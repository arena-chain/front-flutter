import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_watchlist_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_player_detail_screen.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_ui_tokens.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

class ScouterWatchlistTab extends StatelessWidget {
  final String scouterId;

  const ScouterWatchlistTab({super.key, this.scouterId = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScouterUiTokens.scaffoldBg,
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
                child: vm.error != null &&
                        vm.allProspects.isEmpty &&
                        !vm.isLoading
                    ? _errorState(context, vm)
                    : (vm.isLoading && vm.allProspects.isEmpty)
                        ? _loadingSkeleton()
                        : _buildList(context, vm, scouterId),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _loadingSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: const LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: ScouterUiTokens.cardBorder,
              color: ScouterUiTokens.accentGreen,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: List.generate(
              5,
              (i) => Padding(
                padding: EdgeInsets.only(bottom: i == 4 ? 0 : 10),
                child: Container(
                  height: 78,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: ScouterUiTokens.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ScouterUiTokens.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: ScouterUiTokens.chipInactiveBorder
                              .withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              width: 160,
                              decoration: BoxDecoration(
                                color: ScouterUiTokens.chipInactiveBorder
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 8,
                              width: 100,
                              decoration: BoxDecoration(
                                color: ScouterUiTokens.chipInactiveBorder
                                    .withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(4),
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
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback(bool hasNickname, String initial) {
    return SizedBox.expand(
      child: ColoredBox(
        color: ScouterUiTokens.card,
        child: Center(
          child: hasNickname
              ? Text(
                  initial,
                  style: const TextStyle(
                    color: ScouterUiTokens.accentGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Icon(
                  Icons.person_outline_rounded,
                  color: ScouterUiTokens.accentGreen,
                  size: 28,
                ),
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, ScouterWatchlistViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: ScouterUiTokens.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              vm.error ?? 'Could not load watchlist.',
              style: const TextStyle(
                color: ScouterUiTokens.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => vm.loadWatchlist(),
              style: OutlinedButton.styleFrom(
                foregroundColor: ScouterUiTokens.accentGreen,
                side: BorderSide(
                  color: ScouterUiTokens.accentGreen.withValues(alpha: 0.45),
                ),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
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
            style: TextStyle(color: ScouterUiTokens.textSecondary, fontSize: 13),
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                color: isActive ? color : ScouterUiTokens.chipInactiveBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? color : ScouterUiTokens.chipInactiveBorder,
                ),
              ),
              child: Text(
                lvl,
                style: TextStyle(
                  color: isActive
                      ? Colors.black
                      : ScouterUiTokens.textSecondary,
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
      color: ScouterUiTokens.accentGreen,
      backgroundColor: ScouterUiTokens.card,
      onRefresh: () => vm.loadWatchlist(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _prospectCard(context, items[index], vm, scouterId),
      ),
    );
  }

  Widget _prospectCard(BuildContext context, ProspectStatus p,
      ScouterWatchlistViewModel vm, String scouterId) {
    final displayLevel = p.prospectLevel == 'ELITE_PROSPECT'
        ? 'ELITE'
        : p.prospectLevel;
    final nick = p.playerNickname;
    final hasNickname =
        nick != null && nick.isNotEmpty && nick != 'Player';
    final pathId = _watchlistDetailPathId(p);
    final String displayName;
    if (hasNickname) {
      displayName = nick;
    } else {
      displayName =
          pathId.length > 10 ? '${pathId.substring(0, 10)}…' : pathId;
    }
    final initial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final emailLine = p.displayEmail;
    final avatarUrl = p.displayAvatarUrl;
    final elo = p.displayElo;
    final rank = p.displayRankLabel;
    final country = p.displayCountryLabel;
    final pri = (p.priority ?? '—').toUpperCase();
    final g = ScouterUiTokens.accentGreen;

    void openProfile() {
      if (pathId.isEmpty) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScouterPlayerDetailScreen(
            playerUserId: pathId,
            scouterId: scouterId,
            initialPlayer: _watchlistInitialPlayer(p),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _showLevelMenu(context, p, vm),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        decoration: BoxDecoration(
          color: ScouterUiTokens.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ScouterUiTokens.cardBorder),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(color: g, width: 2),
                    color: g.withValues(alpha: 0.08),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: avatarUrl != null &&
                              (avatarUrl.startsWith('http://') ||
                                  avatarUrl.startsWith('https://'))
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              width: 52,
                              height: 52,
                              errorBuilder: (_, _, _) => _avatarFallback(
                                  hasNickname, initial),
                            )
                          : _avatarFallback(hasNickname, initial),
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
                      displayName.isNotEmpty ? displayName : 'Unknown player',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (emailLine != null || !hasNickname) ...[
                      const SizedBox(height: 3),
                      Text(
                        emailLine ??
                            'ID: ${pathId.length > 18 ? '${pathId.substring(0, 18)}…' : pathId}',
                        style: TextStyle(
                          color: emailLine != null
                              ? ScouterUiTokens.textSecondary
                              : ScouterUiTokens.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events_rounded,
                                color: g, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$elo Elo',
                              style: TextStyle(
                                color: g,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Rank: $rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.place_outlined,
                                color: ScouterUiTokens.textSecondary,
                                size: 14),
                            const SizedBox(width: 2),
                            Text(
                              country,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$displayLevel · $pri',
                      style: TextStyle(
                        color: g,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 96,
                    child: FilledButton.icon(
                      onPressed: openProfile,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Profile'),
                      style: FilledButton.styleFrom(
                        backgroundColor: g,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 96,
                    child: OutlinedButton.icon(
                      onPressed: openProfile,
                      icon: Icon(Icons.description_outlined,
                          size: 15, color: Colors.white.withValues(alpha: 0.85)),
                      label: const Text('Report'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.9),
                        side: BorderSide(
                          color: ScouterUiTokens.chipInactiveBorder,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _confirmRemove(context, p, vm),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 40,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFF0055)
                                .withValues(alpha: 0.65),
                          ),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFFF0055), size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, ProspectStatus p, ScouterWatchlistViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ScouterUiTokens.card,
        title: const Text('Remove from watchlist?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'This player will be removed from your tracking list.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: Color(0xFFFF0055))),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await vm.removeFromWatchlist(p.playerId);
    }
  }

  // ─── Level change menu ────────────────────────────────────────────────────

  void _showLevelMenu(BuildContext context, ProspectStatus p,
      ScouterWatchlistViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ScouterUiTokens.card,
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
                    color: ScouterUiTokens.chipInactiveBorder,
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
              const Divider(color: ScouterUiTokens.cardBorder),
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
              color: ScouterUiTokens.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            'No players in $level.',
            style: const TextStyle(
                color: ScouterUiTokens.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set a prospect level in a player\'s\ndetail screen to track them here.',
            style: TextStyle(color: ScouterUiTokens.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Color _levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'WATCHLIST':
        return ScouterUiTokens.accentGreen;
      case 'PROSPECT':
      case 'ELITE_PROSPECT':
      case 'ELITE':
        return const Color(0xFFFFAA00);
      case 'SIGNED':
        return ScouterUiTokens.accentGreen;
      default:
        return ScouterUiTokens.textSecondary;
    }
  }
}

/// Profile / player document id for `/api/scouter/players/:id`.
String _watchlistDetailPathId(ProspectStatus p) {
  final m = p.raw['playerId'];
  if (m is Map) {
    final id = (m['_id'] ?? m['id'] ?? '').toString();
    if (id.isNotEmpty) return id;
  }
  return p.playerId.isNotEmpty ? p.playerId : p.id;
}

PlayerDetail _watchlistInitialPlayer(ProspectStatus p) {
  void mergeEnriched(Map<String, dynamic> j) {
    final ep = p.raw['_enrichedProfile'];
    if (ep is! Map) return;
    final snap = Map<String, dynamic>.from(Map<String, dynamic>.from(ep));
    for (final key in ['email', 'avatar', 'elo', 'country', 'rank', 'tier']) {
      if (snap[key] != null) j[key] = snap[key];
    }
  }

  final m = p.raw['playerId'];
  if (m is Map) {
    final j = Map<String, dynamic>.from(m);
    if (p.playerNickname?.isNotEmpty == true) {
      j['nickname'] = p.playerNickname;
    }
    mergeEnriched(j);
    return PlayerDetail.fromJson(j);
  }
  final id = _watchlistDetailPathId(p);
  final j = <String, dynamic>{
    '_id': id,
    'userId': id,
    'nickname': p.playerNickname ?? 'Player',
  };
  mergeEnriched(j);
  return PlayerDetail.fromJson(j);
}
