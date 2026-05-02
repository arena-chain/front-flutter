import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/feature_leagues/leagues_api.dart';
import 'package:arena_chain_flutter/core/models/feature_leagues/leagues_models.dart';
import 'package:arena_chain_flutter/screens/leagues/player_leagues_screen.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_ui_tokens.dart';

// ── Design tokens (aligned with scouter shell: watchlist / matches) ────────
const _bgTop = ScouterUiTokens.scaffoldBg;
const _bgBottom = ScouterUiTokens.scaffoldBg;
const _surface = ScouterUiTokens.card;
const _card = ScouterUiTokens.card;
const _cardElevated = ScouterUiTokens.card;
const _border = ScouterUiTokens.cardBorder;
const _accent = ScouterUiTokens.accentGreen;
const _textSecondary = ScouterUiTokens.textSecondaryAlt;

class ViewAllLeaguesScreen extends StatefulWidget {
  final String? scouterId;
  /// When provided (e.g. when used as tab), called instead of Navigator.pop.
  final VoidCallback? onBack;

  const ViewAllLeaguesScreen({super.key, this.scouterId, this.onBack});

  @override
  State<ViewAllLeaguesScreen> createState() => _ViewAllLeaguesScreenState();
}

class _ViewAllLeaguesScreenState extends State<ViewAllLeaguesScreen>
    with AutomaticKeepAliveClientMixin {
  final _api = LeaguesApi();
  List<LeagueItem> _all = [];
  bool _loading = true;
  String? _error;
  bool _inFlight = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_inFlight) return;
    _inFlight = true;
    final blockUi = !refresh && _all.isEmpty;
    if (blockUi) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (refresh && mounted) {
      setState(() => _error = null);
    }
    try {
      final leagues = await _api.getLeagues();
      if (mounted) setState(() => _all = leagues);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      _inFlight = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              child: (_loading && _all.isEmpty)
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
                : _error != null && _all.isEmpty
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
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // padding for floating nav
        itemCount: _all.length,
        itemBuilder: (ctx, i) => _leagueCard(ctx, _all[i]),
      ),
    );
  }

  bool _isActiveLeague(LeagueItem l) {
    final s = l.status.toUpperCase();
    return s == 'ONGOING' || s == 'ACTIVE' || s == 'OPEN_REGISTRATION';
  }

  String? _organiserNickname(LeagueItem l) {
    final raw = l.raw['organiserId'];
    if (raw is Map) {
      return (raw['nickname'] ?? raw['username'] ?? raw['displayName'])
          ?.toString();
    }
    return l.raw['organiserNickname']?.toString();
  }

  String _regionLabel(LeagueItem l) {
    final region = l.regionValue.isNotEmpty
        ? l.regionValue
        : (l.raw['regionId']?.toString() ?? '');
    return region.isEmpty ? 'Global' : region.toUpperCase();
  }

  String? _description(LeagueItem l) => l.raw['description']?.toString();

  SeasonItem _defaultSeason(List<SeasonItem> seasons) {
    for (final s in seasons) {
      if (s.status.toUpperCase() == 'ONGOING') return s;
    }
    return seasons.first;
  }

  Future<void> _openLeagueDetail(BuildContext context, LeagueItem league) async {
    try {
      final seasons = await _api.getSeasons(league.id);
      if (!context.mounted) return;
      if (seasons.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No seasons found for "${league.name}".'),
            backgroundColor: _surface,
          ),
        );
        return;
      }
      SeasonItem season;
      if (seasons.length == 1) {
        season = _defaultSeason(seasons);
      } else {
        final picked = await showModalBottomSheet<SeasonItem>(
          context: context,
          backgroundColor: _cardElevated,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          builder: (ctx) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _textSecondary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      league.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a season',
                      style: TextStyle(color: _textSecondary.withValues(alpha: 0.9), fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(ctx).height * 0.5,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: seasons.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: _border),
                        itemBuilder: (ctx, i) {
                          final s = seasons[i];
                          final st = s.status.toUpperCase();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              s.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              st,
                              style: TextStyle(color: _textSecondary.withValues(alpha: 0.85), fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: _textSecondary),
                            onTap: () => Navigator.pop(ctx, s),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        if (picked == null || !context.mounted) return;
        season = picked;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => LeagueSeasonScreen(league: league, season: season),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFFF0055).withValues(alpha: 0.9),
        ),
      );
    }
  }

  Widget _leagueCard(BuildContext context, LeagueItem l) {
    final levelColor = _levelColor(l.level);
    final isActive = _isActiveLeague(l);
    final name = l.name;
    final organiser = _organiserNickname(l);
    final region = _regionLabel(l);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openLeagueDetail(context, l),
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
                                      color: ScouterUiTokens.accentBlue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: ScouterUiTokens.accentBlue.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.public,
                                            color: ScouterUiTokens.accentBlue, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          region,
                                          style: const TextStyle(
                                            color: ScouterUiTokens.accentBlue,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_description(l) case final String desc when desc.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  desc,
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
