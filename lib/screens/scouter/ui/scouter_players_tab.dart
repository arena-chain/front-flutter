import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_players_view_model.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_player_detail_screen.dart';

class ScouterPlayersTab extends StatefulWidget {
  final String scouterId;

  const ScouterPlayersTab({super.key, required this.scouterId});

  @override
  State<ScouterPlayersTab> createState() => _ScouterPlayersTabState();
}

class _ScouterPlayersTabState extends State<ScouterPlayersTab> {
  final _searchCtrl = TextEditingController();
  bool _cardView = false;  // false = leaderboard, true = cards

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<LeaderboardEntry> _applySearch(List<LeaderboardEntry> entries) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return entries;
    return entries
        .where((e) =>
            (e.user?.nickname ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Explore Players',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<ScouterPlayersViewModel>(
            builder: (context, vm, _) {
              return IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: vm.showFilterResults ? const Color(0xFF00FF00) : Colors.white,
                ),
                onPressed: () => _showFilterSheet(context, vm),
              );
            },
          ),
        ],
      ),
      body: Consumer<ScouterPlayersViewModel>(
        builder: (context, vm, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(vm),
              _buildGamePicker(vm),
              _buildViewToggle(),
              Expanded(
                child: vm.showFilterResults
                    ? _buildFilterResults(context, vm)
                    : _buildLeaderboard(context, vm),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar(ScouterPlayersViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by nickname…',
          hintStyle:
              const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
          prefixIcon: const Icon(Icons.search,
              color: Color(0xFF4A5568), size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                  child: const Icon(Icons.close,
                      color: Color(0xFF4A5568), size: 18),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF0F1221),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1A1F36)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1A1F36)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF00FF00), width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─── Game Picker ──────────────────────────────────────────────────────────

  Widget _buildGamePicker(ScouterPlayersViewModel vm) {
    if (vm.games.isEmpty) {
      return const SizedBox(
        height: 42,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00FF00),
            strokeWidth: 2,
          ),
        ),
      );
    }
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: vm.games.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final game = vm.games[index];
          final isSelected = vm.selectedGameId == game.id;
          return GestureDetector(
            onTap: () => vm.selectGame(game.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00FF00)
                    : const Color(0xFF0F1221),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00FF00)
                      : const Color(0xFF2A2F46),
                ),
              ),
              child: Text(
                game.title,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF0A0E1A)
                      : const Color(0xFF7A86AC),
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── View Toggle ──────────────────────────────────────────────────────────

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          _toggleBtn('🏆  Leaderboard', !_cardView, () {
            setState(() => _cardView = false);
          }),
          const SizedBox(width: 10),
          _toggleBtn('🃏  Cards', _cardView, () {
            setState(() => _cardView = true);
          }),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF00FF00).withOpacity(0.12)
              : const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? const Color(0xFF00FF00)
                : const Color(0xFF2A2F46),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? const Color(0xFF00FF00)
                : const Color(0xFF7A86AC),
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ─── Leaderboard ──────────────────────────────────────────────────────────

  Widget _buildLeaderboard(
      BuildContext context, ScouterPlayersViewModel vm) {
    if (vm.isLoadingLeaderboard) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF00)),
      );
    }
    if (vm.leaderboardError != null) {
      return Center(
        child: Text(
          vm.leaderboardError!,
          style: const TextStyle(color: Color(0xFFFF0055)),
        ),
      );
    }
    final entries = _applySearch(vm.leaderboard);
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No players found.',
          style: TextStyle(color: Color(0xFF7A86AC)),
        ),
      );
    }
    if (_cardView) {
      return _buildCardGrid(context, entries);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: entries.length,
      itemBuilder: (context, index) =>
          _leaderboardRow(context, entries[index], index + 1),
    );
  }

  // ─── Card Grid View ───────────────────────────────────────────────────────

  Widget _buildCardGrid(BuildContext context, List<LeaderboardEntry> entries) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) =>
          _playerCard(context, entries[index]),
    );
  }

  Widget _playerCard(BuildContext context, LeaderboardEntry entry) {
    final tierColor = _tierColor(entry.tier);
    final userId = entry.user?.id ?? '';
    return GestureDetector(
      onTap: () {
        if (userId.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScouterPlayerDetailScreen(
              playerUserId: userId,
              scouterId: widget.scouterId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tierColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      entry.user?.nickname.isNotEmpty == true
                          ? entry.user!.nickname[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: tierColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Watchlist heart (decorative – tap opens detail)
                Icon(Icons.favorite_border,
                    color: const Color(0xFF4A5568), size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              entry.user?.nickname ?? '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (entry.team != null)
              Text(
                entry.team!.name,
                style: const TextStyle(
                    color: Color(0xFF7A86AC), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: tierColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.tier,
                      style: TextStyle(
                        color: tierColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.elo}',
                  style: const TextStyle(
                    color: Color(0xFFBBC4D4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Leaderboard Row ──────────────────────────────────────────────────────

  Widget _leaderboardRow(
      BuildContext context, LeaderboardEntry entry, int rank) {
    final tierColor = _tierColor(entry.tier);
    return GestureDetector(
      onTap: () {
        final userId = entry.user?.id ?? '';
        if (userId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScouterPlayerDetailScreen(
                playerUserId: userId,
                scouterId: widget.scouterId,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: rank <= 3
                ? const Color(0xFF00FF00).withOpacity(0.3)
                : const Color(0xFF1A1F36),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rank == 1
                      ? const Color(0xFFFFD700)
                      : rank == 2
                          ? const Color(0xFFC0C0C0)
                          : rank == 3
                              ? const Color(0xFFCD7F32)
                              : const Color(0xFF7A86AC),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  entry.user?.nickname.isNotEmpty == true
                      ? entry.user!.nickname[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: tierColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.user?.nickname ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.team != null)
                    Text(
                      entry.team!.name,
                      style: const TextStyle(
                          color: Color(0xFF7A86AC), fontSize: 12),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.elo} ELO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.tier,
                    style: TextStyle(
                        color: tierColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filter Results ───────────────────────────────────────────────────────

  Widget _buildFilterResults(
      BuildContext context, ScouterPlayersViewModel vm) {
    if (vm.isFiltering) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF00)),
      );
    }
    if (vm.filterError != null) {
      return Center(
        child: Text(
          vm.filterError!,
          style: const TextStyle(color: Color(0xFFFF0055)),
        ),
      );
    }
    if (vm.filterResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off,
                color: Color(0xFF4A5568), size: 48),
            const SizedBox(height: 12),
            const Text(
              'No players match your filters.',
              style: TextStyle(color: Color(0xFF7A86AC)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: vm.resetFilter,
              child: const Text('Clear Filters',
                  style: TextStyle(color: Color(0xFF00FF00))),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Text(
                '${vm.filterResults.length} results',
                style: const TextStyle(
                    color: Color(0xFF7A86AC), fontSize: 13),
              ),
              const Spacer(),
              TextButton(
                onPressed: vm.resetFilter,
                child: const Text('Clear',
                    style: TextStyle(
                        color: Color(0xFFFF0055), fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            itemCount: vm.filterResults.length,
            itemBuilder: (context, index) =>
                _filteredPlayerRow(context, vm.filterResults[index]),
          ),
        ),
      ],
    );
  }

  Widget _filteredPlayerRow(BuildContext context, PlayerDetail p) {
    return GestureDetector(
      onTap: () {
        final userId = p.userId?.id ?? '';
        if (userId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScouterPlayerDetailScreen(
                playerUserId: userId,
                scouterId: widget.scouterId,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1A1F36)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF00).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  p.userId?.nickname.isNotEmpty == true
                      ? p.userId!.nickname[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.userId?.nickname ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    p.userId?.country ?? p.region ?? '',
                    style: const TextStyle(
                        color: Color(0xFF7A86AC), fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${p.elo} ELO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (p.isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF00).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                          color: Color(0xFF00FF00),
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context, ScouterPlayersViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1221),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _FilterSheet(vm: vm),
    );
  }

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
        return const Color(0xFF7A86AC);
    }
  }
}

// ─── Filter Sheet (unchanged logic) ──────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final ScouterPlayersViewModel vm;

  const _FilterSheet({required this.vm});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _tier;
  late String? _country;
  late bool? _hasTeam;
  late String? _prospectLevel;
  late String? _priority;
  final _countryCtrl = TextEditingController();

  static const _tiers = [
    'IRON', 'BRONZE', 'SILVER', 'GOLD', 'PLATINUM',
    'DIAMOND', 'MASTER', 'GRANDMASTER', 'CHALLENGER', 'IMMORTAL', 'RADIANT'
  ];
  static const _prospectLevels = [
    'UNKNOWN', 'WATCHLIST', 'PROSPECT', 'ELITE_PROSPECT', 'SIGNED'
  ];
  static const _priorities = ['LOW', 'MEDIUM', 'HIGH'];

  @override
  void initState() {
    super.initState();
    final vm = widget.vm;
    _tier = vm.filterTier;
    _country = vm.filterCountry;
    _hasTeam = vm.filterHasTeam;
    _prospectLevel = vm.filterProspectLevel;
    _priority = vm.filterPriority;
    _countryCtrl.text = vm.filterCountry ?? '';
  }

  @override
  void dispose() {
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2F46),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filter Players',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _label('Tier'),
          DropdownButtonFormField<String>(
            value: _tier,
            dropdownColor: const Color(0xFF0F1221),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Any tier'),
            items: _tiers
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _tier = v),
          ),
          const SizedBox(height: 14),
          _label('Country'),
          TextFormField(
            controller: _countryCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('e.g. Tunisia'),
            onChanged: (v) =>
                _country = v.trim().isEmpty ? null : v.trim(),
          ),
          const SizedBox(height: 14),
          _label('Team Status'),
          Row(
            children: [
              _toggleChip('Any', null, _hasTeam),
              const SizedBox(width: 8),
              _toggleChip('Has Team', true, _hasTeam),
              const SizedBox(width: 8),
              _toggleChip('Free Agent', false, _hasTeam),
            ],
          ),
          const SizedBox(height: 14),
          _label('Prospect Level'),
          DropdownButtonFormField<String>(
            value: _prospectLevel,
            dropdownColor: const Color(0xFF0F1221),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Any level'),
            items: _prospectLevels
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (v) => setState(() => _prospectLevel = v),
          ),
          const SizedBox(height: 14),
          _label('Priority'),
          Row(
            children: _priorities
                .map((p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _toggleChip(p, p, _priority),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.vm.resetFilter();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2A2F46)),
                    foregroundColor: const Color(0xFF7A86AC),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.vm.filterTier = _tier;
                    widget.vm.filterCountry = _country;
                    widget.vm.filterHasTeam = _hasTeam;
                    widget.vm.filterProspectLevel = _prospectLevel;
                    widget.vm.filterPriority = _priority;
                    widget.vm.applyFilter();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF00),
                    foregroundColor: const Color(0xFF0A0E1A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF4A5568)),
        filled: true,
        fillColor: const Color(0xFF1A1F36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00FF00)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Widget _toggleChip<T>(String label, T value, T current) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (value == null) {
            _hasTeam = null;
            _priority = null;
          } else if (value is bool?) {
            _hasTeam = isSelected ? null : value as bool?;
          } else {
            _priority = isSelected ? null : value as String?;
          }
        });
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00FF00).withOpacity(0.15)
              : const Color(0xFF1A1F36),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00FF00)
                : const Color(0xFF2A2F46),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF00FF00)
                : const Color(0xFF7A86AC),
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
