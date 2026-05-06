import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/core/models/channel_model.dart';
import 'package:arena_chain_flutter/core/models/stream_model.dart';
import 'package:arena_chain_flutter/core/services/live_catalog_service.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/bottom_navbar.dart';
import 'package:arena_chain_flutter/screens/player/feature_live/ui/scheduled_streams_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_live/ui/arena_live_stream_card.dart';
import 'package:arena_chain_flutter/screens/player/feature_highlights/ui/player_highlights_feed_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_highlights/viewmodel/highlights_feed_view_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/ui/tournaments_list_screen.dart';
import 'package:arena_chain_flutter/screens/leagues/player_leagues_screen.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_news/viewmodel/news_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_rank/viewmodel/rank_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/viewmodel/linked_accounts_viewmodel.dart';
import 'package:arena_chain_flutter/core/models/linked_accounts/linked_game_account.dart';
import 'package:arena_chain_flutter/core/models/rank_model.dart';
import 'package:arena_chain_flutter/core/models/news_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/viewmodel/level_viewmodel.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/viewmodel/notification_view_model.dart';

import 'package:arena_chain_flutter/screens/training/training_dashboard_screen.dart';
import 'package:arena_chain_flutter/core/api/training_api_service.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

import 'package:arena_chain_flutter/screens/player/feature_home/_common/arena_chain_animated_title.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/game_poster_card.dart'
    show GamePosterCard, gameAccentColor;
