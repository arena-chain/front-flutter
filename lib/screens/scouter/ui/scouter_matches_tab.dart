import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_matches_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_ui_tokens.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

class ScouterMatchesTab extends StatelessWidget {
  const ScouterMatchesTab({super.key});

  static const _filters = ['LIVE', 'TODAY', 'UPCOMING', 'RESULTS'];

  @override
  Widget build(BuildContext context) {
    return Consumer<ScouterMatchesViewModel>(
      builder: (context, vm, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilterChips(vm),
            Expanded(
              child: (vm.isLoading && vm.allMatches.isEmpty)
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: ScouterUiTokens.accentGreen))
                  : vm.error != null
                      ? _errorState(vm)
                      : _buildMatchList(context, vm),
            ),
          ],
        );
      },
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matches',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'League schedules and your evaluated players',
            style: TextStyle(color: ScouterUiTokens.textSecondary, fontSize: 13),
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                    ? ScouterUiTokens.accentGreen
                    : ScouterUiTokens.chipInactiveBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? ScouterUiTokens.accentGreen
                      : ScouterUiTokens.chipInactiveBorder,
                ),
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
                          ? ScouterUiTokens.scaffoldBg
                          : ScouterUiTokens.textSecondary,
                      fontSize: 12,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
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
      color: ScouterUiTokens.accentGreen,
      backgroundColor: ScouterUiTokens.card,
      onRefresh: vm.loadMatches,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: matches.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
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
        ? ScouterUiTokens.accentGreen
        : status == 'UPCOMING'
            ? ScouterUiTokens.accentBlue
            : ScouterUiTokens.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScouterUiTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive
              ? ScouterUiTokens.accentGreen.withValues(alpha: 0.35)
              : ScouterUiTokens.cardBorder,
        ),
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
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: ScouterUiTokens.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
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
                        color: ScouterUiTokens.textMuted, fontSize: 11)),
              ],
            ],
          ),
          const Spacer(),
          // Score
          Text(
            score,
            style: TextStyle(
              color: isLive ? ScouterUiTokens.accentGreen : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right,
              color: ScouterUiTokens.textMuted, size: 18),
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
          const Icon(Icons.sports_esports_outlined,
              color: ScouterUiTokens.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            messages[filter] ?? 'No matches found.',
            style: const TextStyle(color: ScouterUiTokens.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Open Leagues for full schedules, or add\nplayers to your list to see their matches.',
            style: TextStyle(color: ScouterUiTokens.textMuted, fontSize: 12),
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
          const Icon(Icons.error_outline,
              color: Color(0xFFFF0055), size: 40),
          const SizedBox(height: 10),
          Text(
            vm.error ?? 'Something went wrong.',
            style: const TextStyle(color: Color(0xFFFF0055), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: vm.loadMatches,
            child: const Text('Retry',
                style: TextStyle(color: ScouterUiTokens.accentGreen)),
          ),
        ],
      ),
    );
  }
}

// ─── Small pulse dot (LIVE filter chip) ──────────────────────────────────────

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
                ? ScouterUiTokens.scaffoldBg.withValues(alpha: 0.35 + 0.65 * _anim.value)
                : ScouterUiTokens.accentGreen.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: ScouterUiTokens.scaffoldBg
                          .withValues(alpha: 0.25 * _anim.value),
                      blurRadius: 6 * _anim.value,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
        );
      },
    );
  }
}
