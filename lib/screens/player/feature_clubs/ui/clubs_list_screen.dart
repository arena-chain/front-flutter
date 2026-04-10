import 'package:flutter/material.dart';

class ClubsListScreen extends StatelessWidget {
  const ClubsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF13172E), Color(0xFF0A0E1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 10),
                    _buildClubCard(
                      title: 'Elite Gamers',
                      description: 'Professional team focused on FPS games',
                      members: 45,
                      games: ['Valorant', 'CS2', 'Apex Legends'],
                      nextTournament: 'Spring Championship',
                      tournamentDate: 'Mar 5, 2026',
                    ),
                    const SizedBox(height: 20),
                    _buildClubCard(
                      title: 'MOBA Masters',
                      description: 'Top-tier MOBA competitive team',
                      members: 68,
                      games: ['League of Legends', 'Dota 2'],
                      nextTournament: 'League Masters Cup',
                      tournamentDate: 'Mar 1, 2026',
                    ),
                    const SizedBox(height: 20),
                    _buildClubCard(
                      title: 'Arena Champions',
                      description: 'Multi-game esports organization',
                      members: 132,
                      games: ['Valorant', 'CS2', 'League of Legends', 'Apex'],
                      nextTournament: 'Cross-Game Tournament',
                      tournamentDate: 'Mar 15, 2026',
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
=======
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
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
    );
  }

  Widget _buildHeader(BuildContext context) {
<<<<<<< HEAD
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
=======
    return Container(
      padding: const EdgeInsets.all(20),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
<<<<<<< HEAD
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Hub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
=======
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
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
                ),
              ),
            ],
          ),
<<<<<<< HEAD
          const Padding(
            padding: EdgeInsets.only(left: 45),
            child: Text(
              'Join competitive gaming communities',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
=======
          const SizedBox(height: 8),
          const Text(
            'Join competitive gaming communities',
            style: TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 14,
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
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
<<<<<<< HEAD
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF87).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people, color: Color(0xFF00FF87), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '$members',
                              style: const TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'GAMES',
                    style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: games.map((game) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Text(
                          game,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Tournament Banner
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF00FF87).withOpacity(0.05), Colors.transparent],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Color(0xFF00FF87), size: 30),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('NEXT TOURNAMENT', style: TextStyle(color: Color(0xFF00FF87), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(nextTournament, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              Text(tournamentDate, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Join Button
            InkWell(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00FF87), Color(0xFF00DF76)],
                  ),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VIEW CLUB INFO',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_ios, color: Colors.black, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
=======
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
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
      ),
    );
  }
}
