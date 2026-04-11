import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/feature_leagues/leagues_api.dart';
import 'package:arena_chain_flutter/core/models/feature_leagues/leagues_models.dart';
import 'package:arena_chain_flutter/navigation.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _bg         = Color(0xFF060810);
const _surface    = Color(0xFF0F1221);
const _card       = Color(0xFF131828);
const _cardHigh   = Color(0xFF181E30);
const _border     = Color(0xFF1E2540);
const _accent     = Color(0xFF00FF00);
const _blue       = Color(0xFF4488FF);
const _orange     = Color(0xFFFFAA00);
const _red        = Color(0xFFFF4455);
const _textPrimary   = Colors.white;
const _textSecondary = Color(0xFF8B95A5);
const _textMuted     = Color(0xFF4A5568);

// ═════════════════════════════════════════════════════════════════════════════
// Player Leagues Screen
// ═════════════════════════════════════════════════════════════════════════════

class PlayerLeaguesScreen extends StatefulWidget {
  final VoidCallback? onBack;

  /// Inside [PlayerHomeScreen] bottom tabs: hide duplicate nav; menu opens drawer.
  final bool embeddedInPlayerShell;

  const PlayerLeaguesScreen({
    super.key,
    this.onBack,
    this.embeddedInPlayerShell = false,
  });

  @override
  State<PlayerLeaguesScreen> createState() => _PlayerLeaguesScreenState();
}

class _PlayerLeaguesScreenState extends State<PlayerLeaguesScreen> {
  final _api = LeaguesApi();

  List<LeagueItem> _leagues = [];
  bool _loading = true;
  String? _error;

