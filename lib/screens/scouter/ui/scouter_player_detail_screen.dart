import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_player_detail_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/create_report_bottom_sheet.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/create_recommendation_bottom_sheet.dart';

// ─────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────

Color _tierColor(String tier) {
  switch (tier.toUpperCase()) {
    case 'RADIANT':
    case 'GRANDMASTER':
      return const Color(0xFFFF4444);
    case 'IMMORTAL':
    case 'CHALLENGER':
      return const Color(0xFFFF6644);
    case 'MASTER':
      return const Color(0xFFAA44FF);
    case 'DIAMOND':
      return const Color(0xFF4488FF);
    case 'PLATINUM':
      return const Color(0xFF44DDAA);
    case 'GOLD':
      return const Color(0xFFFFCC00);
    case 'SILVER':
      return const Color(0xFFCCCCCC);
    default:
      return const Color(0xFF00FF00);
  }
}

// ─────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────

class ScouterPlayerDetailScreen extends StatefulWidget {
  final String playerUserId;
  final String scouterId;
  final VoidCallback? onReportCreated;

  const ScouterPlayerDetailScreen({
    super.key,
    required this.playerUserId,
    required this.scouterId,
    this.onReportCreated,
  });

  @override
  State<ScouterPlayerDetailScreen> createState() =>
      _ScouterPlayerDetailScreenState();
}

