import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class ChatWebRTCService extends ChangeNotifier {
  static final ChatWebRTCService _instance = ChatWebRTCService._internal();
  factory ChatWebRTCService() => _instance;
  ChatWebRTCService._internal();

  final TokenStorage _tokenStorage = TokenStorage();
  IO.Socket? _socket;
  IO.Socket? _presenceSocket;
  
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // Call States
  bool isIncomingCall = false;
  bool isCalling = false;
  bool isInCall = false;
  String? mediaError;
  
  String? currentCallerId;
  String? currentCallerName;
  String? currentCallerAvatar;
  
  String? remoteUserId;
  
  // Voice Room States
  String? currentVoiceRoomId;
  final Map<String, RTCPeerConnection> _roomPeerConnections = {};
  final Map<String, RTCVideoRenderer> _roomRenderers = {}; 
  Map<String, RTCVideoRenderer> get roomRenderers => _roomRenderers;
  Map<String, MediaStream> remoteStreams = {}; // userId -> Stream
  bool isMuted = false;

  final Map<String, dynamic> _stunTurnServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
      {'url': 'stun:stun1.l.google.com:19302'},
      {
        'url': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
      {
        'url': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      }
    ]
  };

  // 1. Initialiser le Socket Chat
  Future<void> connectChatSocket() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _tokenStorage.getAccessToken();
    if (token == null) return;

    _socket = IO.io(
      '${ApiConfig.baseUrl}/chat',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _presenceSocket = IO.io(
      '${ApiConfig.baseUrl}/presence',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('🟢 WebRTC Chat Socket connected');
      notifyListeners();
    });
    _socket!.onDisconnect((_) {
      debugPrint('🔴 WebRTC Chat Socket disconnected');
      notifyListeners();
    });
    _socket!.onConnectError((err) => debugPrint('⚠️ Chat Socket Error: $err'));

    _presenceSocket!.onConnect((_) {
      debugPrint('🟢 Presence Socket connected');
      _presenceSocket!.emit('update-status', {'status': 'online'});
      notifyListeners();
    });
    _presenceSocket!.onDisconnect((_) {
      debugPrint('🔴 Presence Socket disconnected');
      notifyListeners();
    });
    _presenceSocket!.onConnectError((err) => debugPrint('⚠️ Presence Socket Error: $err'));

    _presenceSocket!.on('friend-online', (data) {
      debugPrint('👤 Friend online: ${data['userId']}');
      notifyListeners(); 
    });

    _presenceSocket!.on('friend-offline', (data) {
      debugPrint('👤 Friend offline: ${data['userId']}');
      notifyListeners();
    });

    _presenceSocket!.on('presence-ready', (data) {
      debugPrint('✅ Presence ready: ${data['friends']?.length} friends');
      notifyListeners();
    });

    // Events Entrants (Incoming Call)
    _socket!.on('incomingCall', (data) {
      isIncomingCall = true;
      currentCallerId = data['callerId'];
      currentCallerName = data['callerName'] ?? 'Joueur';
      currentCallerAvatar = data['callerAvatar'];
      notifyListeners(); 
    });

    // ... (rest of voice events) ...
    _socket!.on('offer', (data) async => await _handleIncomingOffer(data['senderId'], data['offer']));
    _socket!.on('answer', (data) async {
      if (_peerConnection != null) {
        await _peerConnection!.setRemoteDescription(RTCSessionDescription(data['answer']['sdp'], data['answer']['type']));
      }
    });
    _socket!.on('ice-candidate', (data) async {
      if (_peerConnection != null && data['candidate'] != null) {
        await _peerConnection!.addCandidate(RTCIceCandidate(data['candidate']['candidate'], data['candidate']['sdpMid'], data['candidate']['sdpMLineIndex']));
      }
    });

    _socket!.on('callAnswered', (data) async {
      if (_peerConnection != null) {
        await _peerConnection!.setRemoteDescription(RTCSessionDescription(data['answer']['sdp'], data['answer']['type']));
        isInCall = true; isCalling = false; notifyListeners();
      }
    });
    _socket!.on('callRejected', (_) => endCallLocally());
    _socket!.on('callEnded', (_) => endCallLocally());

    // --- Voice Room Events ---
    _socket!.on('user-joined', (data) => _setupRoomPeerConnection(data['userId'], false));
    _socket!.on('user-left', (data) => _removeRoomPeerConnection(data['userId']));
    _socket!.on('voice-offer', (data) async => await _handleVoiceOffer(data['from'], data['offer']));
    _socket!.on('voice-answer', (data) async => await _handleVoiceAnswer(data['from'], data['answer']));
    _socket!.on('voice-ice-candidate', (data) async => await _handleVoiceIceCandidate(data['from'], data['candidate']));

    // --- Message Events ---
    _socket!.on('newPrivateMessage', (data) {
      debugPrint('📩 New private message received: $data');
      _messageStreamController.add(data);
      notifyListeners();
    });

    _socket!.on('newGroupMessage', (data) {
      debugPrint('📩 New group message received: $data');
      _messageStreamController.add(data);
      notifyListeners();
    });

    _socket!.connect();
    _presenceSocket!.connect();
  }

  // Stream for new messages
  final StreamController<Map<String, dynamic>> _messageStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;

  // 1.5 Send Private Message
  Future<void> sendPrivateMessage(String receiverId, String message) async {
    // 1. Try Socket if connected
    if (_socket != null && _socket!.connected) {
      _socket!.emit('sendPrivateMessage', {
        'receiverId': receiverId,
        'message': message,
        'messageType': 'text',
      });
      return;
    }

    // 2. Fallback to HTTP REST
    debugPrint('Socket not connected, using HTTP fallback for private message');
    try {
      final token = await _tokenStorage.getAccessToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'receiverId': receiverId,
          'message': message,
          'messageType': 'text',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Message sent via HTTP');
        // Manually trigger stream update for local UI if needed
        final data = json.decode(response.body);
        _messageStreamController.add(data);
      } else {
        debugPrint('HTTP Send failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending message via HTTP: $e');
    }
  }

  // 1.6 Send Group Message
  Future<void> sendGroupMessage(String groupId, String message) async {
    // 1. Try Socket if connected
    if (_socket != null && _socket!.connected) {
      _socket!.emit('sendGroupMessage', {
        'groupId': groupId,
        'message': message,
      });
      return;
    }

    // 2. Fallback to HTTP REST
    debugPrint('Socket not connected, using HTTP fallback for group message');
    try {
      final token = await _tokenStorage.getAccessToken();
      // Use channel endpoint as per backend controller
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/user/fallback'), // Placeholder or actual group endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'channelId': groupId,
          'message': message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Group message sent via HTTP');
      }
    } catch (e) {
      debugPrint('Error sending group message via HTTP: $e');
    }
  }

  // 1.7 Join Group Room
  void joinGroupRoom(String groupId) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('joinGroupRoom', {'groupId': groupId});
  }

  // 2. Initialiser le micro/caméra
  Future<void> _initLocalStream() async {
    mediaError = null;
    final mediaConstraints = {
      'audio': true,
      'video': false,
    };
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      debugPrint('[WebRTC] Local stream initialized: ${_localStream?.id}');
    } catch (e) {
      mediaError = "Microphone error: $e";
      debugPrint('[WebRTC] Error getting user media: $e');
      notifyListeners();
    }
  }

  // 3. Créer la connexion RTCPeerConnection
  Future<void> _createPeerConnection(String rId) async {
    remoteUserId = rId;
    _peerConnection = await createPeerConnection(_stunTurnServers);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_socket != null) {
        _socket!.emit('ice-candidate', {
          'receiverId': remoteUserId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex
          }
        });
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        notifyListeners();
      }
    };

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        _peerConnection!.addTrack(track, _localStream!);
      }
    }
  }

  // 4. Appeler quelqu'un
  Future<void> makeCall(String targetId, String targetName, String? myName) async {
    isCalling = true;
    currentCallerId = targetId;
    currentCallerName = targetName;
    notifyListeners();

    await _initLocalStream();
    await _createPeerConnection(targetId);

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _socket!.emit('callUser', {
      'receiverId': targetId,
      'callerName': myName ?? 'Joueur'
    });

    _socket!.emit('offer', {
      'receiverId': targetId,
      'offer': {'sdp': offer.sdp, 'type': offer.type}
    });
  }

  // 5. Recevoir & Accepter
  Future<void> _handleIncomingOffer(String senderId, dynamic offerData) async {
    await _createPeerConnection(senderId);
    await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offerData['sdp'], offerData['type']));
  }

  Future<void> acceptCall() async {
    if (currentCallerId == null) return;
    isIncomingCall = false;
    isInCall = true;
    notifyListeners();

    await _initLocalStream();
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        _peerConnection!.addTrack(track, _localStream!);
      }
    }

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _socket!.emit('answerCall', {
      'callerId': currentCallerId,
      'answer': {'sdp': answer.sdp, 'type': answer.type}
    });
  }

  void rejectCall() {
    if (currentCallerId != null) {
      _socket!.emit('rejectCall', {'callerId': currentCallerId});
    }
    endCallLocally();
  }

  void endCall() {
    if (currentCallerId != null) {
      _socket!.emit('endCall', {'peerId': currentCallerId});
    }
    endCallLocally();
  }

  void endCallLocally() {
    isCalling = false;
    isIncomingCall = false;
    isInCall = false;
    currentCallerId = null;
    currentCallerName = null;

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;

    _remoteStream?.dispose();
    _remoteStream = null;

    _peerConnection?.close();
    _peerConnection = null;

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  //         VOICE ROOM LOGIC (Mesh)
  // ─────────────────────────────────────────────

  Future<void> joinVoiceRoom(String roomId) async {
    if (currentVoiceRoomId == roomId) return;
    if (currentVoiceRoomId != null) leaveVoiceRoom();

    currentVoiceRoomId = roomId;
    notifyListeners();

    try {
      if (_localStream == null) {
        await _initLocalStream();
      }

      // Ensure speaker is on (Mobile only)
      if (!kIsWeb) {
        Helper.setSpeakerphoneOn(true);
      }

      _socket!.emitWithAck('joinVoiceRoom', {'roomId': roomId}, ack: (res) {
        if (res != null && res['status'] == 'ok') {
          final List participants = res['participants'];
          debugPrint('[Voice] Joined room $roomId, found ${participants.length} peers');
          
          for (var pId in participants) {
            if (pId != null) {
              _setupRoomPeerConnection(pId.toString(), true);
            }
          }
        }
      });
    } catch (e) {
      debugPrint('[Voice] Error joining room: $e');
      leaveVoiceRoom();
    }
  }

  void leaveVoiceRoom() {
    if (currentVoiceRoomId == null) return;
    
    _socket?.emit('leaveVoiceRoom');
    currentVoiceRoomId = null;

    // Close all room connections
    _roomPeerConnections.forEach((userId, pc) => pc.close());
    _roomPeerConnections.clear();
    
    // Dispose all room renderers
    _roomRenderers.forEach((userId, renderer) => renderer.dispose());
    _roomRenderers.clear();
    
    remoteStreams.clear();

    if (!isInCall) {
      _localStream?.dispose();
      _localStream = null;
    }

    notifyListeners();
  }

  void toggleMute() {
    isMuted = !isMuted;
    _localStream?.getAudioTracks().forEach((track) => track.enabled = !isMuted);
    notifyListeners();
  }

  Future<void> _setupRoomPeerConnection(String userId, bool createOffer) async {
    if (_roomPeerConnections.containsKey(userId)) return;

    final pc = await createPeerConnection(_stunTurnServers);
    _roomPeerConnections[userId] = pc;

    pc.onConnectionState = (state) {
      debugPrint('[Voice] PC Connection state with $userId: $state');
    };

    pc.onIceConnectionState = (state) {
      debugPrint('[Voice] PC ICE state with $userId: $state');
    };

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        pc.addTrack(track, _localStream!);
      }
    }

    pc.onIceCandidate = (candidate) {
      _socket!.emit('voice-ice-candidate', {
        'to': userId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex
        }
      });
    };

    pc.onTrack = (event) async {
      debugPrint('[Voice] Track received from $userId: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        final stream = event.streams.first;
        remoteStreams[userId] = stream;
        
        // Setup renderer to HEAR the audio
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        renderer.srcObject = stream;
        _roomRenderers[userId] = renderer;
        
        notifyListeners();
      }
    };

    if (createOffer) {
      RTCSessionDescription offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      _socket!.emit('voice-offer', {
        'to': userId,
        'offer': {'sdp': offer.sdp, 'type': offer.type}
      });
    }
  }

  Future<void> _handleVoiceOffer(String from, dynamic offerData) async {
    await _setupRoomPeerConnection(from, false);
    final pc = _roomPeerConnections[from];
    if (pc != null) {
      await pc.setRemoteDescription(
          RTCSessionDescription(offerData['sdp'], offerData['type']));
      RTCSessionDescription answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      _socket!.emit('voice-answer', {
        'to': from,
        'answer': {'sdp': answer.sdp, 'type': answer.type}
      });
    }
  }

  Future<void> _handleVoiceAnswer(String from, dynamic answerData) async {
    final pc = _roomPeerConnections[from];
    if (pc != null) {
      await pc.setRemoteDescription(
          RTCSessionDescription(answerData['sdp'], answerData['type']));
    }
  }

  Future<void> _handleVoiceIceCandidate(String from, dynamic data) async {
    final pc = _roomPeerConnections[from];
    if (pc != null && data != null) {
      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      await pc.addCandidate(candidate);
    }
  }

  void _removeRoomPeerConnection(String userId) {
    if (_roomPeerConnections.containsKey(userId)) {
      _roomPeerConnections[userId]?.close();
      _roomPeerConnections.remove(userId);
      
      _roomRenderers[userId]?.dispose();
      _roomRenderers.remove(userId);
      
      remoteStreams.remove(userId);
      notifyListeners();
    }
  }
}
