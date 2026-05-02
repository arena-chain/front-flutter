import 'dart:convert';

import 'package:arena_chain_flutter/core/api/authenticated_client.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/feature_notifications/app_notification.dart';

class NotificationApi {
  NotificationApi({AuthenticatedClient? client}) : _client = client ?? AuthenticatedClient();

  final AuthenticatedClient _client;
  String get _baseUrl => ApiConfig.baseUrl;

  dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    return jsonDecode(body);
  }

  Exception _error(String message) => Exception(message);

  Future<List<AppNotification>> getNotifications({bool includeArchived = false}) async {
    final query = includeArchived ? '?archived=true' : '';
    final response = await _client.get(Uri.parse('$_baseUrl/notifications$query'));
    if (response.statusCode != 200) {
      throw _error('Failed to load notifications');
    }

    final data = _decodeBody(response.body);
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map((item) => AppNotification.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _client.get(Uri.parse('$_baseUrl/notifications/unread-count'));
    if (response.statusCode != 200) {
      throw _error('Failed to load unread notification count');
    }

    final data = _decodeBody(response.body);
    if (data is int) return data;
    if (data is num) return data.toInt();
    if (data is Map) {
      final raw = data['count'] ?? data['unreadCount'] ?? data['total'];
      if (raw is num) return raw.toInt();
    }
    return 0;
  }

  Future<void> markRead(String id) async {
    final response = await _client.patch(Uri.parse('$_baseUrl/notifications/$id/read'), body: const {});
    if (response.statusCode != 200) {
      throw _error('Failed to mark notification as read');
    }
  }

  Future<void> markAllRead() async {
    final response = await _client.patch(Uri.parse('$_baseUrl/notifications/read-all'), body: const {});
    if (response.statusCode != 200) {
      throw _error('Failed to mark all notifications as read');
    }
  }

  Future<void> deleteOne(String id) async {
    final response = await _client.delete(Uri.parse('$_baseUrl/notifications/$id'));
    if (response.statusCode != 200) {
      throw _error('Failed to delete notification');
    }
  }

  Future<void> clearAll() async {
    final response = await _client.delete(Uri.parse('$_baseUrl/notifications/clear-all'));
    if (response.statusCode != 200) {
      throw _error('Failed to clear notifications');
    }
  }

  Future<NotificationPreferences> getPreferences() async {
    final response = await _client.get(Uri.parse('$_baseUrl/notifications/preferences'));
    if (response.statusCode != 200) {
      throw _error('Failed to load notification preferences');
    }

    final data = _decodeBody(response.body);
    if (data is! Map) {
      throw _error('Invalid notification preferences payload');
    }

    return NotificationPreferences.fromJson(Map<String, dynamic>.from(data));
  }

  Future<NotificationPreferences> savePreferences(Map<String, dynamic> prefs) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/notifications/preferences'),
      body: prefs,
    );
    if (response.statusCode != 200) {
      throw _error('Failed to save notification preferences');
    }

    final data = _decodeBody(response.body);
    if (data is! Map) {
      throw _error('Invalid notification preferences payload');
    }

    return NotificationPreferences.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> registerDeviceToken({required String token, required String platform}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/notifications/device-token'),
      body: {'token': token, 'platform': platform},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _error('Failed to register notification device token');
    }
  }
}
