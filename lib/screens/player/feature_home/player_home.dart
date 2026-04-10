import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/bottom_navbar.dart';
import 'package:arena_chain_flutter/screens/player/feature_live/ui/scheduled_streams_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/ui/tournaments_list_screen.dart';
import 'package:arena_chain_flutter/screens/leagues/player_leagues_screen.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_news/viewmodel/news_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_rank/viewmodel/rank_viewmodel.dart';
import 'package:arena_chain_flutter/core/models/rank_model.dart';
import 'package:arena_chain_flutter/core/models/news_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/viewmodel/level_viewmodel.dart';
import 'package:arena_chain_flutter/navigation.dart';

import 'package:arena_chain_flutter/screens/training/training_dashboard_screen.dart';
import 'package:arena_chain_flutter/core/api/training_api_service.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

import 'package:arena_chain_flutter/screens/player/feature_home/_common/arena_chain_animated_title.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/side_drawer.dart';
import 'package:arena_chain_flutter/screens/player/feature_matchmaking/view_model/matchmaking_view_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_matchmaking/ui/matchmaking_dialogs.dart';
import 'package:arena_chain_flutter/screens/player/feature_messages/ui/messages_screen.dart';

class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  static const Color _neon = Color(0xFF39FF14);

  int _currentIndex = 0;

  // ── Global matchmaking dialog tracking ────────────────────────────────
  MatchmakingViewModel? _matchmakingVm;
  bool _isMatchDialogOpen = false;
  bool _isRoomSheetOpen = false;
  MatchmakingStatus? _lastHandledStatus;

  late final TrainingApiService _trainingApi;
  final TokenStorage _tokenStorage = TokenStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsViewModel>().fetchNews(refresh: true);
      context.read<RankViewModel>().fetchMyRanks();
      context.read<LevelViewModel>().fetchMyLevel();

      _trainingApi = TrainingApiService(
        getToken: () => _tokenStorage.getAccessToken(),
      );

      _matchmakingVm = context.read<MatchmakingViewModel>();
      _matchmakingVm!.addListener(_onMatchmakingChanged);
      _onMatchmakingChanged();
    });
  }

  @override
  void dispose() {
    _matchmakingVm?.removeListener(_onMatchmakingChanged);
    try {
      _trainingApi.dispose();
    } catch (_) {}
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
      backgroundColor: _currentIndex == 0 ||
              _currentIndex == 2 ||
              _currentIndex == 3 ||
              _currentIndex == 5
          ? Colors.black
          : const Color(0xFF0A0E1A),
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
        return const ScheduledStreamsScreen();
      case 2:
        return const PlayerLeaguesScreen(embeddedInPlayerShell: true);
      case 3:
        return const TournamentsListScreen();
      case 4:
        return _buildTrainingScreen();
      case 5:
        return const MessagesScreen(embeddedInPlayerShell: true);
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildTrainingScreen() {
    final user = context.read<AuthViewModel>().currentUser;
    return TrainingDashboardScreen(
      apiService: _trainingApi,
      currentUserId: user?.id ?? '',
      currentUsername: user?.nickname ?? 'Player',
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 28),
          _buildNexusFeed(),
          const SizedBox(height: 28),
          _buildRecentMatchesComingSoon(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 8, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu_rounded, color: Colors.white.withValues(alpha: 0.9)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.search_rounded, color: _neon.withValues(alpha: 0.95)),
                    onPressed: () {},
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_none_rounded, color: _neon.withValues(alpha: 0.95)),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 7,
                          height: 7,
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
          const ArenaChainAnimatedTitle(),
        ],
      ),
    );
  }

  Widget _buildNexusFeed() {
    return Consumer<NewsViewModel>(
      builder: (context, newsVM, child) {
        final news = newsVM.newsResponse?.news ?? [];
        if (news.isEmpty && !newsVM.isLoading) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nexus Feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: _neon.withValues(alpha: 0.35), blurRadius: 8),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.news),
                    child: Text('Explore All', style: TextStyle(color: _neon.withValues(alpha: 0.95), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 210,
              child: newsVM.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: news.length > 8 ? 8 : news.length,
                      itemBuilder: (context, index) {
                        final item = news[index];
                        final gameLabel = item.game.isNotEmpty ? item.game : 'News';
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildNexusCard(item, gameLabel: gameLabel),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNexusCard(NewsItem item, {required String gameLabel}) {
    final title = item.title;
    final imageUrl = item.imageUrl;
    final publishedAt = item.publishedAt;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: _neon.withValues(alpha: 0.14), blurRadius: 18, spreadRadius: 0),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _neon.withValues(alpha: 0.28), width: 1),
          ),
          child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF121212)),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A2A1A),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _neon.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _neon.withValues(alpha: 0.55)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, size: 10, color: _neon.withValues(alpha: 0.95)),
                    const SizedBox(width: 6),
                    Text(
                      '((o)) LIVE',
                      style: TextStyle(
                        color: _neon.withValues(alpha: 0.95),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$gameLabel • ${_timeAgo(publishedAt)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Consumer<RankViewModel>(
      builder: (context, rankVM, child) {
        final primary = rankVM.primaryRank;
        final kdLine = 'K/D: --';
        final winLine = _winRateLabel(primary);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: _neon.withValues(alpha: 0.3), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCyberActionCard(
                      icon: Icons.sports_esports_outlined,
                      title: 'MATCHMAKING',
                      subtitle: 'Find a game quickly',
                      kdLine: kdLine,
                      winRateLine: 'Win Rate: $winLine',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.matchmaking),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCyberActionCard(
                      icon: Icons.emoji_events_outlined,
                      title: 'RANKED MATCH',
                      subtitle: 'Compete for glory',
                      kdLine: kdLine,
                      winRateLine: 'Win Rate: $winLine',
                      onTap: () => _onNavTap(3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _winRateLabel(Rank? primaryRank) {
    if (primaryRank == null) return '--';
    final wins = primaryRank.wins;
    final losses = primaryRank.losses;
    final total = wins + losses;
    if (total == 0) return '--';
    return '${((wins / total) * 100).round()}%';
  }

  Widget _buildCyberActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String kdLine,
    required String winRateLine,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 138,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _neon.withValues(alpha: 0.35), width: 1),
            boxShadow: [
              BoxShadow(
                color: _neon.withValues(alpha: 0.08),
                blurRadius: 14,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: _neon.withValues(alpha: 0.9), size: 30),
                    const Spacer(),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            kdLine,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            winRateLine,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentMatchesComingSoon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Matches',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: _neon.withValues(alpha: 0.3), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _neon.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: _neon.withValues(alpha: 0.06), blurRadius: 18),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _neon.withValues(alpha: 0.45), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: _neon.withValues(alpha: 0.25), blurRadius: 16),
                    ],
                  ),
                  child: Icon(Icons.sports_esports_rounded, color: _neon.withValues(alpha: 0.95), size: 36),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _neon.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _neon.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          'COMING SOON',
                          style: TextStyle(
                            color: _neon.withValues(alpha: 0.95),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your match history and performance data.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