class _ScouterPlayerDetailScreenState
    extends State<ScouterPlayerDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final ScouterPlayerDetailViewModel _vm;
  bool _expandBio = false;

  static const _wlCycle = [
    'UNKNOWN', 'WATCHLIST', 'PROSPECT', 'ELITE_PROSPECT', 'SIGNED'
  ];
  String _wlLevel = 'UNKNOWN';
  bool _savingWl = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _vm = ScouterPlayerDetailViewModel(scouterId: widget.scouterId);
    _vm.loadPlayer(widget.playerUserId).then((_) {
      if (_vm.prospect != null && mounted) {
        setState(() => _wlLevel = _vm.prospect!.prospectLevel);
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _cycleWatchlist() async {
    final next = _wlCycle[(_wlCycle.indexOf(_wlLevel) + 1) % _wlCycle.length];
    setState(() { _savingWl = true; _wlLevel = next; });
    try {
      _vm.selectedProspectLevel = next;
      await _vm.saveProspect(_vm.player?.id ?? '');
    } catch (_) {}
    if (mounted) setState(() => _savingWl = false);
  }

  Color _wlColor(String l) {
    switch (l) {
      case 'WATCHLIST': return const Color(0xFF00AAFF);
      case 'PROSPECT': case 'ELITE_PROSPECT': return const Color(0xFFFFAA00);
      case 'SIGNED': return const Color(0xFF00FF00);
      default: return const Color(0xFF4A5568);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<ScouterPlayerDetailViewModel>(
        builder: (ctx, vm, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (vm.actionSuccess != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(vm.actionSuccess!),
                backgroundColor: const Color(0xFF00FF00).withValues(alpha: 0.9),
              ));
              vm.clearAction();
            } else if (vm.error != null) {
              // Don't show raw API errors (e.g. "Cannot GET/POST /api/...") to the user
              final isApiError = vm.error!.contains('Cannot GET') ||
                  vm.error!.contains('Cannot POST') ||
                  vm.error!.contains('404') || vm.error!.contains('500');
              if (!isApiError) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(vm.error!),
                  backgroundColor: const Color(0xFFFF0055).withValues(alpha: 0.9),
                ));
              }
              vm.clearAction();
            }
          });

          return Scaffold(
            backgroundColor: const Color(0xFF0A0E1A),
            body: vm.isLoading
                ? _loading()
                : Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _heroSection(ctx, vm),
                            _playerMeta(vm),
                            _pillTags(vm),
                            _aboutSection(vm),
                            _statsRow(vm),
                            _matchHighlights(vm),
                            _tabSection(vm),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                      // Sticky bottom CTA
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        child: _bottomBar(ctx, vm),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────

  Widget _loading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: const Color(0xFF00FF00),
              strokeWidth: 2.5,
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading profile…',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Banner ─────────────────────────────────────────────

  Widget _heroSection(BuildContext ctx, ScouterPlayerDetailViewModel vm) {
    final tier = vm.player?.tier ?? vm.player?.rank ?? 'UNRANKED';
    final tColor = _tierColor(tier);

    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Clean dark gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF040609), Color(0xFF0A0E1A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Deep atmospheric glow
          Positioned(
            top: -150, left: -100, right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 0.8,
                  colors: [tColor.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          // Watermark initial
          Positioned(
            right: 20, top: 60,
            child: Text(
              (vm.player?.userId?.nickname ?? '?')[0].toUpperCase(),
              style: TextStyle(
                color: tColor.withValues(alpha: 0.06),
                fontSize: 140,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // Bottom fade
          Positioned(
            left: 0, right: 0, bottom: 0,
            height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFF0A0E1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Nav buttons - glass style
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navCircleBtn(icon: Icons.arrow_back_ios_new, onTap: () => Navigator.pop(ctx)),
                  _navCircleBtn(
                    icon: _wlLevel == 'UNKNOWN' ? Icons.bookmark_border_rounded : Icons.bookmark_rounded,
                    color: _wlColor(_wlLevel),
                    onTap: _savingWl ? null : _cycleWatchlist,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navCircleBtn({
    required IconData icon,
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // ── Player Meta (Avatar + Name) ────────────────────────────

  Widget _playerMeta(ScouterPlayerDetailViewModel vm) {
    final nickname = vm.player?.userId?.nickname ?? 'Unknown Player';
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';
    final tier = vm.player?.tier ?? vm.player?.rank ?? 'UNRANKED';
    final isPro = vm.player?.isPro ?? false;
    final tColor = _tierColor(tier);
    final teamName = vm.player?.team?.name;

    return Transform.translate(
      offset: const Offset(0, -44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Hyper-modern avatar
            Container(
              width: 104, height: 104,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [tColor.withValues(alpha: 0.8), tColor.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tColor.withValues(alpha: 0.25),
                    blurRadius: 32,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF040609),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: tColor,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isPro) ...[
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF00).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, color: Color(0xFF00FF00), size: 16),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          nickname,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (teamName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      teamName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111625).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, color: Color(0xFF00FF00), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${vm.player?.elo ?? 0} ELO',
                              style: const TextStyle(
                                color: Color(0xFF00FF00),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111625).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Text(
                          tier,
                          style: TextStyle(
                            color: tColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pill Tags ──────────────────────────────────────────────

  Widget _pillTags(ScouterPlayerDetailViewModel vm) {
    final tags = <String>[
      vm.player?.region ?? 'GLOBAL',
      vm.player?.isPro == true ? 'PRO' : 'AMATEUR',
      if (_wlLevel != 'UNKNOWN') _wlLevel.replaceAll('_', ' '),
    ];

    return Transform.translate(
      offset: const Offset(0, -28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: tags.map((t) => _pillTag(t)).toList(),
        ),
      ),
    );
  }

  Widget _pillTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── About Section ──────────────────────────────────────────

  Widget _aboutSection(ScouterPlayerDetailViewModel vm) {
    final nickname = vm.player?.userId?.nickname ?? 'this player';
    final bio = 'Player profile for $nickname. Currently tracked on ArenaChain scouting platform. '
        'Use the tabs below to explore their match history, scouting reports, and performance stats.';

    final displayText = _expandBio
        ? bio
        : '${bio.substring(0, math.min(bio.length, 100))}...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111625).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4, height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF00),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'About This Player',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: displayText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => setState(() => _expandBio = !_expandBio),
                          child: Text(
                            _expandBio ? '  Show Less' : '  Read More',
                            style: const TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
    );
  }

  // ── Stats Row ─────────────────────────────────────────────

  Widget _statsRow(ScouterPlayerDetailViewModel vm) {
    final matches = vm.matches.length;
    final wins = vm.matches.where((m) => m.team1GamesWon > m.team2GamesWon).length;
    final hours = vm.player?.stats?['hoursPlayed'] ?? '120h';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          Expanded(child: _statCard(Icons.sports_esports_rounded, '$matches', 'Matches')),
          const SizedBox(width: 12),
          Expanded(child: _statCard(Icons.emoji_events_rounded, '$wins', 'Victories')),
          const SizedBox(width: 12),
          Expanded(child: _statCard(Icons.schedule_rounded, '$hours', 'Hours')),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111625).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF00FF00), size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Match Highlights horizontal scroll ─────────────────────

  Widget _matchHighlights(ScouterPlayerDetailViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child: Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF00),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Highlights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 24, right: 24),
            itemCount: 4,
            itemBuilder: (ctx, i) => _highlightCard(i),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static const _clipTitles = ['CLUTCH ROUND', 'ACE PLAY', 'TOP FRAG', 'FINALS VOD'];
  static const _clipDurations = ['0:42', '1:15', '3:20', '45:30'];

  Widget _highlightCard(int i) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FF00).withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF00).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00FF00), width: 2),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF00FF00), size: 28),
            ),
          ),
          Positioned(
            left: 12, right: 12, bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _clipTitles[i % _clipTitles.length],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _clipDurations[i % _clipDurations.length],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs ────────────────────────────────────────────────────

  Widget _tabSection(ScouterPlayerDetailViewModel vm) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TabBar(
            controller: _tab,
            indicator: BoxDecoration(
              color: const Color(0xFF00FF00).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.5)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: const Color(0xFF00FF00),
            unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Matches'),
              Tab(text: 'Reports'),
              Tab(text: 'Scouting'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: TabBarView(
            controller: _tab,
            children: [
              _MatchesTab(vm: vm),
              _ReportsTab(vm: vm),
              _ScoutingTab(vm: vm),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sticky Bottom Action Bar ──────────────────────────────

  Widget _bottomBar(BuildContext ctx, ScouterPlayerDetailViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A0E1A).withValues(alpha: 0),
            const Color(0xFF0A0E1A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showReport(ctx, vm),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00FF00), Color(0xFF00CC88)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF00).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Color(0xFF060A14), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Create Report',
                          style: TextStyle(
                            color: Color(0xFF060A14),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showRecommendation(ctx, vm),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFAA44FF).withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.send_rounded, color: Color(0xFFAA44FF), size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: vm.isAddingToEvaluated
                  ? null
                  : () => vm.addToEvaluated(vm.player?.id ?? ''),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (vm.isAddingToEvaluated ? Colors.grey : const Color(0xFF00AAFF))
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.radar_rounded,
                  color: vm.isAddingToEvaluated
                      ? Colors.white.withValues(alpha: 0.3)
                      : const Color(0xFF00AAFF),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReport(BuildContext ctx, ScouterPlayerDetailViewModel vm) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF0F1221),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateReportBottomSheet(
        scouterId: widget.scouterId,
        playerId: vm.player?.id ?? '',
        playerNickname: vm.player?.userId?.nickname,
        onSubmit: vm.createReport,
        onReportCreated: widget.onReportCreated,
      ),
    );
  }

  void _showRecommendation(BuildContext ctx, ScouterPlayerDetailViewModel vm) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF0F1221),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateRecommendationBottomSheet(
        scouterId: widget.scouterId,
        playerId: vm.player?.id ?? '',
        onSubmit: vm.createRecommendation,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Circuit Board Background Painter
// ─────────────────────────────────────────────────────────────

class _CircuitPainter extends CustomPainter {
  final Color color;
  const _CircuitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Horizontal lines
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Dots at intersections
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    for (double y = 0; y < size.height; y += 30) {
      for (double x = 0; x < size.width; x += 30) {
        canvas.drawCircle(Offset(x, y), 2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter old) => old.color != color;
}

// ═══════════════════════════════════════════════════
// Tab: Matches
// ═══════════════════════════════════════════════════

class _MatchesTab extends StatelessWidget {
  final ScouterPlayerDetailViewModel vm;
  const _MatchesTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_esports_outlined,
                color: Colors.white.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 12),
            Text(
              'No matches found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: vm.matches.length,
      itemBuilder: (_, i) {
        final m = vm.matches[i];
        final win = m.team1GamesWon > m.team2GamesWon;
        final c = win ? const Color(0xFF00FF00) : const Color(0xFFFF0055);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      win ? 'VICTORY' : 'DEFEAT',
                      style: TextStyle(
                        color: c,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (m.scheduledStart != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        m.scheduledStart!.length >= 10
                            ? m.scheduledStart!.substring(0, 10)
                            : m.scheduledStart!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${m.team1GamesWon} – ${m.team2GamesWon}',
                  style: TextStyle(
                    color: c,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════
// Tab: Reports
// ═══════════════════════════════════════════════════

class _ReportsTab extends StatelessWidget {
  final ScouterPlayerDetailViewModel vm;
  const _ReportsTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined,
                color: Colors.white.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 12),
            Text(
              'No reports yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: vm.reports.length,
      itemBuilder: (_, i) {
        final r = vm.reports[i];
        final rc = r.rating >= 80
            ? const Color(0xFF00FF00)
            : r.rating >= 60
                ? const Color(0xFFFFAA00)
                : const Color(0xFFFF0055);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: rc.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: rc, width: 2),
                ),
                child: Center(
                  child: Text('${r.rating}',
                      style: TextStyle(
                        color: rc, fontSize: 16, fontWeight: FontWeight.w900,
                      )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.recommendedRole != null)
                      Text(r.recommendedRole!,
                          style: const TextStyle(
                            color: Color(0xFF00FF00), fontSize: 13,
                            fontWeight: FontWeight.w700,
                          )),
                    if (r.strengths != null)
                      Text('+ ${r.strengths}',
                          style: const TextStyle(
                              color: Color(0xFFBBC4D4), fontSize: 12)),
                    if (r.weaknesses != null)
                      Text('- ${r.weaknesses}',
                          style: const TextStyle(
                              color: Color(0xFF7A86AC), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════
// Tab: Scouting (Info)
// ═══════════════════════════════════════════════════

class _ScoutingTab extends StatelessWidget {
  final ScouterPlayerDetailViewModel vm;
  const _ScoutingTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    final p = vm.player;
    final xp = p?.stats?['xp'] ?? 1250;
    final xpInt = int.tryParse(xp.toString().replaceAll(',', '')) ?? 1250;
    final xpProgress = (xpInt % 2000) / 2000.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // XP bar
          _xpCard(xp, xpProgress),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _infoCard(
                Icons.bolt,
                'ELO',
                '${p?.elo ?? 0}',
                const Color(0xFF00FF00),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _infoCard(
                Icons.military_tech,
                'TIER',
                p?.tier ?? p?.rank ?? '—',
                _tierColor(p?.tier ?? p?.rank ?? ''),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _infoCard(
                Icons.group,
                'TEAM',
                p?.team?.name ?? 'Free Agent',
                const Color(0xFFFFAA00),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _infoCard(
                Icons.public,
                'REGION',
                p?.region ?? '—',
                const Color(0xFF00AAFF),
              ),
            ),
          ]),
          if (vm.prospect != null) ...[
            const SizedBox(height: 10),
            _prospectCard(vm.prospect!.prospectLevel, vm.prospect!.priority ?? 'MEDIUM'),
          ],
        ],
      ),
    );
  }

  Widget _xpCard(dynamic xp, double progress) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFAA44FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.star, color: Color(0xFFAA44FF), size: 16),
            const SizedBox(width: 6),
            const Text('Experience Points',
                style: TextStyle(color: Color(0xFF8B97B5), fontSize: 12)),
            const Spacer(),
            Text('$xp XP',
                style: const TextStyle(
                  color: Color(0xFFAA44FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                )),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFF1A2333),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF00)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF4A5568), fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 14,
                  fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _prospectCard(String level, String priority) {
    final displayLevel = level == 'ELITE_PROSPECT' ? '★ ELITE PROSPECT' : level;
    final lColor = level == 'WATCHLIST'
        ? const Color(0xFF00AAFF)
        : level == 'PROSPECT' || level == 'ELITE_PROSPECT'
            ? const Color(0xFFFFAA00)
            : level == 'SIGNED'
                ? const Color(0xFF00FF00)
                : const Color(0xFF4A5568);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: lColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(displayLevel,
                style: TextStyle(
                    color: lColor, fontSize: 13, fontWeight: FontWeight.w800)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2333),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(priority,
                style: const TextStyle(
                    color: Color(0xFFBBC4D4), fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
