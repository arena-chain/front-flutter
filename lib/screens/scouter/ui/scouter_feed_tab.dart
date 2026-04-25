import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_matches_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_public_highlights_view_model.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_highlight_detail_screen.dart';

class ScouterFeedTab extends StatelessWidget {
  final String scouterId;

  const ScouterFeedTab({super.key, required this.scouterId});

  static const _filters = ['LIVE', 'TODAY', 'UPCOMING', 'RESULTS'];

  @override
  Widget build(BuildContext context) {
    return Consumer2<ScouterMatchesViewModel, ScouterPublicHighlightsViewModel>(
      builder: (context, vm, hlVm, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildTopHighlightsRow(context, hlVm),
            _buildFilterChips(vm),
            Expanded(
              child: vm.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00FF00)))
                  : vm.error != null
                      ? _errorState(vm)
                      : _buildMatchList(context, vm),
            ),
          ],
        );
      },
    );
  }

  /// Public clips ranked by reactions (likes + comments + saves) — same idea as web scouter dashboard.
  Widget _buildTopHighlightsRow(BuildContext context, ScouterPublicHighlightsViewModel hlVm) {
    if (!hlVm.isLoading && hlVm.highlights.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF00FF00), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Top highlights',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hlVm.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00FF00),
                  ),
                )
              else
                Text(
                  '${hlVm.highlights.length} clips',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: hlVm.isLoading && hlVm.highlights.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00FF00)),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  itemCount: hlVm.highlights.length,
                  itemBuilder: (ctx, i) {
                    final h = hlVm.highlights[i];
                    return _feedHighlightCard(context, h);
                  },
                ),
        ),
      ],
    );
  }

  Widget _feedHighlightCard(BuildContext context, HighlightItem h) {
    final thumb = h.thumbnailUrl;
    final clip = h.clipUrl;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ScouterHighlightDetailScreen(highlight: h),
            ),
          );
        },
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.35)),
            color: const Color(0xFF111625).withValues(alpha: 0.8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null && thumb.isNotEmpty)
                Image.network(
                  thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black26),
                )
              else if (clip != null && clip.isNotEmpty)
                const ColoredBox(color: Colors.black45)
              else
                const ColoredBox(color: Colors.black26),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 36),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  h.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final nickname = auth.currentUser?.nickname ?? 'Scout';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Matches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Welcome, $nickname',
                  style: const TextStyle(color: Color(0xFF8B95A5), fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF111625).withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF8B95A5),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Chips ─────────────────────────────────────────────────────────

  Widget _buildFilterChips(ScouterMatchesViewModel vm) {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final f = _filters[i];
          final isActive = vm.activeFilter == f;
          return GestureDetector(
            onTap: () => vm.setFilter(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF00FF00).withValues(alpha: 0.10)
                    : const Color(0xFF111625).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF00FF00).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.05),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00FF00).withValues(alpha: 0.15),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (f == 'LIVE') ...[
                    _SmallPulseDot(active: isActive),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    f,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF00FF00)
                          : const Color(0xFF8B95A5),
                      fontSize: 12,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Match List ───────────────────────────────────────────────────────────

  Widget _buildMatchList(BuildContext context, ScouterMatchesViewModel vm) {
    final matches = vm.filtered;
    if (matches.isEmpty) {
      return _emptyState(vm.activeFilter);
    }
    return RefreshIndicator(
      color: const Color(0xFF00FF00),
      backgroundColor: const Color(0xFF111625),
      onRefresh: vm.loadMatches,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // padding for floating nav
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _matchCard(matches[i]),
      ),
    );
  }

  Widget _matchCard(MatchSummary m) {
    final status = (m.status ?? 'COMPLETED').toUpperCase();
    final isLive = status == 'LIVE' || status == 'IN_PROGRESS';
    final score = '${m.team1GamesWon} – ${m.team2GamesWon}';
    final date = m.scheduledStart != null && m.scheduledStart!.length >= 10
        ? m.scheduledStart!.substring(0, 10)
        : (m.scheduledStart ?? '');

    final statusColor = isLive
        ? const Color(0xFF00FF00)
        : status == 'UPCOMING'
            ? const Color(0xFF00AAFF)
            : const Color(0xFF8B95A5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111625).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive
              ? const Color(0xFF00FF00).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (isLive)
            BoxShadow(
              color: const Color(0xFF00FF00).withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isLive) ...[
                    const _SmallPulseDot(active: true),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isLive ? 'LIVE' : status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(date,
                    style: const TextStyle(
                        color: Color(0xFF8B95A5), fontSize: 11)),
              ],
            ],
          ),
          const Spacer(),
          // Score
          Text(
            score,
            style: TextStyle(
              color: isLive ? const Color(0xFF00FF00) : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right,
              color: Color(0xFF8B95A5), size: 18),
        ],
      ),
    );
  }

  // ─── States ───────────────────────────────────────────────────────────────

  Widget _emptyState(String filter) {
    final messages = {
      'LIVE': 'No live matches right now.',
      'TODAY': 'No matches scheduled for today.',
      'UPCOMING': 'No upcoming matches found.',
      'RESULTS': 'No completed matches yet.',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF111625).withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Icon(Icons.sports_esports_outlined,
                color: Color(0xFF8B95A5), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            messages[filter] ?? 'No matches found.',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Scout and evaluate players to\nsee their matches here.',
            style: TextStyle(color: Color(0xFF8B95A5), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _errorState(ScouterMatchesViewModel vm) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFF0055).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF0055).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Color(0xFFFF0055), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            vm.error ?? 'Something went wrong.',
            style: const TextStyle(color: Color(0xFFFF0055), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: vm.loadMatches,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.4)),
                ),
                child: const Text('Retry',
                    style: TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small pulse dot used by filter chips ─────────────────────────────────────

class _SmallPulseDot extends StatefulWidget {
  final bool active;
  const _SmallPulseDot({required this.active});

  @override
  State<_SmallPulseDot> createState() => _SmallPulseDotState();
}

class _SmallPulseDotState extends State<_SmallPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.active
                ? const Color(0xFF00FF00).withValues(alpha: _anim.value)
                : const Color(0xFF00FF00).withValues(alpha: 0.5),
            shape: BoxShape.circle,
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: const Color(0xFF00FF00).withValues(alpha: _anim.value * 0.6),
                      blurRadius: 8 * _anim.value,
                      spreadRadius: 2 * _anim.value,
                    )
                  ]
                : [],
          ),
        );
      },
    );
  }
}
