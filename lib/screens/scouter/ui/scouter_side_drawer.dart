import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_home_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_players_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_reports_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_watchlist_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_recommendations_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_players_tab.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_watchlist_tab.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_reports_tab.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_recommendations_tab.dart';

const _drawerBg    = Color(0xFF0A0E1B);
const _drawerCard  = Color(0xFF111827);
const _drawerBrd   = Color(0xFF1E2740);
const _accent      = Color(0xFF00FF00);
const _muted       = Color(0xFF4A5568);

class ScouterSideDrawer extends StatelessWidget {
  const ScouterSideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final nickname = auth.currentUser?.nickname ?? 'Scout';
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'S';
    final scouterId = auth.currentUser?.id ?? '';

    return Drawer(
      backgroundColor: _drawerBg,
      width: MediaQuery.of(context).size.width * 0.78,
      child: Column(
        children: [
          // ─── Profile Header ─────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F1F3A), Color(0xFF0A0E1B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(bottom: BorderSide(color: _drawerBrd)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 60, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with glow
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF00FF00), Color(0xFF003320)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Consumer<ScouterHomeViewModel>(
                  builder: (_, vm, __) => Row(
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${vm.scouterLevel} Scout',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<ScouterHomeViewModel>(
                  builder: (_, vm, __) => Row(
                    children: [
                      _statChip('${vm.reportCount}', 'Reports'),
                      const SizedBox(width: 8),
                      _statChip('${vm.prospectCount}', 'Watchlist'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => vm.loadDashboard(),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: _muted,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Menu ────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _section('DISCOVER'),
                _menuItem(
                  context: context,
                  icon: Icons.explore_outlined,
                  label: 'Explore',
                  color: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => ScouterPlayersViewModel()..loadGames(),
                        child: ScouterPlayersTab(scouterId: scouterId),
                      ),
                    ));
                  },
                ),

                _section('SCOUTING'),
                _menuItem(
                  context: context,
                  icon: Icons.bookmark_outline,
                  label: 'Watchlist',
                  color: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => ScouterWatchlistViewModel(scouterId: scouterId)..loadWatchlist(),
                        child: ScouterWatchlistTab(scouterId: scouterId),
                      ),
                    ));
                  },
                ),
                _menuItem(
                  context: context,
                  icon: Icons.assignment_outlined,
                  label: 'Reports',
                  color: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => ScouterReportsViewModel(scouterId: scouterId)..loadReports(),
                        child: ScouterReportsTab(scouterId: scouterId),
                      ),
                    ));
                  },
                ),
                _menuItem(
                  context: context,
                  icon: Icons.send_outlined,
                  label: 'Recommendations',
                  color: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => ScouterRecommendationsViewModel(scouterId: scouterId)..loadRecommendations(),
                        child: ScouterRecommendationsTab(scouterId: scouterId),
                      ),
                    ));
                  },
                ),
              ],
            ),
          ),

          // ─── Footer ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _drawerBrd)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logout button
                Builder(
                  builder: (ctx) => GestureDetector(
                    onTap: () async {
                      final auth = ctx.read<AuthViewModel>();
                      Navigator.pop(ctx); // close drawer first
                      await auth.logout();
                      if (ctx.mounted) {
                        Navigator.of(ctx).pushNamedAndRemoveUntil('/', (_) => false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B5C).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF3B5C).withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B5C).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout_rounded, color: Color(0xFFFF3B5C), size: 18),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Sign Out',
                            style: TextStyle(
                              color: Color(0xFFFF3B5C),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Branding row
                Row(children: [
                  const Icon(Icons.shield_outlined, color: _accent, size: 18),
                  const SizedBox(width: 10),
                  const Text(
                    'ArenaChain Scouting',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: _muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _drawerCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _drawerBrd),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: _muted, size: 18),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
