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

class ViewAllLeaguesScreen extends StatefulWidget {
  final String? scouterId;
  /// When provided (e.g. when used as tab), called instead of Navigator.pop.
  final VoidCallback? onBack;

  const ViewAllLeaguesScreen({super.key, this.scouterId, this.onBack});

  @override
  State<ViewAllLeaguesScreen> createState() => _ViewAllLeaguesScreenState();
}

class _ViewAllLeaguesScreenState extends State<ViewAllLeaguesScreen> {
  final _api = ViewAllApi();
  List<LeagueModel> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      setState(() { _loading = true; _error = null; });
      final leagues = await _api.getAllLeagues();
      if (mounted) setState(() => _all = leagues);
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
                          'Loading leagues…',
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
      child: SafeArea(bottom: false, child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                  'All Leagues',
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
                'Leagues',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ],
      )),
    );
  }

  Widget _buildList() {
    if (_all.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.emoji_events_outlined, color: _textSecondary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'No leagues found',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
        itemCount: _all.length,
        itemBuilder: (ctx, i) => _leagueCard(ctx, _all[i]),
      ),
    );
  }

  Widget _leagueCard(BuildContext context, LeagueModel l) {
    final levelColor = _levelColor(l.level);
    final isActive = l.isActive;
    final name = l.name;
    final organiser = l.organiserNickname;
    final region = l.regionId.isEmpty ? 'Global' : l.regionId.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Optional: navigate to league detail
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: _cardElevated.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? _accent.withValues(alpha: 0.3) : _border,
              ),
              boxShadow: [
                if (isActive)
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
                   if (isActive)
                    Positioned(
                      left: 0, top: 0, bottom: 0,
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // League Level Icon
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                levelColor.withValues(alpha: 0.2),
                                levelColor.withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: levelColor.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Icon(Icons.shield_rounded, color: levelColor, size: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // League Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (organiser != null && organiser.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'by $organiser',
                                  style: TextStyle(color: _textSecondary, fontSize: 13),
                                ),
                              ],
                              const SizedBox(height: 12),
                              // Badges row
                              Row(
                                children: [
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? _accent.withValues(alpha: 0.12) : _textSecondary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isActive ? _accent.withValues(alpha: 0.3) : _textSecondary.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isActive) ...[
                                          Container(
                                            width: 6, height: 6,
                                            decoration: const BoxDecoration(
                                              color: _accent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          isActive ? 'ACTIVE' : 'INACTIVE',
                                          style: TextStyle(
                                            color: isActive ? _accent : _textSecondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Region Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00AAFF).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF00AAFF).withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.public, color: Color(0xFF00AAFF), size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          region,
                                          style: const TextStyle(
                                            color: Color(0xFF00AAFF),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (l.description != null && l.description!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  l.description!,
                                  style: TextStyle(color: _textSecondary, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ]
                            ],
                          ),
                        ),
                        // Right Arrow
                        Center(
                          child: Icon(Icons.chevron_right_rounded, color: _textSecondary, size: 24),
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

  Color _levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'INTERNATIONAL':
        return const Color(0xFFFF4444);
      case 'CONTINENTAL':
        return const Color(0xFFFF6644);
      case 'NATIONAL':
        return const Color(0xFF4488FF);
      case 'REGIONAL':
      default:
        return const Color(0xFF44DDAA);
    }
  }
}
