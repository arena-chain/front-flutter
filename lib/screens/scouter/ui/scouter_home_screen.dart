import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_players_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_reports_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_matches_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_watchlist_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_home_view_model.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_feed_tab.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_side_drawer.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/view_all_players_screen.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/view_all_leagues_screen.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/view_all_tournaments_screen.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_teams_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_highlights/ui/player_highlights_feed_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_highlights/viewmodel/highlights_feed_view_model.dart';

/// === Color Design System ===
/// Background Top:    #040609
/// Background Bottom: #0A0D14
/// Surface:           #111625
/// Accent:            #00FF00
/// Text Secondary:    #8B95A5

class ScouterHomeScreen extends StatefulWidget {
  const ScouterHomeScreen({super.key});

  @override
  State<ScouterHomeScreen> createState() => _ScouterHomeScreenState();
}

class _ScouterHomeScreenState extends State<ScouterHomeScreen> {
  int _currentIndex = 0;
  bool _bootstrapped = false;
  String _scouterId = '';

  ScouterPlayersViewModel? _playersVm;
  ScouterReportsViewModel? _reportsVm;
  ScouterMatchesViewModel? _matchesVm;
  ScouterWatchlistViewModel? _watchlistVm;
  ScouterHomeViewModel? _homeVm;
  HighlightsFeedViewModel? _highlightsFeedVm;

  static const _bgTop = Color(0xFF040609);
  static const _bgBottom = Color(0xFF0A0D14);
  static const _surface = Color(0xFF111625);
  static const _accent = Color(0xFF00FF00);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthViewModel>();
    final id = auth.currentUser?.id ?? '';
    if (_bootstrapped && id == _scouterId) return;

    _scouterId = id;
    _playersVm?.dispose();
    _reportsVm?.dispose();
    _matchesVm?.dispose();
    _watchlistVm?.dispose();
    _homeVm?.dispose();
    _highlightsFeedVm?.dispose();

    _playersVm = ScouterPlayersViewModel()..loadGames();
    _reportsVm = ScouterReportsViewModel(scouterId: _scouterId)..loadReports();
    _matchesVm = ScouterMatchesViewModel(scouterId: _scouterId)..loadMatches();
    _watchlistVm = ScouterWatchlistViewModel(scouterId: _scouterId)..loadWatchlist();
    _homeVm = ScouterHomeViewModel(scouterId: _scouterId)..loadDashboard();
    _highlightsFeedVm = HighlightsFeedViewModel();
    _bootstrapped = true;
  }

  @override
  void dispose() {
    _playersVm?.dispose();
    _reportsVm?.dispose();
    _matchesVm?.dispose();
    _watchlistVm?.dispose();
    _homeVm?.dispose();
    _highlightsFeedVm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapped ||
        _playersVm == null ||
        _reportsVm == null ||
        _matchesVm == null ||
        _watchlistVm == null ||
        _homeVm == null ||
        _highlightsFeedVm == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: _accent),
        ),
      );
    }

    void goToTab(int i) => setState(() => _currentIndex = i);
    final List<Widget> pages = [
      ScouterFeedTab(scouterId: _scouterId),
      const PlayerHighlightsFeedScreen(),
      ViewAllPlayersScreen(
        scouterId: _scouterId,
        onBack: () => goToTab(0),
      ),
      ScouterTeamsScreen(onBack: () => goToTab(0)),
      ViewAllLeaguesScreen(onBack: () => goToTab(0)),
      ViewAllTournamentsScreen(onBack: () => goToTab(0)),
    ];

    final List<_NavItem> navItems = [
      _NavItem(icon: Icons.sports_esports_outlined, activeIcon: Icons.sports_esports, label: 'Matches'),
      _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'Highlights'),
      _NavItem(icon: Icons.person_search_outlined, activeIcon: Icons.person_search, label: 'Players'),
      _NavItem(icon: Icons.group_outlined, activeIcon: Icons.group, label: 'Teams'),
      _NavItem(icon: Icons.shield_outlined, activeIcon: Icons.shield, label: 'Leagues'),
      _NavItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'Events'),
    ];

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _playersVm!),
        ChangeNotifierProvider.value(value: _reportsVm!),
        ChangeNotifierProvider.value(value: _matchesVm!),
        ChangeNotifierProvider.value(value: _watchlistVm!),
        ChangeNotifierProvider.value(value: _homeVm!),
        ChangeNotifierProvider.value(value: _highlightsFeedVm!),
      ],
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgTop, _bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          drawer: const ScouterSideDrawer(),
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildFloatingNavBar(navItems),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar(List<_NavItem> items) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: _surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final selected = _currentIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _accent.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: selected
                            ? Border.all(color: _accent.withValues(alpha: 0.3))
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            color: selected ? _accent : const Color(0xFF8B95A5),
                            size: 22,
                          ),
                          if (selected) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _accent.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: const TextStyle(
                                color: Color(0xFF8B95A5),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
