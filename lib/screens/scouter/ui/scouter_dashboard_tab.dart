import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_home_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_player_detail_screen.dart';

class ScouterDashboardTab extends StatelessWidget {
  final String scouterId;
  final Function(int) onNavTap;

  const ScouterDashboardTab({
    super.key,
    required this.scouterId,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ScouterHomeViewModel>(
      builder: (context, vm, _) {
        final auth = context.read<AuthViewModel>();
        final nickname = auth.currentUser?.nickname ?? 'Scout';
        final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'S';

        return RefreshIndicator(
          color: const Color(0xFF00FF00),
          backgroundColor: const Color(0xFF111625),
          onRefresh: vm.loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(context, nickname, initial),
                const SizedBox(height: 24),
                if (vm.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: Color(0xFF00FF00),
                    ),
                  )
                else ...[
                  _buildStatsRow(context, vm),
                  const SizedBox(height: 28),
                  _buildQuickActions(context),
                  const SizedBox(height: 28),
                  _buildRecentReports(context, vm),
                  const SizedBox(height: 100), // padding for floating nav
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, String nickname, String initial) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF00FF00).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00FF00), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF00).withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 20,
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
                  'Welcome back, $nickname',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Scout Dashboard',
                  style: TextStyle(color: Color(0xFF8B95A5), fontSize: 13),
                ),
              ],
            ),
          ),
          // Scout badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF111625),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF00).withValues(alpha: 0.1),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility, color: Color(0xFF00FF00), size: 14),
                SizedBox(width: 4),
                Text(
                  'SCOUTER',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, ScouterHomeViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard('Players', vm.playerCount.toString(),
                    Icons.people_alt, const Color(0xFF00FF00)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Reports', vm.reportCount.toString(),
                    Icons.assignment, const Color(0xFF00AAFF)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard('Prospects', vm.prospectCount.toString(),
                    Icons.star, const Color(0xFFFFAA00)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Recommends', vm.recommendationCount.toString(),
                    Icons.recommend, const Color(0xFFFF55AA)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111625).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8B95A5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _quickActionCard(
                  icon: Icons.search,
                  label: 'Browse\nPlayers',
                  accentColor: const Color(0xFF00FF00),
                  onTap: () => onNavTap(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionCard(
                  icon: Icons.assignment,
                  label: 'My\nReports',
                  accentColor: const Color(0xFF00AAFF),
                  onTap: () => onNavTap(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionCard(
                  icon: Icons.recommend,
                  label: 'Recomm-\nendations',
                  accentColor: const Color(0xFFFFAA00),
                  onTap: () => onNavTap(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF111625).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.05),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReports(
      BuildContext context, ScouterHomeViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Reports',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => onNavTap(2),
                child: const Row(
                  children: [
                    Text('View All',
                        style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward,
                        color: Color(0xFF00FF00), size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (vm.recentReports.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111625).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined,
                        color: Color(0xFF8B95A5), size: 40),
                    SizedBox(height: 12),
                    Text(
                      'No reports yet. Go scout some players!',
                      style:
                          TextStyle(color: Color(0xFF8B95A5), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...vm.recentReports.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _reportCard(context, r),
                )),
        ],
      ),
    );
  }

  Widget _reportCard(BuildContext context, report) {
    final rating = report.rating as int;
    Color ratingColor = rating >= 80
        ? const Color(0xFF00FF00)
        : rating >= 60
            ? const Color(0xFFFFAA00)
            : const Color(0xFFFF0055);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111625).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ratingColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: ratingColor.withValues(alpha: 0.3)),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.playerNickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (report.recommendedRole != null)
                  Text(
                    report.recommendedRole!,
                    style: const TextStyle(
                        color: Color(0xFF8B95A5), fontSize: 12),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScouterPlayerDetailScreen(
                    playerUserId: report.playerIdStr,
                    scouterId: scouterId,
                  ),
                ),
              );
            },
            child: const Icon(Icons.arrow_forward_ios,
                color: Color(0xFF8B95A5), size: 14),
          ),
        ],
      ),
    );
  }
}
