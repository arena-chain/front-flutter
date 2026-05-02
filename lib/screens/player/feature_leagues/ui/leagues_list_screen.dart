import 'package:flutter/material.dart';

class LeaguesListScreen extends StatelessWidget {
  const LeaguesListScreen({super.key});

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
              _buildLeagueCard(
                title: 'Valorant Pro League',
                game: 'Valorant',
                rank: 'Diamond',
                rankColor: const Color(0xFF00AAFF),
                players: 156,
                topPlayers: [
                  {'name': 'Shadow_Strike', 'points': 2850},
                  {'name': 'Ace_Ninja', 'points': 2720},
                  {'name': 'ProGamer_X', 'points': 2680},
                ],
                isJoined: false,
              ),
              const SizedBox(height: 16),
              _buildLeagueCard(
                title: 'League of Legends Masters',
                game: 'League of Legends',
                rank: 'Platinum',
                rankColor: const Color(0xFF00FFAA),
                players: 243,
                topPlayers: [
                  {'name': 'MidLane_King', 'points': 3200},
                  {'name': 'JungleMain', 'points': 3150},
                  {'name': 'ADC_Master', 'points': 3050},
                ],
                isJoined: true,
              ),
              const SizedBox(height: 16),
              _buildLeagueCard(
                title: 'CS2 Elite Competition',
                game: 'CS:GO',
                rank: 'Master',
                rankColor: const Color(0xFFFFAA00),
                players: 89,
                topPlayers: [
                  {'name': 'Headshot_Hero', 'points': 4100},
                  {'name': 'Clutch_King', 'points': 3980},
                  {'name': 'AWP_Legend', 'points': 3850},
                ],
                isJoined: false,
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
                  Icons.shield,
                  color: Color(0xFF00FF00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Live Leagues',
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
            'Compete with the best players',
            style: TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueCard({
    required String title,
    required String game,
    required String rank,
    required Color rankColor,
    required int players,
    required List<Map<String, dynamic>> topPlayers,
    required bool isJoined,
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
          const SizedBox(height: 12),
          Row(
            children: [
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: rankColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  rank,
                  style: TextStyle(
                    color: rankColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isJoined) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF00).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00FF00).withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Joined',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
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
                '$players Players',
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
                Icons.star,
                color: Color(0xFFFFAA00),
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Top Players',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...topPlayers.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final badgeColors = [
              const Color(0xFFFFAA00), // Gold
              const Color(0xFFAAAAAA), // Silver
              const Color(0xFFCD7F32), // Bronze
            ];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: badgeColors[index].withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: badgeColors[index],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      player['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${player['points']} pts',
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          if (!isJoined)
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
                    Icon(Icons.send, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Request to Join',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
