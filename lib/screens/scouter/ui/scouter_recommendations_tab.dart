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
                        if (!vm.recommendations.isEmpty) ...[
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
                if (vm.isLoading)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: Color(0xFFAA44FF),
                        ),
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(q.isNotEmpty),
                  )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final r = filtered[index];
                        final statusColor = r.status == 'ACCEPTED'
                            ? const Color(0xFF00FF00)
                            : r.status == 'REJECTED'
                                ? const Color(0xFFFF0055)
                                : const Color(0xFFFFAA00);
                        final levelColor = r.recommendationLevel ==
                                'MUST_SIGN'
                            ? const Color(0xFFFF0055)
                            : r.recommendationLevel ==
                                    'STRONGLY_RECOMMEND'
                                ? const Color(0xFFFFAA00)
                                : const Color(0xFF00AAFF);

                        return GestureDetector(
                          onTap: () {
                            final pid = r.playerIdStr;
                            if (pid.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ScouterPlayerDetailScreen(
                                    playerUserId: pid,
                                    scouterId: widget.scouterId,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1221),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF1A1F36),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Org initial circle
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFFAA44FF).withOpacity(0.25),
                                        const Color(0xFF7B2FBE).withOpacity(0.12),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      r.orgName.isNotEmpty
                                          ? r.orgName[0].toUpperCase()
                                          : 'O',
                                      style: const TextStyle(
                                        color: Color(0xFFAA44FF),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.playerNickname,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        r.orgName,
                                        style: const TextStyle(
                                            color: Color(0xFF7A86AC),
                                            fontSize: 12),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: levelColor
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      6),
                                            ),
                                            child: Text(
                                              r.recommendationLevel
                                                  .replaceAll('_', ' '),
                                              style: TextStyle(
                                                color: levelColor,
                                                fontSize: 10,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    r.status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color(0xFF4A5568),
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
                  const Color(0xFFAA44FF).withOpacity(0.25),
                  const Color(0xFF7B2FBE).withOpacity(0.12),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFAA44FF).withOpacity(0.15),
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
