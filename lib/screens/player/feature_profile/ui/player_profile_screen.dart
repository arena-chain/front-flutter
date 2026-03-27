import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/navigation.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nicknameController;
  String _avatarUrl = '';
  
  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    
    // Initialize with data on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final user = authViewModel.currentUser;
      _nicknameController.text = user?.nickname ?? 'Player';
      _avatarUrl = user?.avatar ?? ''; // Restored from local storage after login
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _generateRandomAvatar() {
    final styles = ['avataaars', 'bottts', 'pixel-art', 'lorelei', 'adventurer'];
    final randomStyle = styles[Random().nextInt(styles.length)];
    final randomSeed = Random().nextInt(100000).toString();
    
    setState(() {
      _avatarUrl = 'https://api.dicebear.com/7.x/$randomStyle/png?seed=$randomSeed';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nouvel avatar généré !', style: TextStyle(color: Colors.black)),
        backgroundColor: Color(0xFF00FF00),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSave() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // First update locally for instant feedback
    authViewModel.updateLocalProfile(nickname: _nicknameController.text, avatarUrl: _avatarUrl);

    setState(() {
      _isEditing = false;
    });

    // Then persist to backend + local storage so it survives logout/login
    final success = await authViewModel.updateProfile(
      nickname: _nicknameController.text,
      avatarUrl: _avatarUrl,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Profil mis à jour avec succès.' : 'Sauvegarde locale uniquement (hors ligne).',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFF00FF00),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final user = authViewModel.currentUser;
        final country = user?.country ?? 'TUNISIA';
        // If not editing, display truth from state or input. If editing, display input.
        final nickname = _isEditing ? _nicknameController.text : (_nicknameController.text.isNotEmpty ? _nicknameController.text : (user?.nickname ?? 'Player'));
        final email = user?.email ?? '';
        final isPro = user?.profile?.isPro ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0E1A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Row(
              children: [
                Icon(Icons.person, color: Color(0xFF00FF00), size: 24),
                SizedBox(width: 8),
                Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Color(0xFF00FF00)),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.settings);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildProfileHeader(nickname, email, isPro),
                const SizedBox(height: 24),
                _buildStatsSection(),
                const SizedBox(height: 24),
                _buildMyLeagues(),
                const SizedBox(height: 24),
                _buildAchievements(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(String nickname, String email, bool isPro) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A1F36)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Area
                GestureDetector(
                  onTap: _isEditing ? _generateRandomAvatar : null,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF00).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00FF00), width: 3),
                          image: _avatarUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _avatarUrl.isEmpty
                            ? Center(
                                child: Text(
                                  nickname.isNotEmpty ? nickname[0].toUpperCase() : 'P',
                                  style: const TextStyle(
                                    color: Color(0xFF00FF00),
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (_isEditing)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, color: Colors.white, size: 24),
                                Text(
                                  'Générer',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // User Info Area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing)
                        TextField(
                          controller: _nicknameController,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xFF151515),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF1A1F36)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF00FF00)),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                nickname,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF7A86AC), size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                            ),
                          ],
                        ),
                        
                      const SizedBox(height: 8),
                      Text(
                        isPro ? 'Professional Player' : 'Casual Player',
                        style: const TextStyle(
                          color: Color(0xFF7A86AC),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF00).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00FF00)),
                        ),
                        child: const Text(
                          'Diamond',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Edit Control Buttons
            if (_isEditing) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Sauvegarder', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          // Optional: Reset nickname back to original here if you want cancel to discard changes
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF1A1F36)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Matches', '142', Icons.sports_esports),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Wins', '89', Icons.emoji_events),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Win Rate', '63%', Icons.trending_up),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1F36)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00FF00), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyLeagues() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield, color: Color(0xFF00FF00), size: 20),
              SizedBox(width: 8),
              Text(
                'My Leagues',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLeagueCard(
            name: 'Valorant Pro League',
            game: 'Valorant',
            rank: '#12',
            points: '2680 pts',
            rankBadge: 'Diamond',
            rankColor: const Color(0xFF00FF00),
          ),
          const SizedBox(height: 12),
          _buildLeagueCard(
            name: 'League of Legends Masters',
            game: 'League of Legends',
            rank: '#8',
            points: '3150 pts',
            rankBadge: 'Platinum',
            rankColor: const Color(0xFF00DDDD),
          ),
          const SizedBox(height: 12),
          _buildLeagueCard(
            name: 'CS2 Elite Division',
            game: 'CS2',
            rank: '#24',
            points: '1890 pts',
            rankBadge: 'Gold',
            rankColor: const Color(0xFFFFAA00),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueCard({
    required String name,
    required String game,
    required String rank,
    required String points,
    required String rankBadge,
    required Color rankColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(12),
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
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: rankColor),
                ),
                child: Text(
                  rankBadge,
                  style: TextStyle(
                    color: rankColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F36),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              game,
              style: const TextStyle(
                color: Color(0xFF7A86AC),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rank $rank',
                style: const TextStyle(
                  color: Color(0xFF7A86AC),
                  fontSize: 13,
                ),
              ),
              Text(
                points,
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFF00FF00), size: 20),
              SizedBox(width: 8),
              Text(
                'Achievements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildAchievementBadge('First Win', Icons.emoji_events),
              _buildAchievementBadge('10 Wins', Icons.military_tech),
              _buildAchievementBadge('50 Matches', Icons.sports_esports),
              _buildAchievementBadge('Diamond Rank', Icons.diamond),
              _buildAchievementBadge('Win Streak', Icons.local_fire_department),
              _buildAchievementBadge('Team Player', Icons.groups),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00FF00)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF00FF00), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
