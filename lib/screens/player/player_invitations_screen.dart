import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/team_api.dart';
import 'package:arena_chain_flutter/core/models/team_model.dart';

class PlayerInvitationsScreen extends StatefulWidget {
  const PlayerInvitationsScreen({super.key});

  @override
  State<PlayerInvitationsScreen> createState() => _PlayerInvitationsScreenState();
}

class _PlayerInvitationsScreenState extends State<PlayerInvitationsScreen> {
  final _teamApi = TeamApi();
  List<Invitation> _invitations = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchInvitations();
  }

  Future<void> _fetchInvitations() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final invites = await _teamApi.getReceivedInvitations();
      if (!mounted) return;
      setState(() {
        _invitations = invites;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _invitations = [];
        _isLoading = false;
        _loadError = msg.startsWith('Exception: ') ? msg.substring('Exception: '.length) : msg;
      });
    }
  }

  Future<void> _respond(String inviteId, String status) async {
    setState(() => _isLoading = true);
    try {
      await _teamApi.respondToInvitation(inviteId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation ${status == 'accepted' ? 'Accepted' : 'Rejected'}!')),
      );
      _fetchInvitations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121B),
      appBar: AppBar(
        title: const Text('Roster Invitations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_outlined, color: Colors.orangeAccent, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _loadError!.contains('404')
                              ? 'Invitations API not found on the server (404).\nYour backend must expose GET /api/teams/invitations/received\n(or change TeamApi to match your route).'
                              : _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, height: 1.35),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _fetchInvitations,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _invitations.isEmpty
                  ? const Center(
                      child: Text('No active invitations.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _invitations.length,
              itemBuilder: (context, index) {
                final invite = _invitations[index];
                if (invite.status != 'pending') return const SizedBox.shrink();

                final teamName = invite.team is Map ? invite.team['name'] : 'Unknown Team';
                final senderName = invite.sender is Map ? invite.sender['nickname'] : 'Manager';

                return Card(
                  color: const Color(0xFF1A1A2E),
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Icon(Icons.group, color: Colors.white),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(teamName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('Sent by $senderName', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 30),
                        const Text('OFFERED ROLE:', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(invite.role.toUpperCase(), style: const TextStyle(color: Color(0xFFE94560), fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        const Text('MESSAGE:', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(invite.message, style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _respond(invite.id, 'rejected'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('REJECT', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _respond(invite.id, 'accepted'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('ACCEPT'),
                              ),
                            ),
                          ],
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
