import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:arena_chain_flutter/core/api/stream_api.dart';
import 'package:arena_chain_flutter/core/models/stream_model.dart';
import 'package:arena_chain_flutter/core/services/live_stream_service.dart';

class LiveStreamViewModel extends ChangeNotifier {
  final LiveStreamService _liveStreamService = LiveStreamService();
  final StreamApi _streamApi = StreamApi();
  
  StreamModel? _stream;
  StreamModel? get stream => _stream;

  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  List<Map<String, dynamic>> chatMessages = [];
  bool isLive = false;
  bool isLoading = true;

  StreamSubscription? _streamSub;
  StreamSubscription? _chatSub;
  StreamSubscription? _statusSub;

  LiveStreamViewModel() {
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await remoteRenderer.initialize();
  }

  Future<void> loadStream(String streamId, {String? token}) async {
    isLoading = true;
    notifyListeners();

    _stream = await _streamApi.getStreamById(streamId);
    if (_stream != null) {
      isLive = _stream!.isLive;
      _liveStreamService.connect(_stream!.channelId, token: token);
      
      _streamSub = _liveStreamService.onRemoteStream.listen((event) {
        remoteRenderer.srcObject = event;
        notifyListeners();
      });

      _chatSub = _liveStreamService.onChatMessage.listen((msg) {
        chatMessages.add(msg);
        if (chatMessages.length > 50) chatMessages.removeAt(0);
        notifyListeners();
      });

      _statusSub = _liveStreamService.onStatusChanged.listen((status) {
        isLive = status;
        notifyListeners();
      });
    }

    isLoading = false;
    notifyListeners();
  }

  void sendMessage(String message) {
    _liveStreamService.sendChatMessage(message);
  }

  void sendReaction(String emoji) {
    _liveStreamService.sendReaction(emoji);
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _chatSub?.cancel();
    _statusSub?.cancel();
    _liveStreamService.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}