import 'package:arena_chain_flutter/screens/player/feature_home/_common/hero_card_light_streak.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/side_drawer.dart';
import 'package:arena_chain_flutter/features/lol_control/widgets/queue_selector_dialog.dart';
import 'package:arena_chain_flutter/services/rift_service.dart';
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
  final LiveCatalogService _liveCatalogService = LiveCatalogService();

  List<StreamModel> _livePreviewStreams = [];
  bool _livePreviewLoading = true;
  String? _livePreviewErrorMessage;

  @override
  void initState() {
    super.initState();
    _quickCardController = PageController(viewportFraction: 0.92);
    _quickCardController.addListener(_onQuickCardScroll);
    _loadLivePreview();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final rankVm = context.read<RankViewModel>();
      final linkedVm = context.read<LinkedAccountsViewModel>();
      final mmVm = context.read<MatchmakingViewModel>();

      context.read<NewsViewModel>().fetchNews();
      context.read<RankViewModel>().fetchMyRanks();
      context.read<LevelViewModel>().fetchMyLevel();

      _trainingApi = TrainingApiService(
        getToken: () => _tokenStorage.getAccessToken(),
      );

      await rankVm.fetchMyRanks();
      if (!mounted) return;
      await linkedVm.refresh(platformRanks: rankVm.ranks);

      _matchmakingVm = mmVm;
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
      final snapshot = await _liveCatalogService.fetchSnapshot();
      if (!mounted) return;
      final live = _mergeLivePreview(snapshot.liveStreams);
      setState(() {
        _livePreviewStreams = live;
        _livePreviewLoading = false;
        _livePreviewErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _livePreviewStreams = _mergeLivePreview([]);
        _livePreviewLoading = false;
        _livePreviewErrorMessage = e.toString();
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

  Future<void> _refreshLivePreviewSilently() async {
    if (_livePreviewLoading) {
      return;
    }

    try {
      final snapshot = await _liveCatalogService.fetchSnapshot();
      if (!mounted) {
        return;
      }

      setState(() {
        _livePreviewStreams = snapshot.liveStreams.take(3).toList();
        _livePreviewErrorMessage = null;
      });
    } catch (_) {
      if (!mounted || _livePreviewStreams.isNotEmpty) {
        return;
      }

      setState(() {
        _livePreviewErrorMessage = 'Unable to refresh live streams.';
      });
    }
  }

  @override
  void dispose() {
    _matchmakingVm?.removeListener(_onMatchmakingChanged);
    _quickCardController.removeListener(_onQuickCardScroll);
    _quickCardController.dispose();
    _liveCatalogService.dispose();
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

  void _onQuickCardScroll() {
    if (!_quickCardController.hasClients) return;
    final page = _quickCardController.page;
    if (page == null) return;
    final intendedIndex = page.round();
    if (intendedIndex != _quickCardIndex) {
      setState(() {
        _quickCardIndex = intendedIndex;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      // Reels: ensure latest public highlights are loaded.
      try {
        context.read<HighlightsFeedViewModel>().load(refresh: true);
      } catch (_) {
        // Provider not in scope yet (e.g. first build) — bootstrap below
        // will load() anyway.
      }
    }
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
      extendBody: true,
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
      bottomNavigationBar: _currentIndex == 1
          ? null
          : BottomNavBar(
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
        return PlayerHighlightsFeedScreen(
          onBack: () => _onNavTap(0),
        );
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildQuickActions(),
                const SizedBox(height: 14),
                _buildPerGameStatsStrip(),
                const SizedBox(height: 24),
                Consumer<LinkedAccountsViewModel>(
                  builder: (context, linkedVm, _) {
                    final targetAccent = _activeAccent(linkedVm.accounts);
                    return TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: targetAccent),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      builder: (context, animatedAccent, _) {
                        final accent = animatedAccent ?? targetAccent;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTrainingModeCard(accent),
                            const SizedBox(height: 28),
                            _buildLivePreviewSection(accent),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: MediaQuery.of(context).viewPadding.bottom + 76,
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Consumer<LinkedAccountsViewModel>(
            builder: (context, linkedVm, _) {
              final targetAccent = _activeAccent(linkedVm.accounts);
              return TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: targetAccent),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
                builder: (context, animatedAccent, _) {
                  final accent = animatedAccent ?? targetAccent;
                  return HomeLightStreakOverlay(
                    triggerKey: _quickCardIndex,
                    accentColor: accent,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopLeftIcon(BuildContext context, List<LinkedGameAccount> accounts) {
    final onTerminal = accounts.isEmpty || _quickCardIndex >= accounts.length;
    final String? avatarUrl =
        onTerminal ? null : accounts[_quickCardIndex].avatarUrl?.trim();
    final showAvatar =
        !onTerminal && avatarUrl != null && avatarUrl.isNotEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: showAvatar
          ? Container(
              key: ValueKey('avatar-$_quickCardIndex-$avatarUrl'),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1F1F1F), width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                width: 56,
                height: 56,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Color(0xFF1A1A1A),
                  child: Center(child: ArenaChainAnimatedTitle()),
                ),
              ),
            )
          : const SizedBox(
              key: ValueKey('logo'),
              width: 56,
              height: 56,
              child: Center(child: ArenaChainAnimatedTitle()),
            ),
    );
  }

  Widget _buildHeader() {
    return Consumer<LinkedAccountsViewModel>(
      builder: (context, linkedVm, _) {
        final targetAccent = _activeAccent(linkedVm.accounts);
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: targetAccent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          builder: (context, animatedAccent, _) {
            final accent = animatedAccent ?? targetAccent;
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 6),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Menu',
                      splashRadius: 22,
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildTopLeftIcon(context, linkedVm.accounts),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Consumer2<AuthViewModel, LevelViewModel>(
                        builder: (context, auth, levelVm, _) {
                          final nick =
                              (auth.currentUser?.nickname.trim() ?? '')
                                  .toUpperCase();
                          final level = levelVm.currentLevel?.level ?? 1;
                          if (nick.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: TweenAnimationBuilder<Color?>(
                              tween: ColorTween(end: accent),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutCubic,
                              builder: (context, animatedLevelTint, _) {
                                final levelTint =
                                    animatedLevelTint ?? accent;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF2A2A2A),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          nick,
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                        ),
                                        child: Text(
                                          '·',
                                          style: TextStyle(
                                            color: const Color(0xFFB3B3B3),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'LVL $level',
                                        style: TextStyle(
                                          color: levelTint,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        splashRadius: 24,
                        icon: const Icon(Icons.search, color: Color(0xFF717171)),
                        onPressed: () {},
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.notifications_none_rounded,
                              color: accent.withValues(alpha: 0.95),
                            ),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.notifications,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
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
          },
        );
      },
    );
  }

  String _accountDisplayName(LinkedGameAccount account) {
    final raw = account.displayName.trim();
    if (raw.isEmpty) return '--';
    return raw.toUpperCase();
  }

  Widget _buildPerGameStatsStrip() {
    return Consumer<LinkedAccountsViewModel>(
      builder: (context, linkedVm, _) {
        final accounts = linkedVm.accounts;
        if (_quickCardIndex < 0 || _quickCardIndex >= accounts.length) {
          return const SizedBox.shrink();
        }
        final account = accounts[_quickCardIndex];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _statColumn(
                    'Account',
                    _accountDisplayName(account),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _statColumn('KDA', account.primaryStat),
                ),
                Expanded(
                  flex: 1,
                  child: _statColumn('Win Rate', account.secondaryStat),
                ),
                Expanded(
                  flex: 1,
                  child: _statColumn('Matches', account.matchesCount ?? '--'),
                ),
                Expanded(
                  flex: 1,
                  child: _statColumn('Main', account.mainRole ?? '--'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFB3B3B3),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
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

  Future<void> _refreshLinkedAccounts(BuildContext context) async {
    await context.read<LinkedAccountsViewModel>().refresh(
      platformRanks: context.read<RankViewModel>().ranks,
    );
  }

  /// Active accent color based on which carousel page is currently centered.
  /// Falls back to the static neon green when the user is on the terminal
  /// "Link Riot/Steam" / "All Accounts Linked" tile.
  Color _activeAccent(List<LinkedGameAccount> accounts) {
    if (_quickCardIndex >= 0 && _quickCardIndex < accounts.length) {
      return gameAccentColor(accounts[_quickCardIndex].gameId);
    }
    return _neon;
  }

  Widget _buildQuickActions() {
    return Consumer<LinkedAccountsViewModel>(
      builder: (context, linkedVM, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildPuzzleQuickActions(
            context: context,
            accounts: linkedVM.accounts,
            linkedVm: linkedVM,
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
    required BuildContext context,
    required List<LinkedGameAccount> accounts,
    required LinkedAccountsViewModel linkedVm,
  }) {
    final totalPages = accounts.length + 1;
    final lolControlConnected = context.watch<RiftService>().isLolControlConnected;
    final rv = linkedVm.riotVerified;
    final sv = linkedVm.steamVerified;
    late final String terminalTitle;
    late final String terminalSubtitle;
    late final IconData terminalIcon;
    VoidCallback? terminalTap;
    var terminalDisabled = false;
    if (!rv) {
      terminalTitle = 'LINK RIOT ACCOUNT';
      terminalSubtitle = 'LoL & Valorant cards';
      terminalIcon = Icons.link_rounded;
      terminalTap = () {
        Navigator.pushNamed(context, AppRoutes.myAccount).then((_) {
          if (context.mounted) _refreshLinkedAccounts(context);
        });
      };
    } else if (!sv) {
      terminalTitle = 'LINK STEAM ACCOUNT';
      terminalSubtitle = 'CS2 & Dota 2 cards';
      terminalIcon = Icons.videogame_asset_rounded;
      terminalTap = () {
        Navigator.pushNamed(context, AppRoutes.linkSteam).then((_) {
          if (context.mounted) _refreshLinkedAccounts(context);
        });
      };
    } else {
      terminalTitle = 'ALL ACCOUNTS LINKED';
      terminalSubtitle = 'You are fully connected';
      terminalIcon = Icons.check_circle_outline_rounded;
      terminalDisabled = true;
      terminalTap = null;
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: PageView.builder(
        controller: _quickCardController,
        itemCount: totalPages,
        physics: const PageScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _quickCardIndex = index;
          });
        },
        itemBuilder: (context, index) {
          if (index == accounts.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF1F1F1F),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                    child: Center(
                      child: GestureDetector(
                        onTap: terminalDisabled ? null : terminalTap,
                        child: Opacity(
                          opacity: terminalDisabled ? 0.45 : 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2A2A2A),
                                width: 1,
                              ),
                              color: Colors.black.withValues(alpha: 0.35),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  terminalIcon,
                                  color: const Color(0xFFB3B3B3),
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  terminalTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  terminalSubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final account = accounts[index];
          final accent = gameAccentColor(account.gameId);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GamePosterCard(
                  account: account,
                  totalPages: totalPages,
                  activePage: _quickCardIndex,
                  isLoading: linkedVm.isLoading,
                  onLive: (account.gameId == LinkedGameId.lol && lolControlConnected)
                      ? () => Navigator.pushNamed(context, AppRoutes.lolControl)
                      : null,
                  onPlayNow: () {
                    if (account.gameId == LinkedGameId.lol) {
                      showQueueSelectorDialog(context);
                    } else {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.matchmaking,
                        arguments: account.gameId, // LinkedGameId enum
                      );
                    }
                  },
                  onOpenStats: () =>
                      Navigator.pushNamed(context, account.statsRoute),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLivePreviewSection(Color accent) {
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
                          color: accent.withValues(alpha: 0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '→',
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.85),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: accent,
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
                    neon: accent,
                    onTap: () => _openPreviewStream(_livePreviewStreams[i]),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTrainingModeCard(Color accent) {
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
                color: accent.withValues(alpha: 0.38),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 14),
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
                        color: accent.withValues(alpha: 0.68),
                        width: 1.4,
                      ),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: accent.withValues(alpha: 0.95),
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
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          color: accent,
                          size: 32,
                          shadows: [
                            Shadow(
                              color: accent.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'OPEN',
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
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



