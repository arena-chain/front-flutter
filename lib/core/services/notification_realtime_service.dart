import 'package:arena_chain_flutter/core/models/feature_notifications/app_notification.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class NotificationRealtimeService {
  io.Socket? _socket;

  void connect({
    required String token,
    required void Function(AppNotification notification) onNotification,
    void Function()? onConnected,
    void Function()? onDisconnected,
  }) {
    disconnect();

    _socket = io.io(
      '${ApiConfig.socketOrigin}/notifications',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) => onConnected?.call());
    _socket!.onDisconnect((_) => onDisconnected?.call());
    _socket!.on('notification:new', (payload) {
      if (payload is Map) {
        onNotification(AppNotification.fromJson(Map<String, dynamic>.from(payload)));
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
