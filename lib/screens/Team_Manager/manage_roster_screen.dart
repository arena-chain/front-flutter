import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/team_api.dart';
import 'package:arena_chain_flutter/core/models/team_model.dart';

class ManageRosterScreen extends StatefulWidget {
  final String teamId;
  const ManageRosterScreen({super.key, required this.teamId});

  @override
  State<ManageRosterScreen> createState() => _ManageRosterScreenState();
}

class _ManageRosterScreenState extends State<ManageRosterScreen> {
  final _teamApi = TeamApi();
  Team? _team;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoster();
  }

  Future<void> _fetchRoster() async {
    setState(() => _isLoading = true);
    try {
      final team = await _teamApi.getTeamById(widget.teamId);
      setState(() {
        _team = team;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _removeMember(String userId, String nickname) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Confirm Removal', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to remove $nickname from the roster?', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('REMOVE', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _teamApi.removeMember(widget.teamId, userId);
        _fetchRoster();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member removed.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121B),
      appBar: AppBar(
        title: const Text('Roster Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: _team?.roster?.length ?? 0,
            itemBuilder: (context, index) {
              final member = _team!.roster![index];
              return Card(
                color: const Color(0xFF1A1A2E),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundImage: member.avatar != null ? NetworkImage(member.avatar!) : null,
                    child: member.avatar == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(member.nickname ?? 'Unknown Player', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text('ROLE: ${member.role}', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                      Text('Joined: ${member.joinedAt.day}/${member.joinedAt.month}/${member.joinedAt.year}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () => _removeMember(member.userId, member.nickname ?? 'Player'),
                    icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                  ),
                ),
              );
            },
          ),
    );
  }
}
