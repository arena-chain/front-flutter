import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
<<<<<<< HEAD
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/screens/player/feature_clubs/ui/clubs_list_screen.dart';
=======
import 'package:arena_chain_flutter/screens/player/feature_home/viewmodel/level_viewmodel.dart';
import 'package:arena_chain_flutter/navigation.dart';
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

<<<<<<< HEAD
=======
  static const Color _neonGreen = Color(0xFF39FF14);

>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F1221),
      child: Column(
        children: [
          _buildDrawerHeader(context),
<<<<<<< HEAD
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.hub_outlined,
                  title: 'Nexus Hub',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ClubsListScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
=======
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildLevelProgressionCard(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildDrawerItem(
                  context,
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
                  icon: Icons.video_library,
                  title: 'My Channel',
                  onTap: () {
                    // TODO: Navigate to My Channel
                    Navigator.pop(context); // Close drawer
                    Navigator.pushNamed(context, AppRoutes.myChannel);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.subscriptions,
                  title: 'Subscriptions',
                  onTap: () {
                    // TODO: Navigate to Subscriptions
                    Navigator.pop(context); // Close drawer
                    Navigator.pushNamed(context, AppRoutes.subscriptions);
                  },
                ),
<<<<<<< HEAD
                const Divider(color: Color(0xFF1A1F36), height: 32),
                _buildDrawerItem(
                  context,
                  icon: Icons.shield,
                  title: 'Leagues',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.pushNamed(context, AppRoutes.leagues);
                  },
                ),
=======
                _buildDrawerItem(
                  context,
                  icon: Icons.newspaper_rounded,
                  title: 'News',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.news);
                  },
                ),
                const Divider(color: Color(0xFF1A1F36), height: 32),
                ..._teamAndRecruitmentItems(context),
                const Divider(color: Color(0xFF1A1F36), height: 32),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),
                if (context.read<AuthViewModel>().currentUser?.role.toLowerCase() == 'admin')
                  _buildDrawerItem(
                    context,
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Dashboard',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.pushNamed(context, AppRoutes.adminHome);
                    },
                  ),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

<<<<<<< HEAD
=======
  /// Same destinations as profile team section: manager apply/dashboard + invitations inbox.
  List<Widget> _teamAndRecruitmentItems(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final user = auth.currentUser;
    final role = user?.role.toLowerCase() ?? '';
    final isManager = role == 'team_manager';
    final isAdmin = role == 'admin';

    return [
      if (isManager)
        _buildDrawerItem(
          context,
          icon: Icons.dashboard_customize,
          title: 'Manager Dashboard',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.managerDashboard, arguments: user?.teamId ?? '');
          },
        )
      else if (!isAdmin)
        _buildDrawerItem(
          context,
          icon: Icons.stars,
          title: 'Become Team Manager',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.managerApplication);
          },
        ),
      _buildDrawerItem(
        context,
        icon: Icons.inbox,
        title: 'Recruitment Inbox',
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.playerInvitations);
        },
      ),
    ];
  }

  /// Uses [LevelViewModel] when loaded (same API as the old home card); else `PlayerProfile.stats`; else defaults.
  Widget _buildLevelProgressionCard(BuildContext context) {
    return Consumer2<AuthViewModel, LevelViewModel>(
      builder: (context, auth, levelVm, _) {
        final api = levelVm.currentLevel;
        final stats = auth.currentUser?.profile?.stats ?? {};

        late final int level;
        late final int currentXp;
        late final int xpCap;
        late final double pct;
        late final String pctLabel;

        if (api != null) {
          level = api.level;
          currentXp = api.xp;
          xpCap = api.xpToNextLevel <= 0 ? 1000 : api.xpToNextLevel;
          pct = (api.progressPct / 100).clamp(0.0, 1.0);
          pctLabel = '${api.progressPct.clamp(0.0, 100.0).round()}% Complete';
        } else {
          int lv = (stats['level'] as num?)?.toInt() ?? 0;
          if (lv < 1) lv = 1;
          level = lv;
          currentXp = (stats['xp'] as num?)?.toInt() ??
              (stats['experience'] as num?)?.toInt() ??
              0;
          var cap = (stats['xpToNextLevel'] as num?)?.toInt() ??
              (stats['xpForNextLevel'] as num?)?.toInt() ??
              1000;
          if (cap <= 0) cap = 1000;
          xpCap = cap;
          pct = (currentXp / xpCap).clamp(0.0, 1.0);
          pctLabel = '${(pct * 100).round()}% Complete';
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF1A4D2E),
                Color(0xFF0A120E),
                Color(0xFF050807),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
            border: Border.all(
              color: _neonGreen.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _neonGreen.withValues(alpha: 0.12),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LEVEL PROGRESSION',
                          style: TextStyle(
                            color: _neonGreen.withValues(alpha: 0.95),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Level $level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _neonGreen.withValues(alpha: 0.85), width: 1.5),
                      color: _neonGreen.withValues(alpha: 0.12),
                    ),
                    child: Icon(Icons.bolt_rounded, color: _neonGreen, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  valueColor: AlwaysStoppedAnimation<Color>(_neonGreen.withValues(alpha: 0.9)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$currentXp / $xpCap XP',
                      style: TextStyle(
                        color: _neonGreen.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    pctLabel,
                    style: TextStyle(
                      color: _neonGreen.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
  Widget _buildDrawerHeader(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final user = authViewModel.currentUser;
        final nickname = user?.nickname ?? 'Player';
        final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'P';
        final email = user?.email ?? 'player@example.com';

        return InkWell(
          onTap: () {
            Navigator.pop(context); // Close drawer
            Navigator.pushNamed(context, AppRoutes.playerProfile);
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0E1A),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1A1F36)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
<<<<<<< HEAD
                    color: const Color(0xFF00FF00).withOpacity(0.2),
=======
                    color: const Color(0xFF00FF00).withValues(alpha: 0.2),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00FF00), width: 2),
                    image: (user?.avatar != null && user!.avatar!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(user.avatar!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (user == null || user.avatar == null || user.avatar!.isEmpty)
                      ? Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFF7A86AC),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
<<<<<<< HEAD
      leading: Icon(icon, color: const Color(0xFF00FF00)),
=======
      leading: Icon(icon, color: _neonGreen),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Divider(color: Color(0xFF1A1F36), height: 1),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFFF0055)),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFFF0055),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              Navigator.pop(context); // Close drawer
              final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
              await authViewModel.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 10),
          Divider(
              color: const Color(0xFF1A1F36),
          ),
          const SizedBox(height: 10),
          Text(
            'Arena Chain v1.0.0',
            style: TextStyle(
<<<<<<< HEAD
              color: const Color(0xFF7A86AC).withOpacity(0.5),
=======
              color: const Color(0xFF7A86AC).withValues(alpha: 0.5),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
