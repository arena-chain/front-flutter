import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/team_api.dart';
import 'package:arena_chain_flutter/core/models/team_model.dart';

class TeamsManagementScreen extends StatefulWidget {
  const TeamsManagementScreen({super.key});

  @override
  State<TeamsManagementScreen> createState() => _TeamsManagementScreenState();
}

class _TeamsManagementScreenState extends State<TeamsManagementScreen> {
  final TeamApi _teamApi = TeamApi();
  List<Team> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    try {
      final teams = await _teamApi.getTeams();
      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTeam(String id) async {
    try {
      await _teamApi.deleteTeam(id);
      _loadTeams();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _verifyTeam(String id) async {
    try {
      await _teamApi.updateTeam(id, {'isVerified': true});
      _loadTeams();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCreateTeamDialog() {
    final nameController = TextEditingController();
    String type = 'amateur';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F36),
        title: const Text('Create Team', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Team Name',
                labelStyle: TextStyle(color: Color(0xFF7A86AC)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF7A86AC))),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: type,
              dropdownColor: const Color(0xFF1A1F36),
              style: const TextStyle(color: Colors.white),
              items: ['amateur', 'pro'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => type = v!,
              decoration: const InputDecoration(
                labelText: 'Type',
                labelStyle: TextStyle(color: Color(0xFF7A86AC)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await _teamApi.createTeam({'name': nameController.text, 'type': type});
                  if (mounted) Navigator.pop(context);
                  _loadTeams();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by parent
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00FF00),
        onPressed: _showCreateTeamDialog,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: ListView.builder(
        itemCount: _teams.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final team = _teams[index];
          return Card(
            color: const Color(0xFF1A1F36),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('${team.type} - ${team.isVerified ? "Verified" : "Unverified"}', style: const TextStyle(color: Color(0xFF7A86AC))),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!team.isVerified)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                      onPressed: () => _verifyTeam(team.id),
                      tooltip: 'Verify Team',
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTeam(team.id),
                    tooltip: 'Delete Team',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
