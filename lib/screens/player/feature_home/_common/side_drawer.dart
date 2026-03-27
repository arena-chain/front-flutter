import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/navigation.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F1221),
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildDrawerItem(
                  context,
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
                 _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.pushNamed(context, AppRoutes.settings);
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
                    color: const Color(0xFF00FF00).withOpacity(0.2),
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
      leading: Icon(icon, color: const Color(0xFF00FF00)),
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
              color: const Color(0xFF7A86AC).withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
