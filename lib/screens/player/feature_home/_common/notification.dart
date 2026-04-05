import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNotificationItem(
            icon: Icons.sports_esports,
            iconColor: const Color(0xFF00FF00),
            title: 'New Match Found',
            subtitle: 'Ranked • Valorant',
            time: '2m ago',
            isUnread: true,
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            icon: Icons.emoji_events,
            iconColor: const Color(0xFFFFAA00),
            title: 'Tournament Starting',
            subtitle: 'Check-in required',
            time: '1h ago',
            isUnread: true,
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            icon: Icons.group_add,
            iconColor: const Color(0xFF00CCFF),
            title: 'Team Invitation',
            subtitle: 'Team Liquid invited you to join',
            time: '3h ago',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread 
            ? const Color(0xFF1A1F36) 
            : const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(16),
        border: isUnread 
            ? Border.all(color: const Color(0xFF00FF00).withOpacity(0.3))
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF7A86AC),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7A86AC),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 12),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF00FF00),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
