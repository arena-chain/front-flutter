import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

/// Subscribes to Nest `/presence` namespace (same as desktop `presence.js`).
/// Emits `friend-online` / `friend-offline` for friends.
class FriendsPresenceNotifier extends ChangeNotifier {
  final TokenStorage _tokenStorage = TokenStorage();
  IO.Socket? _socket;
  final Set<String> _onlineUserIds = {};

  Set<String> get onlineUserIds => Set.unmodifiable(_onlineUserIds);

  bool isOnline(String userId) => _onlineUserIds.contains(userId);

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      _socket = IO.io(
        '${ApiConfig.baseUrl}/presence',
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .enableReconnection()
            .build(),
      );

      _socket!.on('friend-online', (data) {
        final id = data is Map ? data['userId']?.toString() : null;
        if (id != null) {
          _onlineUserIds.add(id);
          notifyListeners();
        }
      });

      _socket!.on('friend-offline', (data) {
        final id = data is Map ? data['userId']?.toString() : null;
        if (id != null) {
          _onlineUserIds.remove(id);
          notifyListeners();
        }
      });

      _socket!.on('friend-status', (data) {
        final id = data is Map ? data['userId']?.toString() : null;
        if (id == null) return;
        final status = data['status']?.toString();
        if (status == 'OFFLINE' || status == null) {
          _onlineUserIds.remove(id);
        } else {
          _onlineUserIds.add(id);
        }
        notifyListeners();
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('FriendsPresenceNotifier: connect failed: $e');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _onlineUserIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
