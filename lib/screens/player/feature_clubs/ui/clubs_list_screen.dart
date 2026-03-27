import 'package:flutter/material.dart';

class ClubsListScreen extends StatelessWidget {
  const ClubsListScreen({super.key});

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
              _buildClubCard(
                title: 'Elite Gamers',
                description: 'Professional team focused on FPS games',
                members: 45,
                games: ['Valorant', 'CS2', 'Apex Legends'],
                nextTournament: 'Spring Championship',
                tournamentDate: 'Mar 5, 2026',
              ),
              const SizedBox(height: 16),
              _buildClubCard(
                title: 'MOBA Masters',
                description: 'Top-tier MOBA competitive team',
                members: 68,
                games: ['League of Legends', 'Dota 2'],
                nextTournament: 'League Masters Cup',
                tournamentDate: 'Mar 1, 2026',
              ),
              const SizedBox(height: 16),
              _buildClubCard(
                title: 'Arena Champions',
                description: 'Multi-game esports organization',
                members: 132,
                games: ['Valorant', 'CS2', 'League of Legends', 'Apex'],
                nextTournament: 'Cross-Game Tournament',
                tournamentDate: 'Mar 15, 2026',
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.groups,
                  color: Color(0xFF00FF00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Clubs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Join competitive gaming communities',
            style: TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard({
    required String title,
    required String description,
    required int members,
    required List<String> games,
    required String nextTournament,
    required String tournamentDate,
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.people,
                color: Color(0xFF7A86AC),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '$members Members',
                style: const TextStyle(
                  color: Color(0xFF7A86AC),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.sports_esports,
                color: Color(0xFF7A86AC),
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Games',
                style: TextStyle(
                  color: Color(0xFF7A86AC),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: games.map((game) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F36),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  game,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
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
                      Icons.emoji_events,
                      color: const Color(0xFF00FF00).withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Next Tournament',
                      style: TextStyle(
                        color: Color(0xFF7A86AC),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  nextTournament,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tournamentDate,
                  style: const TextStyle(
                    color: Color(0xFF7A86AC),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF00),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Club',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
