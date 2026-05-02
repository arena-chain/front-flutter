import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/view_all_api.dart';
import 'package:arena_chain_flutter/core/models/view_all_models.dart';

// ── Design tokens ──────────────────────────────────────────────
const _bgTop          = Color(0xFF040609);
const _bgBottom       = Color(0xFF0A0D14);
const _surface        = Color(0xFF111625);
const _card           = Color(0xFF111625);
const _cardElevated   = Color(0xFF161C2C);
const _border         = Color(0x0DFFFFFF); // Colors.white.withValues(alpha: 0.05)
const _accent         = Color(0xFF00FF00);
const _textSecondary  = Color(0xFF8B95A5);

class ViewAllTournamentsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ViewAllTournamentsScreen({super.key, this.onBack});

  @override
  State<ViewAllTournamentsScreen> createState() => _ViewAllTournamentsScreenState();
}

class _ViewAllTournamentsScreenState extends State<ViewAllTournamentsScreen> {
  final _api = ViewAllApi();

  List<TournamentListItem> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() { _loading = true; _error = null; });
      final t = await _api.getAllTournaments();
      if (mounted) setState(() => _all = t);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_bgTop, _bgBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _header(context),
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: _accent,
                              strokeWidth: 2.5,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading tournaments…',
                            style: TextStyle(color: _textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                      ? _errorState()
                      : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext ctx) {
    return Container(
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: const Border(bottom: BorderSide(color: _border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else {
                      Navigator.pop(ctx);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _card.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'All Tournaments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _accent.withValues(alpha: 0.2),
                      _accent.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${_all.length}',
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Tournaments',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_all.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _surface.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.emoji_events_outlined, color: _textSecondary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tournaments found',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _accent,
      backgroundColor: _surface,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // padding for floating nav
        itemCount: _all.length,
        itemBuilder: (ctx, i) => _tournamentCard(_all[i]),
      ),
    );
  }

  Widget _tournamentCard(TournamentListItem t) {
    final statusColor = _statusColor(t.status);
    final isLive = t.status.toUpperCase() == 'ONGOING';
    final start = t.startDate != null && t.startDate!.length >= 10
        ? t.startDate!.substring(0, 10)
        : null;
    final end = t.endDate != null && t.endDate!.length >= 10
        ? t.endDate!.substring(0, 10)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Optional: navigate to tournament detail
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: _cardElevated.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLive ? _accent.withValues(alpha: 0.3) : _border,
              ),
              boxShadow: [
                if (isLive)
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.1),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  if (isLive)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _accent.withValues(alpha: 0.8),
                              _accent.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ────────────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    statusColor.withValues(alpha: 0.2),
                                    statusColor.withValues(alpha: 0.05),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: const Center(
                                child: Icon(Icons.emoji_events_rounded, color: Color(0xFFFFAA00), size: 24),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  if (t.gameTitle != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.sports_esports_rounded, size: 14, color: _textSecondary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            t.gameTitle!,
                                            style: TextStyle(color: _textSecondary, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Body info ─────────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tags row
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Status pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isLive) ...[
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: _accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        t.status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _chip(t.format.replaceAll('_', ' ').toUpperCase(), const Color(0xFF00AAFF)),
                                if (t.registrationOpen)
                                  _chip('REG. OPEN', const Color(0xFF00FF00)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Stats grid
                            Row(
                              children: [
                                Expanded(
                                  child: _statCell(
                                    Icons.groups_rounded,
                                    '${t.currentTeams} / ${t.maxTeams}',
                                    'Teams',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _statCell(
                                    Icons.emoji_events_rounded,
                                    '\$${_format(t.prizePool)}',
                                    'Prize Pool',
                                  ),
                                ),
                                if (t.firstPlace > 0) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _statCell(
                                      Icons.workspace_premium_rounded,
                                      '\$${_format(t.firstPlace)}',
                                      '1st Place',
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // Dates
                            if (start != null || end != null) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, color: _textSecondary, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    [if (start != null) start, if (end != null) end].join(' → '),
                                    style: TextStyle(color: _textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],

                            if (t.description != null && t.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                t.description!,
                                style: TextStyle(color: _textSecondary, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _statCell(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _textSecondary, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
              child: const Icon(Icons.error_outline_rounded, color: Color(0xFFFF0055), size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              _error ?? 'Something went wrong.',
              style: const TextStyle(color: Color(0xFFFF0055), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _load,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accent.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ONGOING':
        return const Color(0xFF00FF00);
      case 'OPEN_REGISTRATION':
        return const Color(0xFF00AAFF);
      case 'COMPLETED':
        return const Color(0xFF8B95A5);
      case 'CANCELLED':
        return const Color(0xFFFF0055);
      case 'DRAFT':
      default:
        return const Color(0xFFFFAA00);
    }
  }

  /// Format large numbers: 10000 → 10K
  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    return '$n';
  }
}
