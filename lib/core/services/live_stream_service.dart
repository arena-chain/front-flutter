import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:arena_chain_flutter/core/api/stream_api.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class LiveStreamService {
  final StreamApi _streamApi = StreamApi();
  IO.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _remoteStream;
  
  final _onRemoteStreamController = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get onRemoteStream => _onRemoteStreamController.stream;

  final _onChatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onChatMessage => _onChatMessageController.stream;
  
  final _onReactionController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onReaction => _onReactionController.stream;

  final _onStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChanged => _onStatusController.stream;

  String? _currentChannelId;

  void connect(String channelId, {String? token}) {
    _currentChannelId = channelId;
    _socket = io.io(
      ApiConfig.socketOrigin,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth(token != null && token.isNotEmpty ? {'token': token} : {})
          .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected');
      _socket!.emit('join-channel', {
        'channelId': channelId,
        'role': 'viewer',
      });
    });

    _socket!.on('broadcaster-status', (data) {
      final bool isBroadcasting = data['isBroadcasting'] ?? false;
      _onStatusController.add(isBroadcasting);
      if (!isBroadcasting) {
        _closePeerConnection();
      }
    });

    _socket!.on('broadcast-ended', (_) {
      _onStatusController.add(false);
      _closePeerConnection();
    });

    _socket!.on('signal-offer', (data) async {
      await _handleOffer(data['sourceId'], data['description']);
    });

    _socket!.on('ice-candidate', (data) async {
      await _handleIceCandidate(data['candidate']);
    });

    _socket!.on('chat-message', (data) {
      _onChatMessageController.add(data);
    });

    _socket!.on('reaction-event', (data) {
      _onReactionController.add(data);
    });

    _socket!.onDisconnect((_) => print('Socket disconnected'));
  }

  Future<void> _handleOffer(String sourceId, dynamic description) async {
    final rtcConfig = await _streamApi.getRtcConfig();
    final iceServers = rtcConfig['iceServers'] as List<dynamic>;

    Map<String, dynamic> configuration = {
      'iceServers': iceServers.map((s) => {
        'urls': s['urls'],
        if (s['username'] != null) 'username': s['username'],
        if (s['credential'] != null) 'credential': s['credential'],
      }).toList(),
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _onRemoteStreamController.add(_remoteStream);
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _socket!.emit('ice-candidate', {
        'targetId': sourceId,
        'channelId': _currentChannelId,
        'candidate': candidate.toMap(),
      });
    };

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(description['sdp'], description['type']),
    );

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _socket!.emit('signal-answer', {
      'targetId': sourceId,
      'channelId': _currentChannelId,
      'description': {'sdp': answer.sdp, 'type': answer.type},
    });
  }

  Future<void> _handleIceCandidate(dynamic candidateData) async {
    if (_peerConnection != null && candidateData != null) {
      await _peerConnection!.addCandidate(
        RTCIceCandidate(
          candidateData['candidate'],
          candidateData['sdpMid'],
          candidateData['sdpMLineIndex'],
        ),
      );
    }
  }

  void sendChatMessage(String message) {
    if (_socket != null && _currentChannelId != null) {
      _socket!.emit('chat-message', {
        'channelId': _currentChannelId,
        'message': message,
      });
    }
  }

  void sendReaction(String emoji) {
    if (_socket != null && _currentChannelId != null) {
      _socket!.emit('reaction', {
        'channelId': _currentChannelId,
        'emoji': emoji,
      });
    }
  }

  void _closePeerConnection() {
    _peerConnection?.dispose();
    _peerConnection = null;
    _remoteStream = null;
    _onRemoteStreamController.add(null);
  }

  void dispose() {
    _socket?.emit('leave-channel');
    _socket?.dispose();
    _closePeerConnection();
    _onRemoteStreamController.close();
    _onChatMessageController.close();
    _onReactionController.close();
    _onStatusController.close();
  }
}
