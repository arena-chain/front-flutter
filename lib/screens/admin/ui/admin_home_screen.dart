import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/screens/feature_auth/ui/login_screen.dart'; // For logout roughly
import 'package:arena_chain_flutter/core/api/feature_auth/auth_api.dart'; // For logout
import 'package:arena_chain_flutter/core/models/feature_auth/team_manager_profile_model.dart';
import 'package:arena_chain_flutter/screens/admin/ui/teams_management_screen.dart';
import 'package:arena_chain_flutter/screens/admin/ui/pending_managers_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    TeamsManagementScreen(),
    PendingManagersScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0C08),
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Logout logic
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1F36),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Teams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Requests',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF00FF00),
        unselectedItemColor: const Color(0xFF7A86AC),
        onTap: _onItemTapped,
      ),
    );
  }
}
