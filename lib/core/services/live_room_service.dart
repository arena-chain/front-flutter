import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

class LiveRoomService {
  io.Socket? _streamSocket;
  io.Socket? _liveGameSocket;
  io.Socket? _presenceSocket;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  bool _isConnecting = false;
  int _candidateIdx = 0;
  String? _token;

  final _chatController = StreamController<Map<String, dynamic>>.broadcast();
  final _reactionSummaryController =
      StreamController<Map<String, int>>.broadcast();
  final _gameEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get onChatMessage => _chatController.stream;
  Stream<Map<String, int>> get onReactionSummary =>
      _reactionSummaryController.stream;
  Stream<Map<String, dynamic>> get onGameEvent => _gameEventController.stream;
  Stream<List<Map<String, dynamic>>> get onPresenceReady =>
      _presenceController.stream;
  Stream<bool> get onConnectionChanged => _connectionController.stream;

  String? _channelId;

  String get _baseUrl => ApiConfig.baseUrl;
  String? _workingBaseUrl;

  List<String> _candidateBaseUrls() {
    final candidates = <String>[
      if (_workingBaseUrl case final String working) working,
      _baseUrl,
      'http://10.0.2.2:3000',
      'http://127.0.0.1:3000',
      'http://localhost:3000',
    ];
    final seen = <String>{};
    return candidates.where((b) => seen.add(b)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchChatHistory(
    String channelId, {
    int limit = 50,
  }) async {
    for (final candidate in _candidateBaseUrls()) {
      final uri = Uri.parse(
        '$candidate/api/chat/channel/$channelId?limit=$limit',
      );
      try {
        final response =
            await http.get(uri).timeout(const Duration(seconds: 6));
        if (response.statusCode != 200) continue;
        _workingBaseUrl = candidate;
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
        if (data is Map && data['messages'] is List) {
          return (data['messages'] as List)
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      } on SocketException {
        continue;
      } on TimeoutException {
        continue;
      } catch (_) {
        continue;
      }
    }
    return [];
  }

  void connect({
    required String channelId,
    required String userId,
    String? token,
  }) {
    _channelId = channelId;
    _token = token;
    _candidateIdx = 0;
    _connectUsingCandidate();
  }

  void _connectUsingCandidate() {
    if (_isDisposed || _isConnecting) return;
    final candidates = _candidateBaseUrls();
    if (candidates.isEmpty) return;
    if (_candidateIdx >= candidates.length) _candidateIdx = 0;

    final base = candidates[_candidateIdx];
    _isConnecting = true;
    _teardownSocketsOnly();
    _connectionController.add(false);

    _streamSocket = io.io(
      base,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth(_token != null ? {'token': _token} : {})
          .build(),
    );
    _liveGameSocket = io.io(
      '$base/live-game',
      io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    _presenceSocket = io.io(
      '$base/presence',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth(_token != null ? {'token': _token} : {})
          .build(),
    );

    _streamSocket!.onConnect((_) {
      _workingBaseUrl = base;
      _isConnecting = false;
      _connectionController.add(true);
      _streamSocket!.emit(
        'join-channel',
        {'channelId': _channelId, 'role': 'viewer'},
      );
      _presenceSocket?.emit('get-friends');
      _presenceSocket?.emit(
        'update-status',
        {'status': 'online', 'details': 'Watching live room'},
      );
    });

    void failover(dynamic _) {
      if (_isDisposed) return;
      _isConnecting = false;
      _connectionController.add(false);
      _scheduleNextCandidate();
    }

    _streamSocket!.onConnectError(failover);
    _streamSocket!.onError(failover);
    _streamSocket!.onDisconnect((_) {
      if (_isDisposed) return;
      _connectionController.add(false);
      _scheduleNextCandidate();
    });

    _streamSocket!.on('chat-message', (payload) {
      if (payload is Map) {
        _chatController.add(Map<String, dynamic>.from(payload));
      }
    });
    _streamSocket!.on('reaction-summary', (payload) {
      if (payload is Map && payload['counts'] is Map) {
        final raw = Map<String, dynamic>.from(payload['counts'] as Map);
        _reactionSummaryController.add(
          raw.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
        );
      }
    });

    _liveGameSocket!.on('game-event', (payload) {
      if (payload is Map) {
        _gameEventController.add(Map<String, dynamic>.from(payload));
      }
    });
    _liveGameSocket!.on('game-state', (payload) {
      if (payload is Map) {
        _gameEventController.add({
          'type': 'game-state',
          ...Map<String, dynamic>.from(payload),
        });
      }
    });

    _presenceSocket!.on('presence-ready', (payload) {
      if (payload is Map && payload['friends'] is List) {
        final friends = (payload['friends'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _presenceController.add(friends);
      }
    });
    _presenceSocket!.on(
      'friend-online',
      (payload) => _mergePresence(payload, 'online'),
    );
    _presenceSocket!.on(
      'friend-offline',
      (payload) => _mergePresence(payload, 'offline'),
    );
    _presenceSocket!.on(
      'friend-status',
      (payload) => _mergePresence(payload, null),
    );

    _streamSocket!.connect();
    _liveGameSocket!.connect();
    _presenceSocket!.connect();
  }

  void _scheduleNextCandidate() {
    _reconnectTimer?.cancel();
    _candidateIdx += 1;
    _reconnectTimer = Timer(const Duration(seconds: 2), _connectUsingCandidate);
  }

  List<Map<String, dynamic>> _presenceCache = [];
  void _mergePresence(dynamic payload, String? fallbackStatus) {
    if (payload is! Map) return;
    final map = Map<String, dynamic>.from(payload);
    final userId = (map['userId'] ?? '').toString();
    if (userId.isEmpty) return;
    final idx = _presenceCache.indexWhere((f) => '${f['userId']}' == userId);
    final status = map['status']?.toString() ?? fallbackStatus ?? 'online';
    if (idx == -1) {
      _presenceCache.add({'userId': userId, 'status': status, ...map});
    } else {
      _presenceCache[idx] = {..._presenceCache[idx], ...map, 'status': status};
    }
    _presenceController.add(List<Map<String, dynamic>>.from(_presenceCache));
  }

  void sendMessage(String message) {
    final channel = _channelId;
    if (channel == null) return;
    final text = message.trim();
    if (text.isEmpty) return;
    _streamSocket?.emit('chat-message', {'channelId': channel, 'message': text});
  }

  void sendReaction(String emoji) {
    final channel = _channelId;
    if (channel == null) return;
    _streamSocket?.emit('reaction', {'channelId': channel, 'emoji': emoji});
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _streamSocket?.emit('leave-channel');
    _teardownSocketsOnly();
    _streamSocket = null;
    _liveGameSocket = null;
    _presenceSocket = null;
    _channelId = null;
    _presenceCache = [];
    _isConnecting = false;
  }

  void _teardownSocketsOnly() {
    _streamSocket?.disconnect();
    _streamSocket?.dispose();
    _liveGameSocket?.disconnect();
    _liveGameSocket?.dispose();
    _presenceSocket?.disconnect();
    _presenceSocket?.dispose();
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _chatController.close();
    _reactionSummaryController.close();
    _gameEventController.close();
    _presenceController.close();
    _connectionController.close();
  }
}