  String? _expandedId;
  final Map<String, List<SeasonItem>> _seasonsCache = {};
  final Map<String, bool> _seasonsLoading = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() { _loading = true; _error = null; });
      final list = await _api.getLeagues();
      if (mounted) setState(() => _leagues = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSeasons(String leagueId) async {
    if (_seasonsCache.containsKey(leagueId)) return;
    setState(() => _seasonsLoading[leagueId] = true);
    try {
      final list = await _api.getSeasons(leagueId);
      if (mounted) setState(() => _seasonsCache[leagueId] = list);
    } catch (_) {
      if (mounted) setState(() => _seasonsCache[leagueId] = []);
    } finally {
      if (mounted) setState(() => _seasonsLoading[leagueId] = false);
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_expandedId == id) {
        _expandedId = null;
      } else {
        _expandedId = id;
        _loadSeasons(id);
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final body = Column(
      children: [
        _Header(
          onBack: widget.onBack,
          count: _leagues.length,
          embeddedInPlayerShell: widget.embeddedInPlayerShell,
        ),
        Expanded(
          child: _loading
              ? const _Spinner()
              : _error != null
                  ? _ErrorState(error: _error!, onRetry: _load)
                  : _leagues.isEmpty
                      ? const _EmptyState()
                      : RefreshIndicator(
                          color: _accent,
                          backgroundColor: _surface,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
                            itemCount: _leagues.length,
                            itemBuilder: (ctx, i) {
                              final l = _leagues[i];
                              final isExpanded = _expandedId == l.id;
                              return _LeagueCard(
                                league: l,
                                isExpanded: isExpanded,
                                seasons: _seasonsCache[l.id],
                                seasonsLoading: _seasonsLoading[l.id] ?? false,
                                onToggle: () => _toggle(l.id),
                                onSeasonTap: (season) => Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                    builder: (_) => LeagueSeasonScreen(
                                      league: l,
                                      season: season,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );

    if (widget.embeddedInPlayerShell) {
      return ColoredBox(color: _bg, child: body);
    }

    return Scaffold(
      backgroundColor: _bg,
      body: body,
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback? onBack;
  final int count;
  final bool embeddedInPlayerShell;

  const _Header({
    this.onBack,
    required this.count,
    this.embeddedInPlayerShell = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (embeddedInPlayerShell) {
                        Scaffold.maybeOf(context)?.openDrawer();
                      } else if (onBack != null) {
                        onBack!();
                      } else {
                        Navigator.maybePop(context);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Icon(
                        embeddedInPlayerShell ? Icons.menu_rounded : Icons.arrow_back_ios_new,
                        color: _textPrimary,
                        size: embeddedInPlayerShell ? 22 : 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Leagues',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accent.withOpacity(0.3)),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Hero banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accent.withOpacity(0.15), _accent.withOpacity(0.03)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accent.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, color: _accent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Leagues',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Compete with the best players',
                          style: TextStyle(color: _textSecondary, fontSize: 12),
                        ),
                      ],
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
}

// ── League Card ───────────────────────────────────────────────────────────────

class _LeagueCard extends StatelessWidget {
  final LeagueItem league;
  final bool isExpanded;
  final List<SeasonItem>? seasons;
  final bool seasonsLoading;
  final VoidCallback onToggle;
  final void Function(SeasonItem) onSeasonTap;

  const _LeagueCard({
    required this.league,
    required this.isExpanded,
    required this.seasons,
    required this.seasonsLoading,
    required this.onToggle,
    required this.onSeasonTap,
  });

  Color get _statusColor {
    switch (league.status.toUpperCase()) {
      case 'ONGOING': return _accent;
      case 'FINISHED': return _textSecondary;
      default: return _orange;
    }
  }

  Color get _levelColor {
    switch (league.level.toUpperCase()) {
      case 'INTERNATIONAL': return _red;
      case 'CONTINENTAL': return _orange;
      case 'NATIONAL': return _blue;
      default: return const Color(0xFF44DDAA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded ? _accent.withOpacity(0.35) : _border,
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: isExpanded
              ? [BoxShadow(color: _accent.withOpacity(0.08), blurRadius: 20, spreadRadius: -2)]
              : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ──────────────────────────────────────────────
            InkWell(
              onTap: onToggle,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            league.name,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: _textSecondary, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Tags row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (league.gameTitle != null)
                          _Tag(label: league.gameTitle!, color: _blue),
                        _Tag(label: league.level, color: _levelColor),
                        _StatusTag(status: league.status, color: _statusColor),
                        if (league.regionValue.isNotEmpty)
                          _Tag(label: league.regionValue.toUpperCase(), color: _textSecondary),
                      ],
                    ),
                    if (league.participantCount > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.people_alt_outlined, color: _textMuted, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            '${league.participantCount} Participants',
                            style: const TextStyle(color: _textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // ── Seasons (expanded) ───────────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _SeasonsSection(
                seasons: seasons,
                loading: seasonsLoading,
                onSeasonTap: onSeasonTap,
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Seasons Section ───────────────────────────────────────────────────────────

class _SeasonsSection extends StatelessWidget {
  final List<SeasonItem>? seasons;
  final bool loading;
  final void Function(SeasonItem) onSeasonTap;

  const _SeasonsSection({
    required this.seasons,
    required this.loading,
    required this.onSeasonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SEASONS',
            style: TextStyle(
              color: _textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: _accent, strokeWidth: 2))),
            )
          else if (seasons == null || seasons!.isEmpty)
            const Text('No seasons available.',
                style: TextStyle(color: _textSecondary, fontSize: 13))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: seasons!.map((s) => _SeasonPill(season: s, onTap: () => onSeasonTap(s))).toList(),
            ),
        ],
      ),
    );
  }
}

class _SeasonPill extends StatelessWidget {
  final SeasonItem season;
  final VoidCallback onTap;
  const _SeasonPill({required this.season, required this.onTap});

  Color get _color {
    switch (season.status.toUpperCase()) {
      case 'ONGOING': return _accent;
      case 'FINISHED': return _textSecondary;
      default: return _orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded, color: _color, size: 13),
            const SizedBox(width: 6),
            Text(
              season.name,
              style: TextStyle(color: _color, fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded, color: _color.withOpacity(0.6), size: 11),
          ],
        ),
      ),
    );
  }
}

// ── Small tag widgets ─────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusTag({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final isLive = status.toUpperCase() == 'ONGOING';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(width: 5, height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
          ],
          Text(status.toUpperCase(),
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// League Season Screen
// ═════════════════════════════════════════════════════════════════════════════

class LeagueSeasonScreen extends StatefulWidget {
  final LeagueItem league;
  final SeasonItem season;
  const LeagueSeasonScreen({super.key, required this.league, required this.season});

  @override
  State<LeagueSeasonScreen> createState() => _LeagueSeasonScreenState();
}

class _LeagueSeasonScreenState extends State<LeagueSeasonScreen>
    with SingleTickerProviderStateMixin {
  final _api = LeaguesApi();
  late TabController _tabs;

  List<MatchItem> _matches = [];
  List<StandingItem> _standings = [];
  bool _matchesLoading = true;
  bool _standingsLoading = false;
  String? _matchesError;
  String? _standingsError;

  // For auto-refresh of live matches
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1 && _standings.isEmpty && !_standingsLoading) {
        _loadStandings();
      }
    });
    _loadMatches();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    try {
      setState(() { _matchesLoading = true; _matchesError = null; });
      final list = await _api.getMatches(widget.season.id);
      if (mounted) setState(() => _matches = list);
      _scheduleRefreshIfNeeded(list);
    } catch (e) {
      if (mounted) setState(() => _matchesError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _matchesLoading = false);
    }
  }

  Future<void> _loadStandings() async {
    try {
      setState(() { _standingsLoading = true; _standingsError = null; });
      final list = await _api.getStandings(widget.season.id);
      if (mounted) setState(() => _standings = list);
    } catch (e) {
      if (mounted) setState(() => _standingsError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _standingsLoading = false);
    }
  }

  void _scheduleRefreshIfNeeded(List<MatchItem> matches) {
    _refreshTimer?.cancel();
    final hasLive = matches.any((m) => m.isLive);
    // If there's an ongoing match, poll every 30 s to catch status changes
    if (hasLive) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadMatches());
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _SeasonHeader(league: widget.league, season: widget.season, tabs: _tabs),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _MatchesTab(
                  matches: _matches,
                  loading: _matchesLoading,
                  error: _matchesError,
                  onRefresh: _loadMatches,
                ),
                _StandingsTab(
                  standings: _standings,
                  loading: _standingsLoading,
                  error: _standingsError,
                  onRefresh: _loadStandings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Season Header ─────────────────────────────────────────────────────────────

class _SeasonHeader extends StatelessWidget {
  final LeagueItem league;
  final SeasonItem season;
  final TabController tabs;
  const _SeasonHeader({required this.league, required this.season, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: _textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          league.name,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          season.name,
                          style: const TextStyle(color: _textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _StatusTag(
                    status: season.status,
                    color: season.status.toUpperCase() == 'ONGOING' ? _accent : _orange,
                  ),
                ],
              ),
            ),
            TabBar(
              controller: tabs,
              indicatorColor: _accent,
              indicatorWeight: 2,
              labelColor: _accent,
              unselectedLabelColor: _textSecondary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Matches'),
                Tab(text: 'Standings'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Matches Tab
// ═════════════════════════════════════════════════════════════════════════════

class _MatchesTab extends StatelessWidget {
  final List<MatchItem> matches;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  const _MatchesTab({
    required this.matches,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _Spinner();
    if (error != null) return _ErrorState(error: error!, onRetry: onRefresh);
    if (matches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_esports_outlined, color: _textMuted, size: 48),
            SizedBox(height: 12),
            Text('No matches yet', style: TextStyle(color: _textSecondary, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _accent,
      backgroundColor: _surface,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: matches.length,
        itemBuilder: (_, i) => _MatchCard(match: matches[i]),
      ),
    );
  }
}

// ── Match Card ────────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final MatchItem match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isLive = match.isLive;
    final isDone = match.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLive ? _accent.withOpacity(0.4) : _border,
            width: isLive ? 1.5 : 1,
          ),
          boxShadow: isLive
              ? [BoxShadow(color: _accent.withOpacity(0.1), blurRadius: 16, spreadRadius: -2)]
              : [],
        ),
        child: Column(
          children: [
            // ── Teams + score ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  // Team 1
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TeamAvatar(name: match.team1Name, color: _blue),
                        const SizedBox(height: 8),
                        Text(
                          match.team1Name,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Score / VS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: isDone
                        ? Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _cardHigh,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _border),
                                ),
                                child: Text(
                                  '${match.team1GamesWon}  –  ${match.team2GamesWon}',
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'VS',
                            style: TextStyle(
                              color: isLive ? _accent : _textMuted,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                  // Team 2
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _TeamAvatar(name: match.team2Name, color: _orange, align: Alignment.centerRight),
                        const SizedBox(height: 8),
                        Text(
                          match.team2Name,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Footer: date + LIVE button ─────────────────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _border)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: _textMuted, size: 13),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _formatDate(match.scheduledDateTime),
                      style: const TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ),
                  _LiveButton(match: match),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'TBD';
    final local = dt.toLocal();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}  ·  $h:$m';
  }
}

class _TeamAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final Alignment align;
  const _TeamAvatar({required this.name, required this.color, this.align = Alignment.centerLeft});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Align(
      alignment: align,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(initial,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}

// ── LIVE Button ───────────────────────────────────────────────────────────────

class _LiveButton extends StatefulWidget {
  final MatchItem match;
  const _LiveButton({required this.match});

  @override
  State<_LiveButton> createState() => _LiveButtonState();
}

class _LiveButtonState extends State<_LiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  Timer? _activationTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulse = Tween(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _syncAnimation();
    _scheduleActivation();
  }

  void _syncAnimation() {
    if (widget.match.isLive) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  /// Schedule a one-shot timer to auto-activate the button at scheduledStart.
  void _scheduleActivation() {
    final dt = widget.match.scheduledDateTime;
    if (dt == null || widget.match.isLive) return;
    final diff = dt.toLocal().difference(DateTime.now());
    if (diff.isNegative || diff.inSeconds == 0) return;
    _activationTimer = Timer(diff, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void didUpdateWidget(_LiveButton old) {
    super.didUpdateWidget(old);
    if (widget.match.isLive != old.match.isLive) _syncAnimation();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _activationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;

    // Determine visual state
    Color color;
    String label;
    bool animated = false;

    if (m.isLive) {
      color = _accent;
      label = 'LIVE';
      animated = true;
    } else if (m.isCompleted) {
      color = _blue;
      label = 'ENDED';
    } else if (m.isCancelled) {
      color = _red;
      label = 'CANCELLED';
    } else {
      // SCHEDULED — check if start time is very close (< 5 min)
      final dt = m.scheduledDateTime;
      final diff = dt != null ? dt.toLocal().difference(DateTime.now()) : null;
      if (diff != null && !diff.isNegative && diff.inMinutes <= 5) {
        color = _orange;
        label = 'SOON';
      } else {
        color = _textSecondary;
        label = 'UPCOMING';
      }
    }

    if (!animated) {
      return _badge(color, label, opacity: 1.0, dotOpacity: 0.5);
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => _badge(color, label,
          opacity: _pulse.value, dotOpacity: _pulse.value),
    );
  }

  Widget _badge(Color color, String label,
      {required double opacity, required double dotOpacity}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12 * opacity),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5 * opacity)),
        boxShadow: widget.match.isLive
            ? [BoxShadow(color: color.withOpacity(0.2 * opacity), blurRadius: 8)]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(dotOpacity),
              shape: BoxShape.circle,
              boxShadow: widget.match.isLive
                  ? [BoxShadow(color: color.withOpacity(0.4 * dotOpacity), blurRadius: 6)]
                  : [],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(opacity),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Standings Tab
// ═════════════════════════════════════════════════════════════════════════════

class _StandingsTab extends StatelessWidget {
  final List<StandingItem> standings;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  const _StandingsTab({
    required this.standings,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _Spinner();
    if (error != null) return _ErrorState(error: error!, onRetry: onRefresh);
    if (standings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined, color: _textMuted, size: 48),
            SizedBox(height: 12),
            Text('No standings yet', style: TextStyle(color: _textSecondary, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _accent,
      backgroundColor: _surface,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Row(
              children: [
                SizedBox(width: 32, child: Text('#', style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                Expanded(child: Text('TEAM', style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1))),
                SizedBox(width: 32, child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                SizedBox(width: 32, child: Text('L', textAlign: TextAlign.center, style: TextStyle(color: _textMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                SizedBox(width: 40, child: Text('PTS', textAlign: TextAlign.right, style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...standings.map((s) => _StandingRow(standing: s)),
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final StandingItem standing;
  const _StandingRow({required this.standing});

  Color get _rankColor {
    switch (standing.rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFBBBBBB);
      case 3: return const Color(0xFFCD7F32);
      default: return _textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = standing.rank <= 3 && standing.rank > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isTop3 ? _rankColor.withOpacity(0.06) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTop3 ? _rankColor.withOpacity(0.3) : _border,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${standing.rank}',
                style: TextStyle(
                  color: _rankColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: Text(
                standing.teamName,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 32,
              child: Text('${standing.wins}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            SizedBox(
              width: 32,
              child: Text('${standing.losses}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _red, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            SizedBox(
              width: 40,
              child: Text('${standing.points}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared utility widgets
// ═════════════════════════════════════════════════════════════════════════════

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 32, height: 32,
        child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.emoji_events_outlined, color: _textMuted, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('No leagues found',
              style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Check back later for upcoming competitions.',
              style: TextStyle(color: _textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: _red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _red.withOpacity(0.3)),
              ),
              child: const Icon(Icons.error_outline_rounded, color: _red, size: 32),
            ),
            const SizedBox(height: 16),
            Text(error,
                style: const TextStyle(color: _textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accent.withOpacity(0.4)),
                ),
                child: const Text('Retry',
                    style: TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
