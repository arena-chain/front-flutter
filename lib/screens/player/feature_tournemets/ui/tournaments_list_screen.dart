import 'package:flutter/material.dart';

class TournamentsListScreen extends StatelessWidget {
  const TournamentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 24),
              _buildTournamentCard(
                title: 'Winter Championship 2026',
                game: 'Valorant',
                date: 'Feb 15, 2026',
                prize: '\$50,000',
                players: '128/128',
                location: 'Online',
                isFull: true,
              ),
              const SizedBox(height: 16),
              _buildTournamentCard(
                title: 'Spring League Masters',
                game: 'League of Legends',
                date: 'Mar 1, 2026',
                prize: '\$25,000',
                players: '45/64',
                location: 'Online',
                isFull: false,
              ),
              const SizedBox(height: 16),
              _buildTournamentCard(
                title: 'CS2 Pro Invitational',
                game: 'CS:GO',
                date: 'Mar 15, 2026',
                prize: '\$100,000',
                players: '64/64',
                location: 'Online',
                isFull: true,
              ),
              const SizedBox(height: 16),
              _buildTournamentCard(
                title: 'Apex Legends Championship',
                game: 'Apex Legends',
                date: 'Apr 1, 2026',
                prize: '\$75,000',
                players: '20/60',
                location: 'Online',
                isFull: false,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Color(0xFF00FF00),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tournaments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF00),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Create',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upcoming competitive events',
            style: TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard({
    required String title,
    required String game,
    required String date,
    required String prize,
    required String players,
    required String location,
    required bool isFull,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A1F36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isFull
                      ? const Color(0xFFFF0055).withOpacity(0.1)
                      : const Color(0xFF00FF00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFull
                        ? const Color(0xFFFF0055).withOpacity(0.3)
                        : const Color(0xFF00FF00).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isFull ? 'Full' : 'Open',
                  style: TextStyle(
                    color: isFull ? const Color(0xFFFF0055) : const Color(0xFF00FF00),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F36),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              game,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: date,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.emoji_events,
                  label: 'Prize',
                  value: prize,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.people,
                  label: 'Players',
                  value: players,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: location,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isFull ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isFull ? const Color(0xFF1A1F36) : const Color(0xFF00FF00),
                foregroundColor: isFull ? const Color(0xFF4A5568) : Colors.white,
                disabledBackgroundColor: const Color(0xFF1A1F36),
                disabledForegroundColor: const Color(0xFF4A5568),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isFull ? 'Registration Full' : 'Register Now',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isFull) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF7A86AC),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7A86AC),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
