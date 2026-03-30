import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/team_api.dart';
import 'package:arena_chain_flutter/core/models/team_model.dart';

class TeamProfileScreen extends StatefulWidget {
  final String teamId;
  const TeamProfileScreen({super.key, required this.teamId});

  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends State<TeamProfileScreen> {
  final _teamApi = TeamApi();
  Team? _team;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF16213E),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_team?.logo != null)
                    Image.network(_team!.logo!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 80))
                  else
                    const Center(child: Icon(Icons.shield, size: 80, color: Colors.blueAccent)),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, const Color(0xFF0F0F1E).withOpacity(0.9), const Color(0xFF0F0F1E)]))),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_team?.name ?? 'Unknown Team', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                            if (_team?.isVerified ?? false)
                              const Padding(padding: EdgeInsets.only(left: 10), child: Icon(Icons.verified, color: Colors.blueAccent, size: 22)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(_team?.type.toUpperCase() ?? 'AMATEUR', style: const TextStyle(color: Color(0xFFE94560), letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About Team', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(_team?.description ?? 'No description provided.', style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 30),
                  const Text('Official Roster', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ...(_team?.roster ?? []).map((member) => _buildMemberTile(member)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(TeamMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: member.avatar != null ? NetworkImage(member.avatar!) : null,
            child: member.avatar == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.nickname ?? 'Player', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE94560).withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                  child: Text(member.role.toUpperCase(), style: const TextStyle(color: Color(0xFFE94560), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('JOINED', style: TextStyle(color: Colors.grey, fontSize: 8)),
              Text('${member.joinedAt.month}/${member.joinedAt.year}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
