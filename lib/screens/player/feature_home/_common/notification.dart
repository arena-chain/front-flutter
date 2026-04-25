import 'dart:math' as math;

import 'package:flutter/material.dart';

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
            shadows: [
              Shadow(color: _neon.withValues(alpha: 0.22), blurRadius: 10),
            ],
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final breathe = 0.62 + 0.38 * math.sin(_pulse.value * math.pi * 2);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _buildNotificationItem(
                breathe: breathe,
                icon: Icons.sports_esports_rounded,
                iconColor: _neon,
                title: 'New Match Found',
                subtitle: 'Ranked • Valorant',
                time: '2m ago',
                isUnread: true,
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                breathe: breathe,
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFFFB020),
                title: 'Tournament Starting',
                subtitle: 'Check-in required',
                time: '1h ago',
                isUnread: true,
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                breathe: 1.0,
                icon: Icons.group_add_rounded,
                iconColor: const Color(0xFF4FD1FF),
                title: 'Team Invitation',
                subtitle: 'Team Liquid invited you to join',
                time: '3h ago',
                isUnread: false,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem({
    required double breathe,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    final double unreadBorderAlpha = isUnread
        ? ((0.28 + 0.18 * breathe).clamp(0.0, 1.0) as double)
        : 0;
    final glowAlpha = isUnread ? 0.05 + 0.06 * breathe : 0.0;

    return Container(
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
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 10),
            Container(
              width: 8,
              height: 8,
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
    );
  }
}
