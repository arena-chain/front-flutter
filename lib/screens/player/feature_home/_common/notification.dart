import 'dart:math' as math;

import 'package:arena_chain_flutter/core/models/feature_notifications/app_notification.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/viewmodel/notification_view_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  static const Color _background = Color(0xFF000000);
  static const Color _surface = Color(0xFF0A0A0A);
  static const Color _card = Color(0xFF1A1C23);
  static const Color _cardRead = Color(0xFF12141A);
  static const Color _neon = Color(0xFF39FF14);

  late final AnimationController _pulse;
  bool _pulseStarted = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pulseStarted) return;
    _pulseStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 0.5;
    } else {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _openNotification(
    BuildContext context,
    NotificationViewModel vm,
    AppNotification notification,
  ) async {
    if (!notification.isRead) {
      await vm.markRead(notification.id);
    }

    if (!context.mounted) return;

    if (notification.resourceDeleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This content no longer exists.')),
      );
      return;
    }

    final link = notification.link;
    if (link == null || link.isEmpty) {
      return;
    }

    if (link.startsWith('/')) {
      Navigator.pushNamed(context, link);
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri != null) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: _neon.withValues(alpha: 0.22)),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: _neon.withValues(alpha: 0.92)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          Consumer<NotificationViewModel>(
            builder: (context, vm, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (vm.unreadCount > 0)
                  IconButton(
                    tooltip: 'Mark all read',
                    onPressed: () => vm.markAllRead(),
                    icon: Icon(Icons.done_all_rounded, color: _neon.withValues(alpha: 0.9)),
                  ),
                if (vm.notifications.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear all',
                    onPressed: () => vm.clearAll(),
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && !vm.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: _neon),
            );
          }

          if (vm.error != null && vm.notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load notifications',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vm.error!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: vm.refresh,
                      style: ElevatedButton.styleFrom(backgroundColor: _neon, foregroundColor: Colors.black),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final breathe = 0.62 + 0.38 * math.sin(_pulse.value * math.pi * 2);
              final notifications = vm.notifications;
              if (notifications.isEmpty) {
                return const Center(
                  child: Text(
                    'All caught up!',
                    style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                );
              }

              return RefreshIndicator(
                color: _neon,
                onRefresh: vm.refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(
                      context: context,
                      vm: vm,
                      breathe: breathe,
                      notification: notification,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem({
    required BuildContext context,
    required NotificationViewModel vm,
    required double breathe,
    required AppNotification notification,
  }) {
    final isUnread = !notification.isRead;
    final iconColor = _categoryColor(notification.category);
    final icon = _categoryIcon(notification.category, notification.resourceDeleted);
    final title = notification.title;
    final subtitle = notification.message;
    final time = _timeAgo(notification.createdAt);
    final double unreadBorderAlpha = isUnread
        ? (0.28 + 0.18 * breathe).clamp(0.0, 1.0).toDouble()
        : 0;
    final glowAlpha = isUnread ? 0.05 + 0.06 * breathe : 0.0;

    return GestureDetector(
      onTap: () => _openNotification(context, vm, notification),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? _card : _cardRead,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _neon.withValues(alpha: isUnread ? unreadBorderAlpha : 0.08),
            width: isUnread ? 1.25 : 1,
          ),
          boxShadow: [
            if (isUnread)
              BoxShadow(
                color: _neon.withValues(alpha: glowAlpha),
                blurRadius: 18,
                spreadRadius: 0,
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: isUnread ? 0.5 : 0.28),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: isUnread ? 0.22 : 0.08),
                    blurRadius: isUnread ? 12 : 4,
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.42),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        notification.category.toUpperCase(),
                        style: TextStyle(
                          color: iconColor.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => vm.deleteOne(notification.id),
                        icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: _neon,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _neon.withValues(alpha: 0.65 * breathe),
                      blurRadius: 8 * breathe,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category, bool resourceDeleted) {
    if (resourceDeleted) return Icons.warning_amber_rounded;
    switch (category) {
      case 'matches':
        return Icons.sports_esports_rounded;
      case 'leagues':
        return Icons.shield_outlined;
      case 'social':
        return Icons.group_add_rounded;
      case 'achievements':
        return Icons.emoji_events_rounded;
      case 'streams':
        return Icons.live_tv_rounded;
      case 'security':
        return Icons.lock_outline_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'matches':
        return const Color(0xFF39FF14);
      case 'leagues':
        return const Color(0xFF9C6BFF);
      case 'social':
        return const Color(0xFF4FD1FF);
      case 'achievements':
        return const Color(0xFFFFB020);
      case 'streams':
        return const Color(0xFFFF004D);
      case 'security':
        return const Color(0xFFFF5C7A);
      default:
        return Colors.white70;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(date);
  }
}

