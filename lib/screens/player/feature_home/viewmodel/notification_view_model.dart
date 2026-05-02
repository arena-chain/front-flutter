import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/api/feature_notifications/notification_api.dart';
import 'package:arena_chain_flutter/core/models/feature_notifications/app_notification.dart';
import 'package:arena_chain_flutter/core/services/notification_realtime_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel({
    NotificationApi? notificationApi,
    NotificationRealtimeService? realtimeService,
    TokenStorage? tokenStorage,
  }) : _notificationApi = notificationApi ?? NotificationApi(),
       _realtimeService = realtimeService ?? NotificationRealtimeService(),
       _tokenStorage = tokenStorage ?? TokenStorage();

  final NotificationApi _notificationApi;
  final NotificationRealtimeService _realtimeService;
  final TokenStorage _tokenStorage;

  List<AppNotification> _notifications = const [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  String? _currentUserId;
  bool _isAuthenticated = false;

  List<AppNotification> get notifications =>
      _notifications.where((notification) => !notification.archived).toList();
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  void syncAuth({required bool isAuthenticated, String? userId}) {
    final hasUserChanged = _currentUserId != userId;
    final authChanged = _isAuthenticated != isAuthenticated;

    _isAuthenticated = isAuthenticated;
    _currentUserId = userId;

    if (!isAuthenticated || userId == null || userId.isEmpty) {
      _realtimeService.disconnect();
      _notifications = const [];
      _unreadCount = 0;
      _isLoading = false;
      _isInitialized = true;
      _error = null;
      notifyListeners();
      return;
    }

    if (authChanged || hasUserChanged || !_isInitialized) {
      _reconnectRealtime();
      refresh();
    }
  }

  Future<void> refresh() async {
    if (!_isAuthenticated) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final notifications = await _notificationApi.getNotifications();
      int unreadCount;
      try {
        unreadCount = await _notificationApi.getUnreadCount();
      } catch (_) {
        unreadCount = notifications.where((notification) => !notification.isRead).length;
      }

      _notifications = notifications;
      _unreadCount = unreadCount;
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    final existing = _notifications.where((item) => item.id == id).firstOrNull;
    if (existing == null || existing.isRead) {
      return;
    }

    await _notificationApi.markRead(id);
    _notifications = _notifications
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    _unreadCount = (_unreadCount - 1).clamp(0, 1 << 31);
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await _notificationApi.markAllRead();
    _notifications = _notifications
        .map((item) => item.isRead ? item : item.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> deleteOne(String id) async {
    final existing = _notifications.where((item) => item.id == id).firstOrNull;
    await _notificationApi.deleteOne(id);
    _notifications = _notifications.where((item) => item.id != id).toList();
    if (existing != null && !existing.isRead) {
      _unreadCount = (_unreadCount - 1).clamp(0, 1 << 31);
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _notificationApi.clearAll();
    _notifications = const [];
    _unreadCount = 0;
    notifyListeners();
  }

  void _reconnectRealtime() {
    _realtimeService.disconnect();
    _tokenStorage.getAccessToken().then((token) {
      if (token == null || token.isEmpty || !_isAuthenticated) {
        return;
      }

      _realtimeService.connect(
        token: token,
        onNotification: _handleIncomingNotification,
      );
    });
  }

  void _handleIncomingNotification(AppNotification notification) {
    final alreadyExists = _notifications.any((item) => item.id == notification.id);
    if (alreadyExists) {
      return;
    }

    _notifications = [notification, ..._notifications];
    if (!notification.isRead) {
      _unreadCount += 1;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeService.disconnect();
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
