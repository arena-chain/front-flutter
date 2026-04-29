import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asn1.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum RiftConnectionStatus {
  disconnected,
  connecting,
  waitingForConduit,
  waitingForApproval,
  connected,
  error,
}

class LcuEvent {
  final String uri;
  final String eventType;
  final dynamic data;
  final int httpStatus;

  LcuEvent({
    required this.uri,
    this.eventType = 'Update',
    this.data,
    required this.httpStatus,
  });

  Map<String, dynamic> get asMap =>
      {'uri': uri, 'data': data, 'httpStatus': httpStatus};
}

class RiftService extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  RiftConnectionStatus _status = RiftConnectionStatus.disconnected;
  RiftConnectionStatus get status => _status;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String? _conduitPublicKey;
  String? get conduitPublicKey => _conduitPublicKey;

  bool get conduitConnected =>
      _status == RiftConnectionStatus.connected && _conduitPublicKey != null;

  Uint8List? _aesKey;
  final _lcuController = StreamController<LcuEvent>.broadcast();
  Stream<LcuEvent> get lcuEvents => _lcuController.stream;

  /// Host/IP last used in [connect] (Rift relay). Use for Nest/Socket.io on the same machine.
  String? _lastRelayHostIp;
  String? get lastRelayHostIp => _lastRelayHostIp;

  static const String _kGameflowPhaseUri = '/lol-gameflow/v1/gameflow-phase';
  static const int _nestLiveGameApiPort = 3000;

  final _random = Random.secure();
  int _nextRequestId = 1;

  // Rift-level opcodes (mobile <-> Rift relay)
  static const int _riftConnect = 4;
  static const int _riftConnectPubkey = 5;
  static const int _riftSend = 6;
  static const int _riftReceive = 8;

  // Conduit-level inner opcodes (mobile <-> Conduit, inside encrypted tunnel)
  static const int _mobileSecret = 1;
  static const int _mobileSecretResponse = 2;
  static const int _mobileSubscribe = 5;
  static const int _mobileRequest = 7;
  static const int _mobileResponse = 8;
  static const int _mobileUpdate = 9;

  static String? _deviceIdentity;
  static String _getDeviceIdentity() {
    if (_deviceIdentity != null) return _deviceIdentity!;
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _deviceIdentity =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    return _deviceIdentity!;
  }

  void _log(String msg) => debugPrint('[RiftService] $msg');

  /// When the socket drops (e.g. closeCode 1005), clear crypto state and pending
  /// requests. No auto-reconnect — user must pair again from the pairing screen.
  void _onTransportClosed({required bool clearAsError}) {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _aesKey = null;
    _conduitPublicKey = null;
    _pendingRequests.clear();
    if (clearAsError) {
      _status = RiftConnectionStatus.error;
    } else if (_status != RiftConnectionStatus.error) {
      _status = RiftConnectionStatus.disconnected;
    } else {
      _status = RiftConnectionStatus.disconnected;
    }
    if (!clearAsError) {
      _errorMessage = '';
    }
    notifyListeners();
  }

  /// Conduit sometimes sends pseudo-JSON where the last array element is a bare
  /// word (e.g. `...,Lobby]`). Quote those tokens so [jsonDecode] succeeds.
  String _sanitizeLcuDecryptedPayload(String decrypted) {
    final re = RegExp(r',([A-Za-z][A-Za-z0-9_]*)\]$');
    var s = decrypted;
    while (true) {
      final m = re.firstMatch(s);
      if (m == null) {
        break;
      }
      final word = m.group(1)!;
      if (word == 'true' || word == 'false' || word == 'null') {
        break;
      }
      s = s.replaceRange(m.start, m.end, ',"$word"]');
    }
    return s;
  }

  // ── connection ──────────────────────────────────────────────

  Future<void> connect(String ip, String port, String code) async {
    _lastRelayHostIp = ip;
    _closeSocketOnly();
    _conduitPublicKey = null;
    _aesKey = null;

    _status = RiftConnectionStatus.connecting;
    _errorMessage = '';
    notifyListeners();

    final uri = Uri.parse('ws://$ip:$port/mobile');
    _log('Connecting to $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _log('WebSocket connected');
    } catch (e) {
      _log('WebSocket connect failed: $e');
      _status = RiftConnectionStatus.error;
      _errorMessage = 'WebSocket connect failed: $e';
      notifyListeners();
      return;
    }

    _subscription = _channel!.stream.listen(
      _onMessage,
      onError: (e) {
        _log('WebSocket stream error: $e');
        _errorMessage = 'WebSocket error: $e';
        _onTransportClosed(clearAsError: true);
      },
      onDone: () {
        _log('WebSocket closed — closeCode=${_channel?.closeCode}, closeReason=${_channel?.closeReason}');
        _onTransportClosed(clearAsError: false);
      },
    );

    _log('Sending CONNECT with code=$code');
    _sendRaw(jsonEncode([_riftConnect, code]));
  }

  // ── incoming ────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    if (raw is! String) {
      _log('Received non-string message, ignoring');
      return;
    }

    try {
      final msg = jsonDecode(raw) as List<dynamic>;
      final opcode = (msg[0] as num).toInt();
      final payload = msg.length > 1 ? msg[1] : null;

      _log('← Rift opcode=$opcode payload_type=${payload.runtimeType}');

      switch (opcode) {
        case _riftConnectPubkey:
          _handleConnectPubkey(payload);
          break;
        case _riftReceive:
          _handleReceive(payload);
          break;
        default:
          _log('Unhandled rift opcode $opcode');
      }
    } catch (e, st) {
      _log('_onMessage parse error: $e\n$st');
    }
  }

  // ── CONNECT_PUBKEY (5) ──────────────────────────────────────

  void _handleConnectPubkey(dynamic payload) {
    if (payload == null) {
      _log('CONNECT_PUBKEY: null → Conduit not running');
      _conduitPublicKey = null;
      _status = RiftConnectionStatus.waitingForConduit;
      _errorMessage = 'Conduit not connected — make sure Conduit is running on your PC.';
      notifyListeners();
      return;
    }
    if (payload is String && payload.isNotEmpty) {
      _log('CONNECT_PUBKEY: received pubkey (${payload.length} chars)');
      _conduitPublicKey = payload;
      _status = RiftConnectionStatus.waitingForApproval;
      _errorMessage = '';
      notifyListeners();
      _sendSecretMessage(payload);
      return;
    }
    _log('CONNECT_PUBKEY: invalid payload type=${payload.runtimeType}');
    _status = RiftConnectionStatus.error;
    _errorMessage = 'Invalid CONNECT_PUBKEY payload from Rift';
    notifyListeners();
  }

  // ── RSA Secret exchange ─────────────────────────────────────

  void _sendSecretMessage(String pubkeyBase64) {
    try {
      _log('Parsing RSA public key...');
      final rsaPubKey = _parseAsn1PublicKey(pubkeyBase64);
      _log('RSA key parsed: ${rsaPubKey.modulus!.bitLength}-bit');

      final aesKey = _generateRandomBytes(32);
      _aesKey = aesKey;
      _log('Generated AES key (${aesKey.length} bytes)');

      final identity = _getDeviceIdentity();
      final secretPayload = jsonEncode({
        'secret': base64Encode(aesKey),
        'identity': identity,
        'device': 'ArenaChain Mobile',
        'browser': 'Flutter',
      });
      _log('Secret payload identity=$identity');

      final cipher = OAEPEncoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(rsaPubKey));

      final plainBytes = Uint8List.fromList(utf8.encode(secretPayload));
      final encrypted = cipher.process(plainBytes);
      final encryptedBase64 = base64Encode(encrypted);
      _log('RSA encrypted secret (${encryptedBase64.length} chars)');

      final innerMsg = [_mobileSecret, encryptedBase64];
      _sendRaw(jsonEncode([_riftSend, innerMsg]));
      _log('Sent SECRET message via SEND opcode');
    } catch (e, st) {
      _log('RSA secret exchange FAILED: $e\n$st');
      _status = RiftConnectionStatus.error;
      _errorMessage = 'RSA encryption failed: $e';
      notifyListeners();
    }
  }

  // ── RECEIVE (8) ─────────────────────────────────────────────

  void _handleReceive(dynamic payload) {
    _log('RECEIVE: status=$_status, payload_type=${payload.runtimeType}, hasKey=${_aesKey != null}');

    // Before secret is confirmed, expect plaintext arrays
    if (_status == RiftConnectionStatus.waitingForApproval) {
      if (payload is List) {
        _handlePlaintextReceive(payload);
      } else if (payload is String) {
        _log('RECEIVE: got string while waitingForApproval, trying as encrypted SecretResponse');
        _handleEncryptedReceive(payload);
      }
      return;
    }

    // After connected, messages are AES-encrypted strings
    if (payload is String) {
      _handleEncryptedReceive(payload);
      return;
    }

    // Fallback for plaintext
    if (payload is List) {
      _handlePlaintextReceive(payload);
    }
  }

  void _handlePlaintextReceive(dynamic payload) {
    if (payload is! List || payload.isEmpty) return;

    final innerOp = (payload[0] as num).toInt();
    _log('Plaintext inner opcode=$innerOp, payload=$payload');

    if (innerOp == _mobileSecretResponse) {
      final approved = payload.length > 1 && payload[1] == true;
      _log('SecretResponse: approved=$approved');

      if (approved) {
        _status = RiftConnectionStatus.connected;
        _errorMessage = '';
        notifyListeners();
        _log('Status → connected. Subscribing to endpoints...');

        // Small delay before sending encrypted messages to ensure
        // Conduit has fully set the AES key before we send
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_status == RiftConnectionStatus.connected) {
            _subscribeToEndpoints();
          }
        });
      } else {
        _status = RiftConnectionStatus.error;
        _errorMessage = 'Connection denied by desktop user.';
        _aesKey = null;
        notifyListeners();
      }
    }
  }

  void _handleEncryptedReceive(String encryptedPayload) {
    if (_aesKey == null) {
      _log('Cannot decrypt: no AES key');
      return;
    }

    _log('Decrypting RECEIVE (${encryptedPayload.length} chars, has colon: ${encryptedPayload.contains(":")})');
    final decrypted = _decryptAES(encryptedPayload);
    if (decrypted == null) {
      _log('DECRYPT FAILED for payload: ${encryptedPayload.substring(0, min(80, encryptedPayload.length))}...');
      return;
    }

    _log('Decrypted: ${decrypted.substring(0, min(200, decrypted.length))}');

    dynamic inner;
    try {
      final sanitized = _sanitizeLcuDecryptedPayload(decrypted);
      inner = jsonDecode(sanitized);
    } catch (e, st) {
      _log('LCU inner jsonDecode failed (after bare-word sanitize): $e\n$st\nraw=$decrypted');
      return;
    }

    try {
      // JSON-object push (alternate wire format): { "uri", "data", optional "status" }
      if (inner is Map) {
        final m = Map<String, dynamic>.from(inner);
        final uri = m['uri']?.toString();
        if (uri != null && uri.isNotEmpty && m.containsKey('data')) {
          final statusRaw = m['status'];
          final statusCode = statusRaw is num
              ? statusRaw.toInt()
              : (statusRaw is String ? int.tryParse(statusRaw) : null) ?? 200;
          _log('LCU push (map): uri=$uri status=$statusCode');
          final decodedData = _decodeLcuPayload(m['data']);
          _lcuController.add(LcuEvent(
            uri: uri,
            data: decodedData,
            httpStatus: statusCode,
            eventType: statusCode == 200 ? 'Update' : 'Delete',
          ));
          _notifyNestGameflowPhaseIfNeeded(uri, decodedData);
          return;
        }
        _log('Inner JSON map not handled as LCU push: keys=${m.keys.toList()}');
        return;
      }

      if (inner is! List || inner.isEmpty) {
        _log('Inner message is not a List or map we handle: ${inner.runtimeType}');
        return;
      }

      final innerOp = _readInt(inner[0], -1);
      if (innerOp < 0) {
        _log('Inner opcode not a number: ${inner[0]}');
        return;
      }
      _log('Inner opcode=$innerOp');

      // Inbound LCU reply to a mobile request (Mimic Conduit: MobileOpcode.Response = 8)
      // Wire: [8, requestId, httpStatus, responseData]
      switch (innerOp) {
        case _mobileSecretResponse:
          final approved = inner.length > 1 && inner[1] == true;
          _log('Encrypted SecretResponse: approved=$approved');
          if (approved && _status != RiftConnectionStatus.connected) {
            _status = RiftConnectionStatus.connected;
            _errorMessage = '';
            notifyListeners();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (_status == RiftConnectionStatus.connected) {
                _subscribeToEndpoints();
              }
            });
          }
          break;

        case _mobileResponse:
          _handleLcuResponse(inner);
          break;

        // Mimic Conduit: MobileOpcode.Update = 9 — LCU subscription push
        case _mobileUpdate:
          _handleLcuUpdate(inner);
          break;

        // Some relays use opcode 3 for push-style updates [3, uri, data] or [3, uri, status, data]
        case 3:
          _handleLcuPushOpcode3(inner);
          break;

        default:
          _log('Unhandled inner opcode $innerOp: $decrypted');
      }
    } catch (e, st) {
      _log('LCU inner routing error: $e\n$st');
    }
  }

  int _readInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  String? _phaseStringFromGameflowData(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final s = raw.replaceAll('"', '').trim();
      if (s.isEmpty || s == 'null') return null;
      return s;
    }
    if (raw is Map) {
      final p = (raw['phase'] ?? raw['gameflowPhase'] ?? '').toString().trim();
      return p.isEmpty ? null : p;
    }
    return null;
  }

  void _notifyNestGameflowPhaseIfNeeded(String uri, dynamic data) {
    if (uri != _kGameflowPhaseUri) return;
    final phase = _phaseStringFromGameflowData(data);
    if (phase == null || phase.isEmpty) return;
    _postGameflowPhaseToNest(phase);
  }

  void _postGameflowPhaseToNest(String phase) {
    final host = _lastRelayHostIp;
    if (host == null || host.isEmpty) {
      _log('Nest gameflow phase POST skipped (no relay host yet)');
      return;
    }
    final url = Uri.parse('http://$host:$_nestLiveGameApiPort/api/live-game/phase');
    http
        .post(
          url,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({'phase': phase}),
        )
        .then((response) {
          if (response.statusCode < 200 || response.statusCode >= 300) {
            _log(
              'Nest POST /api/live-game/phase failed: ${response.statusCode} ${response.body}',
            );
          }
        })
        .catchError((Object e) {
          _log('Nest POST /api/live-game/phase error: $e');
        });
  }

  dynamic _decodeLcuPayload(dynamic rawData) {
    if (rawData is String) {
      try {
        return jsonDecode(rawData);
      } catch (_) {
        return rawData;
      }
    }
    return rawData;
  }

  void _handleLcuPushOpcode3(List inner) {
    if (inner.length < 3) {
      _log('LCU push opcode 3 too short: $inner');
      return;
    }
    final uri = inner[1].toString();
    final int statusCode;
    final dynamic rawData;
    if (inner.length >= 4) {
      statusCode = _readInt(inner[2], 200);
      rawData = inner[3];
    } else {
      statusCode = 200;
      rawData = inner[2];
    }
    final data = _decodeLcuPayload(rawData);
    _log('LCU push [3]: uri=$uri status=$statusCode');
    _lcuController.add(LcuEvent(
      uri: uri,
      data: data,
      httpStatus: statusCode,
      eventType: statusCode == 200 ? 'Update' : 'Delete',
    ));
    _notifyNestGameflowPhaseIfNeeded(uri, data);
  }

  // ── LCU Response [8, id, statusCode, data] ──────────────────

  void _handleLcuResponse(List inner) {
    if (inner.length < 3) {
      _log('LCU Response too short: $inner');
      return;
    }
    final requestId = _readInt(inner[1], -1);
    final statusCode = _readInt(inner[2], -1);
    if (requestId < 0 || statusCode < 0) {
      _log('LCU Response bad id/status: inner=$inner');
      return;
    }
    final rawData = inner.length > 3 ? inner[3] : null;
    final data = _decodeLcuPayload(rawData);

    final pending = _pendingRequests.remove(requestId);
    _log('LCU Response [8]: id=$requestId status=$statusCode path=$pending dataType=${data.runtimeType}');

    if (pending != null) {
      _lcuController.add(LcuEvent(
        uri: pending,
        data: data,
        httpStatus: statusCode,
      ));
      _notifyNestGameflowPhaseIfNeeded(pending, data);
    } else {
      _log('LCU Response [8]: no pending entry for id=$requestId — reply dropped');
    }
  }

  // ── LCU Update [9, "/uri", statusCode, data] ───────────────

  void _handleLcuUpdate(List inner) {
    if (inner.length < 3) {
      _log('LCU Update too short: $inner');
      return;
    }
    final uri = inner[1].toString();
    final statusCode = _readInt(inner[2], 200);
    final rawData = inner.length > 3 ? inner[3] : null;
    final data = _decodeLcuPayload(rawData);

    _log('LCU Update [9]: uri=$uri status=$statusCode');

    final eventType = (statusCode == 200) ? 'Update' : 'Delete';
    _lcuController.add(LcuEvent(
      uri: uri,
      data: data,
      httpStatus: statusCode,
      eventType: eventType,
    ));
    _notifyNestGameflowPhaseIfNeeded(uri, data);
  }

  // ── Subscribe to LCU endpoints ──────────────────────────────

  void _subscribeToEndpoints() {
    _log('Subscribing to LCU endpoints...');
    final paths = [
      '/lol-lobby/v2/lobby',
      '/lol-gameflow/v1/gameflow-phase',
      '/lol-matchmaking/v1/ready-check',
      '/lol-champ-select/v1/session',
      '/lol-gameflow/v1/session',
      '/lol-chat/v1/friends',
      '/lol-chat/v1/me',
    ];
    for (final path in paths) {
      final innerMsg = jsonEncode([_mobileSubscribe, path]);
      _log('→ Subscribe: $path');
      _sendEncryptedInner(innerMsg);
    }
    _log('All subscriptions sent');
  }

  // ── outgoing: LCU requests ─────────────────────────────────

  final Map<int, String> _pendingRequests = {};

  void sendLcuRequest(String method, String path, [dynamic body]) {
    if (_status != RiftConnectionStatus.connected || _aesKey == null) {
      _log('sendLcuRequest BLOCKED: status=$_status hasKey=${_aesKey != null}');
      return;
    }

    final id = _nextRequestId++;
    _pendingRequests[id] = path;

    // Mimic Conduit (MobileConnectionHandler): inner encrypted payload is a JSON array:
    //   [7, requestId, path, method, bodyStringOrNull]  (MobileOpcode.Request = 7)
    // Rift *outer* WS opcode 4 is CONNECT only — do not confuse with this inner opcode.
    // Inbound: [8, requestId, httpStatus, data] = LCU HTTP reply; [9, uri, status, data] = subscription push.
    final String? bodyString = body != null ? jsonEncode(body) : null;

    final innerList = <dynamic>[_mobileRequest, id, path, method, bodyString];
    final innerMsg = jsonEncode(innerList);

    _log('→ LCU Request #$id: $method $path body=$bodyString');
    _sendEncryptedInner(innerMsg);
  }

  void _sendEncryptedInner(String plaintext) {
    if (_aesKey == null) {
      _log('_sendEncryptedInner BLOCKED: no AES key');
      return;
    }
    final encrypted = _encryptAES(plaintext);
    _log('→ SEND encrypted (${encrypted.length} chars)');
    _sendRaw(jsonEncode([_riftSend, encrypted]));
  }

  // ── AES crypto ("base64(IV):base64(ciphertext)") ───────────

  String _encryptAES(String plaintext) {
    final iv = _generateRandomBytes(16);
    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(_aesKey!), iv));

    final input = _pkcs7Pad(Uint8List.fromList(utf8.encode(plaintext)), cipher.blockSize);
    final output = Uint8List(input.length);

    for (var offset = 0; offset < input.length; offset += cipher.blockSize) {
      cipher.processBlock(input, offset, output, offset);
    }

    return '${base64Encode(iv)}:${base64Encode(output)}';
  }

  String? _decryptAES(String raw) {
    try {
      final colonIdx = raw.indexOf(':');
      if (colonIdx < 0) {
        _log('_decryptAES: no colon separator found');
        return null;
      }

      final ivPart = raw.substring(0, colonIdx);
      final ctPart = raw.substring(colonIdx + 1);

      final iv = base64Decode(ivPart);
      final ciphertext = base64Decode(ctPart);
      if (iv.length != 16 || ciphertext.isEmpty) {
        _log('_decryptAES: bad lengths iv=${iv.length} ct=${ciphertext.length}');
        return null;
      }

      final cipher = CBCBlockCipher(AESEngine())
        ..init(false, ParametersWithIV(KeyParameter(_aesKey!), Uint8List.fromList(iv)));

      final output = Uint8List(ciphertext.length);
      for (var offset = 0; offset < ciphertext.length; offset += cipher.blockSize) {
        cipher.processBlock(Uint8List.fromList(ciphertext), offset, output, offset);
      }

      return utf8.decode(_pkcs7Unpad(output), allowMalformed: true);
    } catch (e, st) {
      _log('_decryptAES error: $e\n$st');
      return null;
    }
  }

  // ── RSA: parse ASN.1 DER SubjectPublicKeyInfo ───────────────

  RSAPublicKey _parseAsn1PublicKey(String base64Key) {
    final der = base64Decode(base64Key);
    final parser = ASN1Parser(Uint8List.fromList(der));

    final topSeq = parser.nextObject() as ASN1Sequence;
    final bitString = topSeq.elements![1] as ASN1BitString;
    final pubKeyBytes = Uint8List.fromList(bitString.stringValues!);

    final innerParser = ASN1Parser(pubKeyBytes);
    final innerSeq = innerParser.nextObject() as ASN1Sequence;

    final modulus = (innerSeq.elements![0] as ASN1Integer).integer!;
    final exponent = (innerSeq.elements![1] as ASN1Integer).integer!;

    return RSAPublicKey(modulus, exponent);
  }

  // ── helpers ─────────────────────────────────────────────────

  Uint8List _generateRandomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  Uint8List _pkcs7Pad(Uint8List data, int blockSize) {
    final padLen = blockSize - (data.length % blockSize);
    return Uint8List(data.length + padLen)
      ..setAll(0, data)
      ..fillRange(data.length, data.length + padLen, padLen);
  }

  Uint8List _pkcs7Unpad(Uint8List data) {
    if (data.isEmpty) return data;
    final padLen = data.last;
    if (padLen > data.length || padLen > 16 || padLen == 0) return data;
    return Uint8List.fromList(data.sublist(0, data.length - padLen));
  }

  // ── transport ───────────────────────────────────────────────

  void _sendRaw(String message) {
    if (_channel == null) {
      _log('_sendRaw: channel is null, cannot send');
      return;
    }
    _channel!.sink.add(message);
  }

  void _closeSocketOnly() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void disconnect() {
    _log('disconnect() called');
    _closeSocketOnly();
    _conduitPublicKey = null;
    _aesKey = null;
    _pendingRequests.clear();
    _status = RiftConnectionStatus.disconnected;
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _lcuController.close();
    super.dispose();
  }
}
