import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_recommendations_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_player_detail_screen.dart';

class ScouterRecommendationsTab extends StatefulWidget {
  final String scouterId;

  const ScouterRecommendationsTab({super.key, required this.scouterId});

  @override
  State<ScouterRecommendationsTab> createState() =>
      _ScouterRecommendationsTabState();
}

class _ScouterRecommendationsTabState extends State<ScouterRecommendationsTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Recommendations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ScouterRecommendationsViewModel>(
        builder: (context, vm, _) {
          final q = _searchCtrl.text.trim().toLowerCase();
          final filtered = q.isEmpty
              ? vm.recommendations
              : vm.recommendations
                  .where((r) =>
                      r.playerNickname.toLowerCase().contains(q) ||
                      r.orgName.toLowerCase().contains(q))
                  .toList();

          return RefreshIndicator(
            color: const Color(0xFFAA44FF),
            backgroundColor: const Color(0xFF0F1221),
            onRefresh: vm.loadRecommendations,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Players you\'ve recommended to orgs',
                          style: TextStyle(
                            color: Color(0xFF7A86AC),
                            fontSize: 13,
                          ),
                        ),
                        if (vm.recommendations.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search by player or org…',
                              hintStyle: const TextStyle(
                                color: Color(0xFF4A5568),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF4A5568),
                                size: 20,
                              ),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchCtrl.clear();
                                        setState(() {});
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        color: Color(0xFF4A5568),
                                        size: 18,
                                      ),
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFF0F1221),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFF1A1F36)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFF1A1F36)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFAA44FF),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                ),
                if (vm.isLoading && vm.recommendations.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Color(0xFFAA44FF)),
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState(q.isNotEmpty))
                else ...[
                  // Stats summary strip
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Row(
                        children: [
                          _statChip('Total', vm.recommendations.length.toString(), const Color(0xFFAA44FF)),
                          const SizedBox(width: 8),
                          _statChip('Accepted', vm.recommendations.where((r) => r.status == 'ACCEPTED').length.toString(), const Color(0xFF00FF00)),
                          const SizedBox(width: 8),
                          _statChip('Pending', vm.recommendations.where((r) => r.status == 'PENDING').length.toString(), const Color(0xFFFFAA00)),
                          const SizedBox(width: 8),
                          _statChip('Rejected', vm.recommendations.where((r) => r.status == 'REJECTED').length.toString(), const Color(0xFFFF0055)),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildCard(context, filtered[index]),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Stat chip ────────────────────────────────────────────────────────────

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ─── Recommendation card ──────────────────────────────────────────────────

  Widget _buildCard(BuildContext context, dynamic r) {
    final statusColor = r.status == 'ACCEPTED'
        ? const Color(0xFF00FF00)
        : r.status == 'REJECTED'
            ? const Color(0xFFFF0055)
            : const Color(0xFFFFAA00);
    final levelColor = r.recommendationLevel == 'MUST_SIGN'
        ? const Color(0xFFFF0055)
        : r.recommendationLevel == 'STRONGLY_RECOMMEND'
            ? const Color(0xFFFFAA00)
            : const Color(0xFF00AAFF);
    final levelLabel = (r.recommendationLevel as String).replaceAll('_', ' ');
    final playerName = (r.playerNickname as String).isNotEmpty ? r.playerNickname as String : 'Unknown Player';
    final orgName = (r.orgName as String).isNotEmpty ? r.orgName as String : null;
    final playerInitial = playerName[0].toUpperCase();
    final message = r.raw['message']?.toString();
    final rawDate = r.raw['createdAt']?.toString();
    String? dateLabel;
    if (rawDate != null) {
      try {
        final d = DateTime.parse(rawDate);
        dateLabel = '${d.day}/${d.month}/${d.year}';
      } catch (_) {}
    }
    final pid = r.playerIdStr as String;

    return GestureDetector(
      onTap: () {
        if (pid.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ScouterPlayerDetailScreen(
              playerUserId: pid,
              scouterId: widget.scouterId,
            ),
          ));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1221),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A1F36)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colored left border by level
                Container(width: 4, color: levelColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: avatar + name + status
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Player avatar
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: levelColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(playerInitial,
                                    style: TextStyle(color: levelColor, fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(playerName,
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis),
                                  if (orgName != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.arrow_forward, color: Color(0xFF4A5568), size: 11),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(orgName,
                                              style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(r.status as String,
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Badges row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: levelColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(levelLabel,
                                  style: TextStyle(color: levelColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            if (dateLabel != null)
                              Text(dateLabel, style: const TextStyle(color: Color(0xFF4A5568), fontSize: 11)),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_ios, color: Color(0xFF4A5568), size: 11),
                          ],
                        ),
                        // Message preview
                        if (message != null && message.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.format_quote, color: Color(0xFF4A5568), size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(message,
                                      style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12, height: 1.3),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearch) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gradient icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFAA44FF).withValues(alpha: 0.25),
                  const Color(0xFF7B2FBE).withValues(alpha: 0.12),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFAA44FF).withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.thumb_up_rounded,
              color: Color(0xFFAA44FF),
              size: 52,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            isSearch ? 'No results match your search' : 'No recommendations yet',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            isSearch
                ? 'Try a different player or org name.'
                : 'Open a player profile and tap "Recommend"\nto suggest them to an organization.',
            style: const TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
