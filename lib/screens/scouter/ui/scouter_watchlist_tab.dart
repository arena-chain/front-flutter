import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_watchlist_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_player_detail_screen.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

class ScouterWatchlistTab extends StatelessWidget {
  final String scouterId;

  const ScouterWatchlistTab({super.key, this.scouterId = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Watchlist',
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
      ),
      body: Consumer<ScouterWatchlistViewModel>(
        builder: (context, vm, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildLevelTabs(vm),
              Expanded(
                child: vm.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00FF00)))
                    : _buildList(context, vm, scouterId),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Players you\'re tracking',
            style: TextStyle(color: Color(0xFF7A86AC), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Level sub-tabs ───────────────────────────────────────────────────────

  Widget _buildLevelTabs(ScouterWatchlistViewModel vm) {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: ScouterWatchlistViewModel.levels.length,
        itemBuilder: (context, i) {
          final lvl = ScouterWatchlistViewModel.levels[i];
          final isActive = vm.activeLevel == lvl;
          final color = _levelColor(lvl);
          return GestureDetector(
            onTap: () => vm.setLevel(lvl),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? color : const Color(0xFF0F1221),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? color : const Color(0xFF2A2F46),
                ),
              ),
              child: Text(
                lvl,
                style: TextStyle(
                  color: isActive
                      ? Colors.black
                      : const Color(0xFF7A86AC),
                  fontSize: 12,
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Prospect list ────────────────────────────────────────────────────────

  Widget _buildList(BuildContext context, ScouterWatchlistViewModel vm, String scouterId) {
    final items = vm.filtered;
    if (items.isEmpty) {
      return _emptyState(vm.activeLevel);
    }
    return RefreshIndicator(
      color: const Color(0xFF00FF00),
      backgroundColor: const Color(0xFF0F1221),
      onRefresh: vm.loadWatchlist,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _prospectCard(context, items[index], vm, scouterId),
      ),
    );
  }

  Widget _prospectCard(BuildContext context, ProspectStatus p,
      ScouterWatchlistViewModel vm, String scouterId) {
    final levelColor = _levelColor(p.prospectLevel);
    // Display-friendly level
    final displayLevel = p.prospectLevel == 'ELITE_PROSPECT'
        ? 'ELITE'
        : p.prospectLevel;
    final displayName = p.playerNickname != 'Player' ? p.playerNickname : (p.playerId.length > 8 ? '${p.playerId.substring(0, 8)}...' : p.playerId);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (scouterId.isNotEmpty && p.playerId.isNotEmpty) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ScouterPlayerDetailScreen(
                playerUserId: p.playerId,
                scouterId: scouterId,
              ),
            ));
          } else if (p.playerId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Player details unavailable for this entry'),
                backgroundColor: Color(0xFFFFAA00),
              ),
            );
          }
        },
        onLongPress: () => _showLevelMenu(context, p, vm),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1221),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1A1F36)),
          ),
          child: Row(
            children: [
              // Avatar initial
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: levelColor,
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
                      displayName.isNotEmpty ? displayName : 'Unknown Player',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _badge(displayLevel, levelColor),
                        if (p.priority != null) ...[
                          const SizedBox(width: 6),
                          _badge(p.priority!, _priorityColor(p.priority!)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Color(0xFF4A5568), size: 14),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showLevelMenu(context, p, vm),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.more_vert,
                      color: Color(0xFF4A5568), size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Level change menu ────────────────────────────────────────────────────

  void _showLevelMenu(BuildContext context, ProspectStatus p,
      ScouterWatchlistViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1221),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
                'Change Level',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...ScouterWatchlistViewModel.levels.map(
                (lvl) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _levelColor(lvl),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(lvl,
                      style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    vm.changeLevel(p.playerId, lvl);
                  },
                ),
              ),
              const Divider(color: Color(0xFF1A1F36)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline,
                    color: Color(0xFFFF0055), size: 20),
                title: const Text('Remove from watchlist',
                    style: TextStyle(color: Color(0xFFFF0055))),
                onTap: () {
                  Navigator.pop(ctx);
                  vm.removeFromWatchlist(p.playerId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _emptyState(String level) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark_border,
              color: Color(0xFF4A5568), size: 48),
          const SizedBox(height: 12),
          Text(
            'No players in $level.',
            style: const TextStyle(
                color: Color(0xFF7A86AC), fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set a prospect level in a player\'s\ndetail screen to track them here.',
            style: TextStyle(color: Color(0xFF4A5568), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'WATCHLIST':
        return const Color(0xFF00AAFF);
      case 'PROSPECT':
      case 'ELITE_PROSPECT':
      case 'ELITE':
        return const Color(0xFFFFAA00);
      case 'SIGNED':
        return const Color(0xFF00FF00);
      default:
        return const Color(0xFF7A86AC);
    }
  }

  Color _priorityColor(String p) {
    switch (p.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFFF0055);
      case 'MEDIUM':
        return const Color(0xFFFFAA00);
      case 'LOW':
      default:
        return const Color(0xFF7A86AC);
    }
  }
}
