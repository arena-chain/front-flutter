import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_reports_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/report_detail_screen.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';

class ScouterReportsTab extends StatefulWidget {
  final String scouterId;

  const ScouterReportsTab({super.key, required this.scouterId});

  @override
  State<ScouterReportsTab> createState() => _ScouterReportsTabState();
}

class _ScouterReportsTabState extends State<ScouterReportsTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Group reports by Today / This Week / Older
  Map<String, List<ScoutingReport>> _group(List<ScoutingReport> reports) {
    final now = DateTime.now();
    final today = <ScoutingReport>[];
    final week = <ScoutingReport>[];
    final older = <ScoutingReport>[];

    for (final r in reports) {
      final dt = r.createdAt != null ? DateTime.tryParse(r.createdAt!) : null;
      if (dt == null) {
        older.add(r);
      } else if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) {
        today.add(r);
      } else if (now.difference(dt).inDays <= 7) {
        week.add(r);
      } else {
        older.add(r);
      }
    }
    return {
      if (today.isNotEmpty) 'Today': today,
      if (week.isNotEmpty) 'This Week': week,
      if (older.isNotEmpty) 'Older': older,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Reports',
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
      body: Consumer<ScouterReportsViewModel>(
        builder: (context, vm, _) {
          final q = _searchCtrl.text.trim().toLowerCase();
          final filtered = q.isEmpty
              ? vm.reports
              : vm.reports
                  .where((r) =>
                      (r.playerNickname ?? '').toLowerCase().contains(q))
                  .toList();
          final groups = _group(filtered);

          return RefreshIndicator(
            color: const Color(0xFF00FF00),
            backgroundColor: const Color(0xFF0F1221),
            onRefresh: () => vm.loadReports(refresh: true),
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
                          'All your scouting reports',
                          style: TextStyle(
                              color: Color(0xFF7A86AC), fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        // Search bar
                        TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search by player name…',
                            hintStyle: const TextStyle(
                                color: Color(0xFF4A5568), fontSize: 14),
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
                                  color: Color(0xFF00FF00), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),

              // Loading
              if (vm.isLoading && vm.reports.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: Color(0xFF00FF00)),
                    ),
                  ),
                )
              // Empty
              else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(60),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF00)
                                  .withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.assignment_outlined,
                                color: Color(0xFF4A5568), size: 40),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            q.isEmpty
                                ? 'No reports yet'
                                : 'No reports match "$q"',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Go to a player profile and write\na report to see it here.",
                            style: TextStyle(
                                color: Color(0xFF7A86AC), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                // Grouped report list
                else
                  ...groups.entries.map((entry) => _groupSliver(
                      context, entry.key, entry.value, vm)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Group Sliver ──────────────────────────────────────────────────────────

  SliverList _groupSliver(BuildContext context, String title,
      List<ScoutingReport> reports, ScouterReportsViewModel vm) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...reports.map((r) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ReportCard(
                report: r,
                scouterId: widget.scouterId,
                onDelete: () => vm.deleteReport(r.id),
                onReportCreated: vm.loadReports,
              ),
            )),
      ]),
    );
  }
}

// ─── Report Card ──────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final ScoutingReport report;
  final String scouterId;
  final VoidCallback onDelete;
  final VoidCallback? onReportCreated;

  const _ReportCard({
    required this.report,
    required this.scouterId,
    required this.onDelete,
    this.onReportCreated,
  });

  @override
  Widget build(BuildContext context) {
    final rating = report.rating;
    final ratingColor = rating >= 80
        ? const Color(0xFF00FF00)
        : rating >= 60
            ? const Color(0xFFFFAA00)
            : const Color(0xFFFF0055);

    return Dismissible(
      key: Key(report.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF0055).withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline,
            color: Color(0xFFFF0055), size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F1221),
            title: const Text('Delete Report',
                style: TextStyle(color: Colors.white)),
            content: const Text(
              'Are you sure you want to delete this report?',
              style: TextStyle(color: Color(0xFF7A86AC)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF7A86AC))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style: TextStyle(color: Color(0xFFFF0055))),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailScreen(
                report: report,
                scouterId: scouterId,
                onReportCreated: onReportCreated,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1221),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1A1F36)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating ring
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: ratingColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: ratingColor.withOpacity(0.4), width: 2),
                ),
                child: Center(
                  child: Text(
                    '$rating',
                    style: TextStyle(
                      color: ratingColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.playerNickname ?? 'Unknown Player',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (report.recommendedRole != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF00FF00).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          report.recommendedRole!,
                          style: const TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (report.strengths != null &&
                        report.strengths!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          report.strengths!,
                          style: const TextStyle(
                              color: Color(0xFF7A86AC), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (report.createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1F36),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            report.createdAt!.length >= 10
                                ? report.createdAt!.substring(0, 10)
                                : report.createdAt!,
                            style: const TextStyle(
                                color: Color(0xFF4A5568), fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Color(0xFF4A5568), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
