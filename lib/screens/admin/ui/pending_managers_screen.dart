import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/team_manager_api.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/team_manager_profile_model.dart';
// import 'package:arena_chain_flutter/core/models/team_model.dart'; // To show requested team name if populated

class PendingManagersScreen extends StatefulWidget {
  const PendingManagersScreen({super.key});

  @override
  State<PendingManagersScreen> createState() => _PendingManagersScreenState();
}

class _PendingManagersScreenState extends State<PendingManagersScreen> {
  final TeamManagerApi _api = TeamManagerApi();
  List<TeamManagerProfile> _managers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  Future<void> _loadManagers() async {
    setState(() => _isLoading = true);
    try {
      final managers = await _api.getPendingManagers();
      setState(() {
        _managers = managers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approve(String userId) async {
    try {
      await _api.approveManager(userId);
      _loadManagers();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manager approved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _reject(String userId) async {
    try {
      await _api.rejectManager(userId);
      _loadManagers();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manager rejected')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // Filter out managers with invalid userId
    final validManagers = _managers.where((m) => m.userId.isNotEmpty).toList();

    if (validManagers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No pending requests', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text(
              'Note: Old test data without valid user IDs has been filtered out.\nPlease create new team manager registrations.',
              style: TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: validManagers.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final profile = validManagers[index];
        return Card(
          color: const Color(0xFF1A1F36),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.firstName ?? "Unknown"} ${profile.lastName ?? "User"}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 4),
                Text('Organization: ${profile.organizationName ?? "N/A"}', style: const TextStyle(color: Color(0xFF7A86AC))),
                Text('Team: ${profile.teamName ?? profile.teamId ?? "Unknown"}', style: const TextStyle(color: Color(0xFF7A86AC))),
                const SizedBox(height: 8),
                Text('Description: ${profile.description ?? ""}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _reject(profile.userId),
                      child: const Text('Reject', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _approve(profile.userId),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF00)),
                      child: const Text('Approve', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
