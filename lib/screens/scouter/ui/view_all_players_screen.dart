import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/feature_scouter/players_directory_api.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_player_detail_screen.dart';

// ── Design tokens ──────────────────────────────────────────────
const _bgTop          = Color(0xFF040609);
const _bgBottom       = Color(0xFF0A0D14);
const _surface        = Color(0xFF111625);
const _card           = Color(0xFF111625);
const _cardElevated   = Color(0xFF161C2C);
const _border         = Color(0x0DFFFFFF); // Colors.white.withValues(alpha: 0.05)
const _accent         = Color(0xFF00FF00);
const _muted          = Color(0xFF6B7280);
const _textSecondary  = Color(0xFF8B95A5);

Color _tierColor(String tier) {
  switch (tier.toUpperCase()) {
    case 'RADIANT': case 'GRANDMASTER': return const Color(0xFFFF4444);
    case 'IMMORTAL': case 'CHALLENGER': return const Color(0xFFFF7744);
    case 'MASTER':   return const Color(0xFFAA44FF);
    case 'DIAMOND':  return const Color(0xFF4488FF);
    case 'PLATINUM': return const Color(0xFF44DDAA);
    case 'GOLD':     return const Color(0xFFFFCC00);
    case 'SILVER':   return const Color(0xFFBBBBBB);
    default:         return const Color(0xFF8B95A5);
  }
}

class ViewAllPlayersScreen extends StatefulWidget {
  final String scouterId;
  /// When provided (e.g. when used as tab), called instead of Navigator.pop.
  final VoidCallback? onBack;

  const ViewAllPlayersScreen({super.key, required this.scouterId, this.onBack});

  @override
  State<ViewAllPlayersScreen> createState() => _ViewAllPlayersScreenState();
}

class _ViewAllPlayersScreenState extends State<ViewAllPlayersScreen> {
  final _api = PlayersDirectoryApi();
  final _searchCtrl = TextEditingController();
  List<PlayerDetail> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      setState(() { _loading = true; _error = null; });
      final players = await _api.getPlayers();
      if (mounted) setState(() => _all = players);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PlayerDetail> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((p) => p.nickname.toLowerCase().contains(q)).toList();
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
                          'Loading players…',
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

  // ── Header ─────────────────────────────────────────────────────

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
      child: SafeArea(bottom: false, child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
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
                    width: 40, height: 40,
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
                  'All Players',
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
                'Players',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _searchBar(),
          ),
        ],
      )),
    );
  }

  Widget _searchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: _card.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by nickname…',
              hintStyle: TextStyle(color: _muted, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: _muted, size: 22),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, color: _accent, size: 22),
                      onPressed: () { _searchCtrl.clear(); setState(() {}); },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  // ── Player list ─────────────────────────────────────────────────

  Widget _buildList() {
    final players = _filtered;
    if (players.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.person_search_rounded, color: _textSecondary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'No players found',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search term',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      color: _accent,
      backgroundColor: _surface,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // padding for floating nav
        itemCount: players.length,
        itemBuilder: (ctx, i) => _playerCard(ctx, players[i], i + 1),
      ),
    );
  }

  Widget _playerCard(BuildContext context, PlayerDetail p, int rank) {
    final nickname = p.nickname;
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';
    final tier = p.tier ?? p.rank ?? 'UNRANKED';
    final tColor = _tierColor(tier);
    final isPro = p.isPro;
    final status = p.team?.name ?? (p.country.isNotEmpty && p.country != 'Unknown' ? p.country : 'Free Agent');

    // Rank styling
    final isTopThree = rank <= 3;
    final rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : _textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (isTopThree)
              BoxShadow(
                color: tColor.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (p.id.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScouterPlayerDetailScreen(
                        playerUserId: p.id,
                        scouterId: widget.scouterId,
                        initialPlayer: p,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isTopThree ? tColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Subtle gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isTopThree ? tColor.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Row(children: [
                          // Rank badge
                          SizedBox(
                            width: 36,
                            child: isTopThree
                                ? Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: rankColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: rankColor.withValues(alpha: 0.5), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: rankColor.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                        )
                                      ]
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$rank',
                                        style: TextStyle(
                                          color: rankColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    '#$rank',
                                    style: TextStyle(
                                      color: _textSecondary.withValues(alpha: 0.6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          // Avatar
                          Container(
                            width: 48, height: 48,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [tColor.withValues(alpha: 0.6), tColor.withValues(alpha: 0.1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D1220),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    color: tColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isPro) ...[
                                      Icon(Icons.verified_rounded, color: _accent, size: 14),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: Text(
                                        nickname,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Stats
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.bolt_rounded, color: _accent, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${p.elo ?? 1000}',
                                    style: const TextStyle(
                                      color: _accent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Text(
                                  tier.toUpperCase(),
                                  style: TextStyle(
                                    color: tColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.15),
                            size: 14,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
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
        ]),
      ),
    );
  }
}
