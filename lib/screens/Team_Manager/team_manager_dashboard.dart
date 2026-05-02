import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/team_api.dart';
import 'package:arena_chain_flutter/core/models/team_model.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:arena_chain_flutter/navigation.dart';

class ManagerDashboardScreen extends StatefulWidget {
  final String teamId;
  const ManagerDashboardScreen({super.key, required this.teamId});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final _teamApi = TeamApi();
  Team? _team;
  List<Invitation> _sentInvites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    setState(() => _isLoading = true);
    try {
      final team = await _teamApi.getTeamById(widget.teamId);
      final invites = await _teamApi.getInvitationsSent(widget.teamId);
      setState(() {
        _team = team;
        _sentInvites = invites;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dashboard Sync Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF12121B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE94560))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF12121B),
      appBar: AppBar(
        title: const Text('Arena Command', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _refreshDashboard, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeamHeader(),
            const SizedBox(height: 30),
            _buildStatGrid(),
            const SizedBox(height: 30),
            _buildSectionHeader('Management Actions'),
            _buildActionRow(),
            const SizedBox(height: 30),
            _buildSectionHeader('Roster Preview'),
            _buildRosterList(),
            const SizedBox(height: 30),
            _buildSectionHeader('Recruitment Tracking'),
            _buildInvitesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(15),
              image: _team?.logo != null ? DecorationImage(image: NetworkImage(_team!.logo!), fit: BoxFit.cover) : null,
            ),
            child: _team?.logo == null ? const Icon(Icons.shield, size: 40, color: Colors.blueAccent) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_team?.name ?? 'Unknown Team', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (_team?.isVerified ?? false)
                      const Padding(padding: EdgeInsets.only(left: 8.0), child: Icon(Icons.verified, color: Colors.blueAccent, size: 18)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(_team?.type.toUpperCase() ?? 'AMATEUR', style: const TextStyle(color: Color(0xFFE94560), fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    return Row(
      children: [
        _statCard('Ligue Rank', _team?.ligue ?? 'Unplaced', Icons.auto_awesome),
        const SizedBox(width: 15),
        _statCard('ELO Rating', _team?.elo.toString() ?? '0', Icons.leaderboard),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 24),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(Icons.person_add, 'Recruit', Colors.green, () {
          Navigator.pushNamed(context, AppRoutes.recruitPlayer, arguments: widget.teamId);
        }),
        _actionButton(Icons.group, 'Full Roster', Colors.blue, () {
          Navigator.pushNamed(context, AppRoutes.manageRoster, arguments: widget.teamId);
        }),
        _actionButton(Icons.post_add, 'Post', Colors.orange, () {
          Navigator.pushNamed(context, AppRoutes.teamFeed, arguments: widget.teamId);
        }),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 28, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRosterList() {
    final roster = _team?.roster ?? [];
    if (roster.isEmpty) return const Text('Roster is empty. Start recruiting!', style: TextStyle(color: Colors.grey));

    return Column(
      children: roster.take(3).map((member) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundImage: member.avatar != null ? NetworkImage(member.avatar!) : null, child: member.avatar == null ? const Icon(Icons.person) : null),
        title: Text(member.nickname ?? 'Player', style: const TextStyle(color: Colors.white)),
        subtitle: Text(member.role, style: TextStyle(color: Colors.blueAccent.withOpacity(0.7))),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      )).toList(),
    );
  }

  Widget _buildInvitesList() {
    if (_sentInvites.isEmpty) return const Text('No active invitations.', style: TextStyle(color: Colors.grey));

    return Column(
      children: _sentInvites.take(3).map((invite) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.mail_outline, color: Colors.orange),
        title: Text('Invite to ${invite.receiver is Map ? invite.receiver['nickname'] : 'Player'}', style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Text(invite.role, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
          child: Text(invite.status.toUpperCase(), style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('View All', style: TextStyle(color: Color(0xFFE94560), fontSize: 12)),
        ],
      ),
    );
  }
}
