import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/screens/player/feature_live/ui/live_detail_screen.dart';

class LiveListScreen extends StatelessWidget {
  const LiveListScreen({super.key});

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
              _buildLiveNowSection(),
              const SizedBox(height: 24),
              _buildLiveCard(
                context,
                title: 'Ranked Grind - Road to Radiant',
                streamer: 'ProGamer_X',
                game: 'Valorant',
                viewers: 1234,
              ),
              const SizedBox(height: 16),
              _buildLiveCard(
                context,
                title: 'Diamond Promos - LET\'S GO!',
                streamer: 'StreamQueen',
                game: 'League of Legends',
                viewers: 856,
              ),
              const SizedBox(height: 16),
              _buildLiveCard(
                context,
                title: 'Competitive Grind',
                streamer: 'NinjaKing',
                game: 'Valorant',
                viewers: 445,
              ),
              const SizedBox(height: 16),
              _buildLiveCard(
                context,
                title: 'Arena Championship Qualifier',
                streamer: 'EsportsLegend',
                game: 'CS:GO',
                viewers: 2103,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Live Views',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLiveNowSection() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF0055).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Color(0xFFFF0055),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Live Now',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF0055).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF0055).withOpacity(0.3),
            ),
          ),
          child: const Text(
            '3 Live',
            style: TextStyle(
              color: Color(0xFFFF0055),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveCard(
    BuildContext context, {
    required String title,
    required String streamer,
    required String game,
    required int viewers,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveDetailScreen(
              title: title,
              streamer: streamer,
              game: game,
              viewers: viewers,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A1F36)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail with LIVE badge
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F36),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF00).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Color(0xFF00FF00),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                // LIVE badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0055),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Select Mode overlay (optional)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Select Mode',
                      style: TextStyle(
                        color: Color(0xFF7A86AC),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Generate Match URL button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF00).withOpacity(0.15),
                        foregroundColor: const Color(0xFF00FF00),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: const Color(0xFF00FF00).withOpacity(0.3),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Generate Match URL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stream info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Matches',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.visibility,
                            color: Color(0xFF7A86AC),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            viewers.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]},',
                                ),
                            style: const TextStyle(
                              color: Color(0xFF7A86AC),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    streamer,
                    style: const TextStyle(
                      color: Color(0xFF7A86AC),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
