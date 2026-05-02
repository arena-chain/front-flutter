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
import 'package:arena_chain_flutter/screens/player/feature_home/viewmodel/linked_accounts_viewmodel.dart';
import 'package:arena_chain_flutter/core/models/linked_accounts/linked_game_account.dart';
import 'package:arena_chain_flutter/core/models/news_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/viewmodel/level_viewmodel.dart';
import 'package:arena_chain_flutter/navigation.dart';

import 'package:arena_chain_flutter/screens/training/training_dashboard_screen.dart';
import 'package:arena_chain_flutter/core/api/training_api_service.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

import 'package:arena_chain_flutter/screens/player/feature_home/_common/arena_chain_animated_title.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/_common/game_poster_card.dart'
    show GamePosterCard, gameAccentColor;
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
    _quickCardController = PageController(viewportFraction: 0.92);
    _loadLivePreview();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final rankVm = context.read<RankViewModel>();
      final linkedVm = context.read<LinkedAccountsViewModel>();
      final mmVm = context.read<MatchmakingViewModel>();

      context.read<NewsViewModel>().fetchNews();
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
          const SizedBox(height: 12),
          _buildAccountStrip(),
          const SizedBox(height: 14),
          _buildQuickActions(),
          const SizedBox(height: 14),
          _buildPerGameStatsStrip(),
          const SizedBox(height: 24),
          Consumer<LinkedAccountsViewModel>(
            builder: (context, linkedVm, _) {
              final accent = _activeAccent(linkedVm.accounts);
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
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _surnameForPill(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final nick = user?.nickname.trim() ?? '';
    return nick.isEmpty ? '' : nick;
  }

  Widget _buildHeader() {
    return Consumer<LinkedAccountsViewModel>(
      builder: (context, linkedVm, _) {
        final accent = _activeAccent(linkedVm.accounts);
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 6),
          child: Row(
            children: [
              Builder(
                builder: (context) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(child: ArenaChainAnimatedTitle()),
                    ),
                  ),
                ),
              ),
              Consumer<AuthViewModel>(
                builder: (context, auth, child) {
                  final nick = _surnameForPill(context);
                  if (nick.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        nick,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
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
        );
      },
    );
  }

  String _connectionSubtitle(LinkedGameAccount account) {
    switch (account.gameId) {
      case LinkedGameId.lol:
      case LinkedGameId.valorant:
        return 'Riot ID • Connected';
      case LinkedGameId.cs2:
      case LinkedGameId.dota2:
        return 'Steam • Connected';
    }
  }

  Widget _buildAccountStrip() {
    return Consumer2<LinkedAccountsViewModel, AuthViewModel>(
      builder: (context, linkedVm, authVm, _) {
        final accounts = linkedVm.accounts;
        final onTerminal =
            accounts.isEmpty || _quickCardIndex >= accounts.length;
        final profileAvatarUrl = authVm.currentUser?.avatar?.trim();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onTerminal)
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFF1A1A1A),
                  child: Icon(Icons.person, color: Colors.white70, size: 22),
                )
              else
                _buildAccountStripGameAvatar(
                  accounts[_quickCardIndex],
                  profileAvatarUrl,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onTerminal)
                      const Text(
                        'NO ACCOUNT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    else ...[
                      Text(
                        accounts[_quickCardIndex].displayName.toUpperCase(),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _connectionSubtitle(accounts[_quickCardIndex]),
                        style: const TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountStripGameAvatar(
    LinkedGameAccount account,
    String? profileAvatarUrl,
  ) {
    final String? url;
    switch (account.gameId) {
      case LinkedGameId.cs2:
      case LinkedGameId.dota2:
        final p = profileAvatarUrl?.trim() ?? '';
        url = p.isNotEmpty ? p : null;
        break;
      case LinkedGameId.lol:
      case LinkedGameId.valorant:
        final r = account.avatarUrl?.trim() ?? '';
        url = r.isNotEmpty ? r : null;
    }
    if (url == null || url.isEmpty) {
      return const CircleAvatar(
        radius: 22,
        backgroundColor: Color(0xFF1A1A1A),
        child: Icon(Icons.person, color: Colors.white70, size: 22),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF1A1A1A),
      backgroundImage: NetworkImage(url),
    );
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn('KDA', account.primaryStat),
                _statColumn('Win Rate', account.secondaryStat),
                _statColumn('Matches', account.matchesCount ?? '--'),
                _statColumn('Main Role', account.mainRole ?? '--'),
                _statColumn('Streak', _formatStreak(account.streak)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statColumn(String label, String value) {
    final isStreakWins =
        label == 'Streak' && value.toLowerCase().contains('win');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB3B3B3),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (isStreakWins) const SizedBox(width: 4),
            if (isStreakWins) const Text('🔥', style: TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  String _formatStreak(String? streak) {
    if (streak == null || streak.isEmpty) return '--';
    return streak;
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

  Widget _buildPuzzleQuickActions({
    required BuildContext context,
    required List<LinkedGameAccount> accounts,
    required LinkedAccountsViewModel linkedVm,
  }) {
    final totalPages = accounts.length + 1;
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
                  onPlayNow: () =>
                      Navigator.pushNamed(context, AppRoutes.matchmaking),
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
                    child: Icon(
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
