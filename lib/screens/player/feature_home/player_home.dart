import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/core/api/stream_api.dart';
import 'package:arena_chain_flutter/core/models/channel_model.dart';
import 'package:arena_chain_flutter/core/models/stream_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/bottom_navbar.dart';
import 'package:arena_chain_flutter/screens/player/feature_live/ui/scheduled_streams_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_live/ui/arena_live_stream_card.dart';
import 'package:arena_chain_flutter/screens/player/feature_highlights/ui/player_highlights_feed_screen.dart';
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
  _QuickActionSide? _activeQuickActionSide;
  late final PageController _quickCardController;
  int _quickCardIndex = 0;

  // ── Global matchmaking dialog tracking ────────────────────────────────
  MatchmakingViewModel? _matchmakingVm;
  bool _isMatchDialogOpen = false;
  bool _isRoomSheetOpen = false;
  MatchmakingStatus? _lastHandledStatus;

  late final TrainingApiService _trainingApi;
  final TokenStorage _tokenStorage = TokenStorage();
  final StreamApi _streamApi = StreamApi();

  List<StreamModel> _livePreviewStreams = [];
  bool _livePreviewLoading = true;

  @override
  void initState() {
    super.initState();
    _quickCardController = PageController();
    _loadLivePreview();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsViewModel>().fetchNews();
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

  static List<StreamModel> _demoLiveStreamsForPreview() {
    return [
      StreamModel(
        id: 'arena-demo-live-1',
        title: 'VCT EMEA Masters — Semifinals',
        description: 'Live coverage',
        streamerId: 'demo',
        channelId: 'ch-val',
        isLive: true,
        viewerCount: 18420,
        thumbnailUrl:
            'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=1200&auto=format&fit=crop',
        tags: const ['Valorant', 'Esports'],
        channel: Channel(
          id: 'ch-val',
          name: 'VALORANT Esports',
          ownerId: 'riot',
        ),
      ),
      StreamModel(
        id: 'arena-demo-live-2',
        title: 'Ranked Grind — Radiant push',
        streamerId: 'demo',
        channelId: 'ch-pro',
        isLive: true,
        viewerCount: 3204,
        thumbnailUrl:
            'https://images.unsplash.com/photo-1511512578047-dfb367046420?q=80&w=1200&auto=format&fit=crop',
        tags: const ['League of Legends'],
        channel: Channel(id: 'ch-pro', name: 'ProPlayer_TV', ownerId: 'p1'),
      ),
      StreamModel(
        id: 'arena-demo-live-3',
        title: 'CS2 FACEIT Level 10 — Full stack',
        streamerId: 'demo',
        channelId: 'ch-cs',
        isLive: true,
        viewerCount: 892,
        thumbnailUrl:
            'https://images.unsplash.com/photo-1614013409192-3435163158e0?q=80&w=1200&auto=format&fit=crop',
        tags: const ['CS2'],
        channel: Channel(id: 'ch-cs', name: 'headshotHQ', ownerId: 'cs1'),
      ),
    ];
  }

  List<StreamModel> _mergeLivePreview(List<StreamModel> apiLive) {
    final demos = _demoLiveStreamsForPreview();
    if (apiLive.length >= 3) return apiLive.take(3).toList();
    if (apiLive.isEmpty) return demos;
    final out = List<StreamModel>.from(apiLive);
    for (final d in demos) {
      if (out.length >= 3) break;
      if (!out.any((s) => s.id == d.id)) out.add(d);
    }
    return out.take(3).toList();
  }

  Future<void> _loadLivePreview() async {
    try {
      final fromLive = await _streamApi.getLiveStreams();
      final all = await _streamApi.getAllStreams();
      var live = fromLive.isNotEmpty
          ? fromLive
          : all.where((s) => s.isLive).toList();
      live = _mergeLivePreview(live);
      if (!mounted) return;
      setState(() {
        _livePreviewStreams = live;
        _livePreviewLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _livePreviewStreams = _demoLiveStreamsForPreview();
        _livePreviewLoading = false;
      });
    }
  }

  void _openPreviewStream(StreamModel stream) {
    if (stream.id.startsWith('arena-demo')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demo stream — use Watch all lives to open ARENA LIVE.',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.87)),
          ),
          backgroundColor: _neon.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pushNamed(context, AppRoutes.liveStream, arguments: stream.id);
  }

  @override
  void dispose() {
    _matchmakingVm?.removeListener(_onMatchmakingChanged);
    _quickCardController.dispose();
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

  bool _isLeftDiagonalHalf(Offset localPosition, Size size) {
    if (size.width <= 0 || size.height <= 0) return true;
    final yAtLeft = size.height * 0.62;
    final yAtRight = size.height * 0.36;
    final yOnDivider =
        yAtLeft + ((yAtRight - yAtLeft) * (localPosition.dx / size.width));
    return localPosition.dy <= yOnDivider;
  }

  void _handleQuickActionTap({
    required TapDownDetails details,
    required BoxConstraints constraints,
    required double cardHeight,
    required VoidCallback onLeftTap,
    required VoidCallback onRightTap,
  }) {
    final size = Size(constraints.maxWidth, cardHeight);
    final isLeft = _isLeftDiagonalHalf(details.localPosition, size);
    setState(() {
      _activeQuickActionSide = isLeft
          ? _QuickActionSide.left
          : _QuickActionSide.right;
    });
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _activeQuickActionSide = null;
      });
    });
    if (isLeft) {
      onLeftTap();
    } else {
      onRightTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex > 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = 4);
      });
    }
    return Scaffold(
      backgroundColor:
          _currentIndex == 0 ||
              _currentIndex == 1 ||
              _currentIndex == 2 ||
              _currentIndex == 3 ||
              _currentIndex == 4
          ? Colors.black
          : const Color(0xFF0A0E1A),
      drawer: const SideDrawer(),
      body: SafeArea(bottom: false, child: _buildCurrentScreen()),
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
        return const PlayerHighlightsFeedScreen();
      case 2:
        return const PlayerLeaguesScreen(embeddedInPlayerShell: true);
      case 3:
        return const TournamentsListScreen();
      case 4:
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
          const SizedBox(height: 24),
          _buildTrainingModeCard(),
          const SizedBox(height: 28),
          _buildLivePreviewSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.search_rounded,
                      color: _neon.withValues(alpha: 0.95),
                    ),
                    onPressed: () {},
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_none_rounded,
                          color: _neon.withValues(alpha: 0.95),
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.notifications,
                        ),
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
                        Shadow(
                          color: _neon.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.news),
                    child: Text(
                      'Explore All',
                      style: TextStyle(
                        color: _neon.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 210,
              child: newsVM.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF39FF14),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: news.length > 8 ? 8 : news.length,
                      itemBuilder: (context, index) {
                        final item = news[index];
                        final gameLabel = item.game.isNotEmpty
                            ? item.game
                            : 'News';
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
          BoxShadow(
            color: _neon.withValues(alpha: 0.14),
            blurRadius: 18,
            spreadRadius: 0,
          ),
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
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFF121212)),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [const Color(0xFF1A2A1A), Colors.black],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _neon.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _neon.withValues(alpha: 0.55)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        size: 10,
                        color: _neon.withValues(alpha: 0.95),
                      ),
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
        final playerName =
            context.read<AuthViewModel>().currentUser?.nickname.toUpperCase() ??
            'COMMANDER_7';
        final kdLine = '2.41';
        final winLine = _winRateLabel(primary);
        final rankLabel = _primaryTierLabel(primary);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildPuzzleQuickActions(
            playerName: playerName,
            rankLabel: rankLabel,
            kdLine: kdLine,
            winRateLine: winLine,
            onMatchmakingTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connect Riot account'),
                  duration: Duration(milliseconds: 900),
                ),
              );
              Navigator.pushNamed(context, AppRoutes.myAccount);
            },
            onRankedTap: () =>
                Navigator.pushNamed(context, AppRoutes.matchmaking),
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

  String _primaryTierLabel(Rank? primaryRank) {
    final tier = primaryRank?.tier;
    if (tier == null || tier.isEmpty) return 'ELITE TIER III';
    return tier.toUpperCase();
  }

  Widget _buildPuzzleQuickActions({
    required String playerName,
    required String rankLabel,
    required String kdLine,
    required String winRateLine,
    required VoidCallback onMatchmakingTap,
    required VoidCallback onRankedTap,
  }) {
    final displayWinRate = winRateLine == '--' ? '68%' : winRateLine;
    final quickProfiles = <Map<String, dynamic>>[
      {
        'name': playerName,
        'kd': kdLine,
        'win': displayWinRate,
        'route': AppRoutes.myAccount,
      },
      {
        'name': 'PHANTOM_09',
        'kd': '1.96',
        'win': '61%',
        'route': AppRoutes.matchmaking,
      },
      {
        'name': 'ZER0SHIFT',
        'kd': '3.03',
        'win': '74%',
        'route': AppRoutes.playerProfile,
      },
    ];
    final totalPages = quickProfiles.length + 1; // last page for adding account
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxWidth < 430 ? 260.0 : 238.0;
        return SizedBox(
          height: cardHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(
                  color: _neon.withValues(alpha: 0.42),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _neon.withValues(alpha: 0.12),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (_quickCardIndex < quickProfiles.length)
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: CustomPaint(
                          painter: _DiagonalDividerPainter(
                            color: _neon.withValues(alpha: 0.82),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: PageView.builder(
                      controller: _quickCardController,
                      itemCount: totalPages,
                      onPageChanged: (index) {
                        setState(() {
                          _quickCardIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        if (index == quickProfiles.length) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                            child: Center(
                              child: GestureDetector(
                                onTap: onMatchmakingTap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _neon.withValues(alpha: 0.78),
                                      width: 1.2,
                                    ),
                                    color: Colors.black.withValues(alpha: 0.35),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: _neon.withValues(alpha: 0.95),
                                        size: 36,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add another account',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.88,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final profile = quickProfiles[index];
                        final route = profile['route'] as String;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.pushNamed(context, route),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _neon.withValues(alpha: 0.8),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 21,
                                        color: _neon.withValues(alpha: 0.95),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'OPERATOR_ID',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.45,
                                              ),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          Text(
                                            profile['name'] as String? ??
                                                playerName,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.96,
                                              ),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.sports_esports_rounded,
                                      color: _neon.withValues(alpha: 0.95),
                                      size: 28,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'KIL/DEATH_RATIO',
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.32,
                                                ),
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              profile['kd'] as String? ??
                                                  kdLine,
                                              style: TextStyle(
                                                color: _neon.withValues(
                                                  alpha: 0.96,
                                                ),
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 46,
                                        color: Colors.white.withValues(
                                          alpha: 0.18,
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 18,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'WIN_PROBABILITY',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.32),
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.6,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                profile['win'] as String? ??
                                                    displayWinRate,
                                                style: TextStyle(
                                                  color: _neon.withValues(
                                                    alpha: 0.96,
                                                  ),
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    width: constraints.maxWidth * 0.58,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'MATCHMAKING',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.96,
                                          ),
                                          fontSize: 40,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Find a game quickly',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () =>
                                        Navigator.pushNamed(context, route),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _neon,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: const Text(
                                        'INITIALIZE  >',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(totalPages, (i) {
                                      final active = i == _quickCardIndex;
                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        width: active ? 12 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: active
                                              ? _neon.withValues(alpha: 0.9)
                                              : Colors.white.withValues(
                                                  alpha: 0.25,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLivePreviewSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ScheduledStreamsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Watch all lives',
                        style: TextStyle(
                          color: _neon.withValues(alpha: 0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '→',
                        style: TextStyle(
                          color: _neon.withValues(alpha: 0.85),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_livePreviewLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: _neon,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _livePreviewStreams.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  ArenaLiveStreamCard(
                    stream: _livePreviewStreams[i],
                    neon: _neon,
                    onTap: () => _openPreviewStream(_livePreviewStreams[i]),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTrainingModeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _buildTrainingScreen()),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _neon.withValues(alpha: 0.38),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(color: _neon.withValues(alpha: 0.1), blurRadius: 14),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _neon.withValues(alpha: 0.68),
                        width: 1.4,
                      ),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: _neon.withValues(alpha: 0.95),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRAINING MODE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Practice mechanics and improve your performance.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _neon,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'OPEN',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

enum _QuickActionSide { left, right }

class _DiagonalDividerPainter extends CustomPainter {
  final Color color;

  _DiagonalDividerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final start = Offset(0, size.height * 0.62);
    final end = Offset(size.width, size.height * 0.36);
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant _DiagonalDividerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DiagonalSplitHighlightPainter extends CustomPainter {
  final _QuickActionSide? side;
  final Color color;

  _DiagonalSplitHighlightPainter({required this.side, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (side == null) return;
    final yAtLeft = size.height * 0.62;
    final yAtRight = size.height * 0.36;
    final path = Path();
    if (side == _QuickActionSide.left) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, yAtRight)
        ..lineTo(0, yAtLeft)
        ..close();
    } else {
      path
        ..moveTo(0, yAtLeft)
        ..lineTo(size.width, yAtRight)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _DiagonalSplitHighlightPainter oldDelegate) {
    return oldDelegate.side != side || oldDelegate.color != color;
  }
}
