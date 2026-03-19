import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/bottom_navbar.dart';
import 'package:arena_chain_flutter/screens/player/feature_live/ui/live_list_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/ui/tournaments_list_screen.dart';

import 'package:arena_chain_flutter/screens/player/feature_clubs/ui/clubs_list_screen.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/navigation.dart';

import 'package:arena_chain_flutter/screens/player/feature_friends/ui/friends_list_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/side_drawer.dart';
import 'package:arena_chain_flutter/screens/player/feature_matchmaking/view_model/matchmaking_view_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_matchmaking/ui/matchmaking_dialogs.dart';

class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  int _currentIndex = 0;

  // ── Global matchmaking dialog tracking ────────────────────────────────
  MatchmakingViewModel? _matchmakingVm;
  bool _isMatchDialogOpen = false;
  bool _isRoomSheetOpen = false;
  MatchmakingStatus? _lastHandledStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _matchmakingVm = context.read<MatchmakingViewModel>();
      _matchmakingVm!.addListener(_onMatchmakingChanged);
      // Handle current status immediately (state may already be restored)
      _onMatchmakingChanged();
    });
  }

  @override
  void dispose() {
    _matchmakingVm?.removeListener(_onMatchmakingChanged);
    super.dispose();
  }

  void _onMatchmakingChanged() {
    if (!mounted) return;
    final vm = _matchmakingVm;
    if (vm == null) return;

    final status = vm.status;
    if (status == _lastHandledStatus) return;

    if (status == MatchmakingStatus.pendingAcceptance && !_isMatchDialogOpen) {
      _lastHandledStatus = status;
      _isMatchDialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showMatchAcceptDialog(
            context: context,
            vm: vm,
            onDismissed: () => _isMatchDialogOpen = false,
          );
        }
      });
    } else if (status == MatchmakingStatus.accepted &&
        vm.activeGame?.roomInfo != null &&
        !_isRoomSheetOpen) {
      _lastHandledStatus = status;
      _isRoomSheetOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamed(context, AppRoutes.gameRoom).then((_) {
            _isRoomSheetOpen = false;
          });
        }
      });
    } else if (status == MatchmakingStatus.idle ||
        status == MatchmakingStatus.searching ||
        status == MatchmakingStatus.cancelled ||
        status == MatchmakingStatus.expired ||
        status == MatchmakingStatus.error) {
      _lastHandledStatus = status;
      _isMatchDialogOpen = false;
      _isRoomSheetOpen = false;
    } else {
      _lastHandledStatus = status;
    }
  }
  // ─────────────────────────────────────────────────────────────────────

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      drawer: const SideDrawer(),
      body: SafeArea(
        bottom: false,
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const LiveListScreen();
      case 2:
        return const TournamentsListScreen();
      case 3:
        return const FriendsListScreen();
      case 4:
        return const ClubsListScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildCurrentRank(),
          const SizedBox(height: 32),
          _buildRecentGames(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Arena-Chain',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.notifications);
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF0055),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final user = authViewModel.currentUser;
        final nickname = user?.nickname ?? 'Player';
        final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'P';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // User Profile Card - Now Clickable
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.playerProfile);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1221),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00FF00).withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF00FF00), width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Color(0xFF00FF00),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nickname,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Tap to view profile',
                                    style: TextStyle(
                                      color: Color(0xFF7A86AC),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF00FF00),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.sports_esports,
                  label: 'Matchmaking',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FF00), Color(0xFF00CC00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.matchmaking);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.emoji_events,
                  label: 'Ranked Match',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00DD00), Color(0xFF009900)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.groups_2,
            label: 'Local Tournament',
            gradient: const LinearGradient(
              colors: [Color(0xFF00FFAA), Color(0xFF00AA77)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            isWide: true,
          ),
        ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Gradient gradient,
    bool isWide = false,
    VoidCallback? onTap,
  }) {
    return Container(
      height: isWide ? 100 : 120,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentRank() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Rank',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1221),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1A1F36)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF00).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Valorant',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Diamond 2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ELO: 2450',
                        style: TextStyle(
                          color: Color(0xFF7A86AC),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Progress to Diamond 3',
                        style: TextStyle(
                          color: Color(0xFF7A86AC),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F36),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: 0.65,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00FF00), Color(0xFF00CC00)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '65%',
                        style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF00).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.military_tech,
                    size: 32,
                    color: Color(0xFF00FF00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGames() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Games',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF00FF00),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGameCard(
            game: 'Valorant',
            result: 'Win',
            score: '13-10',
            kda: '18/12/7',
            rank: 'Diamond 2',
            timeAgo: '2 hours ago',
            isWin: true,
          ),
          const SizedBox(height: 12),
          _buildGameCard(
            game: 'Valorant',
            result: 'Loss',
            score: '9-13',
            kda: '14/15/8',
            rank: 'Diamond 1',
            timeAgo: '5 hours ago',
            isWin: false,
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required String game,
    required String result,
    required String score,
    required String kda,
    required String rank,
    required String timeAgo,
    required bool isWin,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A1F36)),
      ),
      child: Column(
        children: [
          Row(
            children: [
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isWin 
                    ? const Color(0xFF00FF00).withOpacity(0.1)
                    : const Color(0xFFFF0055).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result,
                  style: TextStyle(
                    color: isWin ? const Color(0xFF00FF00) : const Color(0xFFFF0055),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                timeAgo,
                style: const TextStyle(
                  color: Color(0xFF7A86AC),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Score', score),
              Container(
                width: 1,
                height: 24,
                color: const Color(0xFF1A1F36),
              ),
              _buildStat('K/D/A', kda),
              Container(
                width: 1,
                height: 24,
                color: const Color(0xFF1A1F36),
              ),
              _buildStat('Rank', rank),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7A86AC),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
