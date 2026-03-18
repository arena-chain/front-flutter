import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/core/api/riot/riot_api.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/navigation.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final RiotApi _riotApi = RiotApi();
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoadingLinkStatus = true;
  String _linkStatus = 'unlinked';
  String? _riotGameName;
  String? _riotTagLine;
  String? _riotRegion;

  @override
  void initState() {
    super.initState();
    _checkLinkStatus();
  }

  Future<void> _checkLinkStatus() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        if (mounted) setState(() => _isLoadingLinkStatus = false);
        return;
      }

      final result = await _riotApi.getLinkStatus(token: token);
      if (mounted) {
        setState(() {
          _linkStatus = result['status'] ?? 'unlinked';
          _riotGameName = result['riotGameName'];
          _riotTagLine = result['riotTagLine'];
          _riotRegion = result['riotRegion'];
          _isLoadingLinkStatus = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLinkStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final user = authViewModel.currentUser;
        final nickname = user?.nickname ?? 'Player';
        final email = user?.email ?? '';
        final isPro = user?.playerProfile?.isPro ?? false;

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
                _buildConnectedGameAccounts(),
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

  Widget _buildConnectedGameAccounts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_esports, color: Color(0xFF00FF00), size: 20),
              SizedBox(width: 8),
              Text(
                'Connected Game Accounts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingLinkStatus)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1221),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A1F36)),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFF00FF00),
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (_linkStatus == 'verified')
            _buildLinkedAccountCard()
          else if (_linkStatus == 'pending_verification')
            _buildPendingAccountCard()
          else
            _buildNoAccountsCard(),
        ],
      ),
    );
  }

  Widget _buildLinkedAccountCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRoutes.myAccount,
          arguments: {
            'gameName': _riotGameName,
            'tagLine': _riotTagLine,
            'region': _riotRegion,
            'autoFetch': true,
          },
        );
        _checkLinkStatus();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A1F36)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC89B3C), width: 2),
              ),
              child: const Center(
                child: Text(
                  'LoL',
                  style: TextStyle(
                    color: Color(0xFFC89B3C),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'League of Legends',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF00FF00), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_riotGameName ?? ''}#${_riotTagLine ?? ''}',
                        style: const TextStyle(
                          color: Color(0xFF7A86AC),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF7A86AC), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAccountCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRoutes.myAccount,
          arguments: {
            'gameName': _riotGameName,
            'tagLine': _riotTagLine,
            'region': _riotRegion,
            'autoFetch': false,
          },
        );
        _checkLinkStatus();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF9800), width: 2),
              ),
              child: const Center(
                child: Text(
                  'LoL',
                  style: TextStyle(
                    color: Color(0xFFFF9800),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'League of Legends',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.pending, color: Colors.orange.shade300, size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        'Pending verification',
                        style: TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF7A86AC), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccountsCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, AppRoutes.myAccount);
        _checkLinkStatus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A1F36)),
        ),
        child: Column(
          children: [
            Icon(Icons.link_off, color: Colors.white.withOpacity(0.2), size: 40),
            const SizedBox(height: 12),
            const Text(
              'Connect your game account and fetch its data',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7A86AC),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00FF00)),
              ),
              child: const Text(
                'Connect Now',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
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
        child: Row(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF00).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00FF00), width: 3),
              ),
              child: Center(
                child: Text(
                  nickname.isNotEmpty ? nickname[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
