import 'dart:async';

import 'package:arena_chain_flutter/core/api/stream_api.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/stream_model.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class LiveCatalogSnapshot {
  final List<StreamModel> liveStreams;
  final List<StreamModel> scheduledStreams;

  const LiveCatalogSnapshot({
    required this.liveStreams,
    required this.scheduledStreams,
  });
}

class LiveCatalogService {
  LiveCatalogService({StreamApi? streamApi}) : _streamApi = streamApi ?? StreamApi();

  final StreamApi _streamApi;
  io.Socket? _socket;
  Timer? _pollTimer;
  Timer? _debounceTimer;

  Future<LiveCatalogSnapshot> fetchSnapshot() async {
    List<StreamModel> liveFromEndpoint = const [];
    List<StreamModel> allStreams = const [];
    Object? liveError;
    Object? allError;

    try {
      liveFromEndpoint = await _streamApi.getLiveStreams();
    } catch (error) {
      liveError = error;
      debugPrint('LiveCatalogService: /stream/live failed: $error');
    }

    try {
      allStreams = await _streamApi.getAllStreams();
    } catch (error) {
      allError = error;
      debugPrint('LiveCatalogService: /stream failed: $error');
    }

    if (liveError != null && allError != null) {
      throw StreamApiException(
        'Unable to refresh live streams. Please check the stream API.',
      );
    }

    final liveStreams = liveFromEndpoint.isNotEmpty
        ? liveFromEndpoint
        : allStreams.where((stream) => stream.isLive).toList();
    final scheduledStreams = allStreams.where((stream) => !stream.isLive).toList();

    return LiveCatalogSnapshot(
      liveStreams: liveStreams,
      scheduledStreams: scheduledStreams,
    );
  }

  void startRealtimeSync({
    required VoidCallback onCatalogChanged,
    Duration pollInterval = const Duration(seconds: 5),
  }) {
    stopRealtimeSync();

    void scheduleRefresh([String? reason]) {
      debugPrint('LiveCatalogService: scheduling refresh${reason == null ? '' : ' ($reason)'}');
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 250), onCatalogChanged);
    }

    _socket = io.io(
      ApiConfig.socketOrigin,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .build(),
    );

    _socket!.onConnect((_) => scheduleRefresh('connect'));
    _socket!.onDisconnect((_) => scheduleRefresh('disconnect'));
    _socket!.onConnectError((_) => scheduleRefresh('connect-error'));

    for (final event in const [
      'broadcaster-status',
      'broadcast-ended',
      'viewer-joined',
      'viewer-left',
      'signal-offer',
      'signal-answer',
      'ice-candidate',
      'chat-message',
      'reaction-event',
    ]) {
      _socket!.on(event, (_) => scheduleRefresh(event));
    }

    _pollTimer = Timer.periodic(pollInterval, (_) => onCatalogChanged());
  }

  void stopRealtimeSync() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    stopRealtimeSync();
  }
}
