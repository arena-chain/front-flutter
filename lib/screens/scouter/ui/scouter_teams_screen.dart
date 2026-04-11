import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/feature_scouter/players_directory_api.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/directory_models.dart' show TeamItem;

// ── Design tokens ──────────────────────────────────────────────
const _bg      = Color(0xFF040609);
const _surface = Color(0xFF111625);
const _card    = Color(0xFF161C2C);
const _accent  = Color(0xFF00FF00);
const _muted   = Color(0xFF8B95A5);

class ScouterTeamsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ScouterTeamsScreen({super.key, this.onBack});

  @override
  State<ScouterTeamsScreen> createState() => _ScouterTeamsScreenState();
}

class _ScouterTeamsScreenState extends State<ScouterTeamsScreen> {
  final _api = PlayersDirectoryApi();
  final _searchCtrl = TextEditingController();

  List<TeamItem> _teams = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final teams = await _api.getTeams();
      if (mounted) setState(() => _teams = teams);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<TeamItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _teams;
    return _teams.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_bg, Color(0xFF0A0D14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _header(context),
            _searchBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5))
                  : _error != null
                      ? _errorView()
                      : RefreshIndicator(
                          color: _accent,
                          backgroundColor: _surface,
                          onRefresh: _load,
                          child: _filtered.isEmpty
                              ? _emptyView()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                                  itemCount: _filtered.length,
                                  itemBuilder: (_, i) => _teamCard(_filtered[i]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => widget.onBack != null ? widget.onBack!() : Navigator.maybePop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Teams',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_rounded, color: _accent, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${_teams.length}',
                    style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 4),
                  const Text('Teams', style: TextStyle(color: _accent, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search by team name...',
                hintStyle: TextStyle(color: _muted),
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: _muted, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_off_rounded, color: _muted.withValues(alpha: 0.4), size: 48),
          const SizedBox(height: 12),
          const Text('No teams found', style: TextStyle(color: _muted, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.withValues(alpha: 0.6), size: 40),
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: _muted, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withValues(alpha: 0.3)),
              ),
              child: const Text('Retry', style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamCard(TeamItem t) {
    final initial = t.name.isNotEmpty ? t.name[0].toUpperCase() : 'T';
    final hasLogo = t.logo != null && t.logo!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showTeamDetail(context, t),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Row(
                children: [
                  // Team logo / initial
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: _accent.withValues(alpha: 0.3)),
                    ),
                    child: hasLogo
                        ? ClipOval(
                            child: Image.network(t.logo!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(initial, style: const TextStyle(color: _accent, fontSize: 20, fontWeight: FontWeight.w900)),
                                )),
                          )
                        : Center(
                            child: Text(initial, style: const TextStyle(color: _accent, fontSize: 22, fontWeight: FontWeight.w900)),
                          ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.name,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (t.tag.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _card,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Text(t.tag, style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                        if (t.organizationName != null) ...[
                          const SizedBox(height: 3),
                          Text(t.organizationName!, style: const TextStyle(color: _muted, fontSize: 12)),
                        ],
                        if (t.gameTitle != null) ...[
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.sports_esports_outlined, color: _muted, size: 12),
                            const SizedBox(width: 4),
                            Text(t.gameTitle!, style: const TextStyle(color: _muted, fontSize: 11)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Player count
                  if (t.playerCount > 0)
                    Column(
                      children: [
                        Text(
                          '${t.playerCount}',
                          style: const TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const Text('players', style: TextStyle(color: _muted, fontSize: 10)),
                      ],
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTeamDetail(BuildContext context, TeamItem team) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TeamDetailSheet(team: team, api: _api),
    );
  }
}

// ── Team Detail Bottom Sheet ────────────────────────────────────────────────

class _TeamDetailSheet extends StatefulWidget {
  final TeamItem team;
  final PlayersDirectoryApi api;
  const _TeamDetailSheet({required this.team, required this.api});

  @override
  State<_TeamDetailSheet> createState() => _TeamDetailSheetState();
}

class _TeamDetailSheetState extends State<_TeamDetailSheet> {
  bool _loading = false;

  // Extract players embedded in the team document itself
  List<Map<String, dynamic>> get _embeddedPlayers {
    for (final key in const ['players', 'playerIds', 'members', 'roster']) {
      final val = widget.team.raw[key];
      if (val is List && val.isNotEmpty && val.first is Map) {
        return val.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.team;
    final initial = t.name.isNotEmpty ? t.name[0].toUpperCase() : 'T';
    final hasLogo = t.logo != null && t.logo!.isNotEmpty;
    final allPlayers = _embeddedPlayers;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1120),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: _accent.withValues(alpha: 0.3)),
                    ),
                    child: hasLogo
                        ? ClipOval(child: Image.network(t.logo!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(child: Text(initial, style: const TextStyle(color: _accent, fontSize: 24, fontWeight: FontWeight.w900)))))
                        : Center(child: Text(initial, style: const TextStyle(color: _accent, fontSize: 24, fontWeight: FontWeight.w900))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        if (t.organizationName != null)
                          Text(t.organizationName!, style: const TextStyle(color: _muted, fontSize: 13)),
                        if (t.gameTitle != null)
                          Text(t.gameTitle!, style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.white.withValues(alpha: 0.06)),
            // Roster section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  const Text('Roster', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (allPlayers.isNotEmpty)
                    Text('${allPlayers.length} players', style: const TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
              )
            else if (allPlayers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.group_outlined, color: _muted.withValues(alpha: 0.3), size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'No roster data.\nSelect a season to view players.',
                      style: const TextStyle(color: _muted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: allPlayers.length,
                  itemBuilder: (_, i) {
                    final p = allPlayers[i];
                    final nick = (p['nickname'] ?? p['displayName'] ?? p['username'] ?? 'Player').toString();
                    final initial = nick.isNotEmpty ? nick[0].toUpperCase() : 'P';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(child: Text(initial, style: const TextStyle(color: _accent, fontSize: 15, fontWeight: FontWeight.w700))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(nick, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
                          if (p['country'] != null)
                            Text(p['country'].toString(), style: const TextStyle(color: _muted, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
