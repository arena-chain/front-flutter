import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/navigation.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Account',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () {
                  // TODO: Navigate to edit profile
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  // TODO: Navigate to change password
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: Icons.videogame_asset,
                title: 'My Account',
                subtitle: 'Link your League of Legends account',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.myAccount);
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'General',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English',
                onTap: () {
                  // TODO: Show language picker
                },
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F36),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF0055).withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0055).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout, color: Color(0xFFFF0055), size: 20),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xFFFF0055),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () async {
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1F36)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00FF00).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF00FF00), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7A86AC),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF7A86AC),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}



