import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/core/api/team_api.dart';
import 'dart:async';

class RecruitPlayerScreen extends StatefulWidget {
  final String teamId;
  const RecruitPlayerScreen({super.key, required this.teamId});

  @override
  State<RecruitPlayerScreen> createState() => _RecruitPlayerScreenState();
}

class _RecruitPlayerScreenState extends State<RecruitPlayerScreen> {
  final _teamApi = TeamApi();
  Timer? _searchDebounce;
  
  List<PlayerDetail> _players = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
  }

  Future<void> _fetchPlayers([String query = '']) async {
    setState(() => _isLoading = true);
    try {
      final results = await _teamApi.searchPlayers(query);
      setState(() {
        _players = results.map((json) => PlayerDetail.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query;
      _fetchPlayers(query);
    });
  }

  void _showInviteModal(PlayerDetail player) {
    String selectedRole = 'Top';
    final messageController = TextEditingController(text: 'We want you in our team!');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invite ${player.nickname}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Assign Roster Role', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF16213E),
                value: selectedRole,
                items: ['Top', 'Jungle', 'Mid', 'ADC', 'Support', 'Substitute', 'Coach'].map((role) {
                  return DropdownMenuItem(value: role, child: Text(role, style: const TextStyle(color: Colors.white)));
                }).toList(),
                onChanged: (val) => setModalState(() => selectedRole = val!),
                decoration: _modalInputDecoration(),
              ),
              const SizedBox(height: 20),
              const Text('Invitation Message', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: messageController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _modalInputDecoration(),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
                  onPressed: () async {
                    try {
                      await _teamApi.sendInvitation(
                        widget.teamId, 
                        player.userId, 
                        selectedRole, 
                        messageController.text
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation sent!')));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  },
                  child: const Text('SEND OFFICIAL INVITE'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _modalInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF16213E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121B),
      appBar: AppBar(
        title: const Text('Recruit Players'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by nickname...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final p = _players[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: p.avatar != null ? NetworkImage(p.avatar!) : null,
                        child: p.avatar == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(p.nickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('${p.rank} • ${p.country}', style: const TextStyle(color: Colors.grey)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560).withOpacity(0.8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () => _showInviteModal(p),
                        child: const Text('INVITE', style: TextStyle(fontSize: 12)),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
