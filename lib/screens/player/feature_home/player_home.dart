import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/bottom_navbar.dart';
import 'package:arena_chain_flutter/screens/player/feature_live/ui/scheduled_streams_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/ui/tournaments_list_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_news/ui/news_list_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_clubs/ui/clubs_list_screen.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_news/viewmodel/news_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_rank/viewmodel/rank_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/viewmodel/level_viewmodel.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/core/services/friends_presence_service.dart';
import 'package:arena_chain_flutter/screens/player/feature_chat/ui/chat_list_screen.dart';

import 'package:arena_chain_flutter/screens/training/training_dashboard_screen.dart';
import 'package:arena_chain_flutter/core/api/training_api_service.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

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

  late final TrainingApiService _trainingApi;
  final TokenStorage _tokenStorage = TokenStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsPresenceNotifier>().connect();
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
        return const ScheduledStreamsScreen();
      case 2:
        return const TournamentsListScreen();
      case 3:
        return _buildTrainingScreen();
      case 4:
        return const NewsListScreen();
      case 5:
        return ChatListScreen();
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
          const SizedBox(height: 16),
          _buildLevelProgression(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildNexusFeed(),
          const SizedBox(height: 24),
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
                tooltip: 'Find players',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.addFriend);
                },
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

  Widget _buildLevelProgression() {
    return Consumer<LevelViewModel>(
      builder: (context, levelVM, child) {
        if (levelVM.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)));
        }

        final level = levelVM.currentLevel;
        if (level == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF00FF00).withOpacity(0.15), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF00).withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LEVEL PROGRESSION',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Level ${level.level}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF00).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00FF00), width: 1),
                      ),
                      child: const Icon(Icons.flash_on, color: Color(0xFF00FF00), size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: level.progressPct / 100,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00FF00), Color(0xFF00CC00)],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF00FF00).withOpacity(0.3), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${level.xp} / ${level.xpToNextLevel} XP',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${level.progressPct.toInt()}% Complete',
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
                  const Text(
                    'Nexus Feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _onNavTap(4), // Navigate to News tab
                    child: const Text('Explore All', style: TextStyle(color: Color(0xFF00FF00))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: newsVM.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: news.length > 5 ? 5 : news.length,
                    itemBuilder: (context, index) {
                      final item = news[index];
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(12),
                          image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(item.imageUrl!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
                              )
                            : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FF00),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.game.toUpperCase(),
                                  style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final user = authViewModel.currentUser;
        final nickname = user?.nickname ?? 'Player';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

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
                    fontWeight: FontWeight.bold,
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
    return Consumer<RankViewModel>(
      builder: (context, rankVM, child) {
        if (rankVM.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)));

        final primaryRank = rankVM.primaryRank;
        if (primaryRank == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Status',
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
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF00).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              primaryRank.game.toUpperCase(),
                              style: const TextStyle(color: Color(0xFF00FF00), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            primaryRank.tier,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ELO Rating: ${primaryRank.elo}',
                            style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildMiniStat('Wins', primaryRank.wins.toString()),
                              const SizedBox(width: 16),
                              _buildMiniStat('Losses', primaryRank.losses.toString()),
                              const SizedBox(width: 16),
                              _buildMiniStat('Win Rate', '${((primaryRank.wins / ((primaryRank.wins + primaryRank.losses) == 0 ? 1 : (primaryRank.wins + primaryRank.losses))) * 100).toInt()}%'),
                            ],
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
      },
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentGames() {
    return Consumer<RankViewModel>(
      builder: (context, rankVM, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Matches',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All', style: TextStyle(color: Color(0xFF00FF00))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (rankVM.isLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)))
              else if (rankVM.ranks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: const Text(
                    'No match history yet. Play games to see recent performance.',
                    style: TextStyle(color: Color(0xFF7A86AC)),
                  ),
                )
              else
                ...rankVM.ranks.take(3).map((rank) {
                  final totalMatches = rank.wins + rank.losses;
                  final isPositive = rank.wins >= rank.losses;
                  final winRate = totalMatches == 0 ? 0 : ((rank.wins / totalMatches) * 100).toInt();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGameCard(
                      game: rank.game,
                      result: isPositive ? 'Positive' : 'Needs Work',
                      score: '${rank.wins}-${rank.losses}',
                      kda: '$winRate% WR',
                      rank: rank.tier,
                      timeAgo: _timeAgo(rank.updatedAt),
                      isWin: isPositive,
                    ),
                  );
                }),
            ],
          ),
        );
      },
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
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              _buildMiniStat('Score', score),
              Container(
                width: 1,
                height: 24,
                color: const Color(0xFF1A1F36),
              ),
              _buildMiniStat('K/D/A', kda),
              Container(
                width: 1,
                height: 24,
                color: const Color(0xFF1A1F36),
              ),
              _buildMiniStat('Rank', rank),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
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
