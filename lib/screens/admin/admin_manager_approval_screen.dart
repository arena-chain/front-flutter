import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/team_manager_api.dart';
import 'package:arena_chain_flutter/core/models/feature_auth/team_manager_profile_model.dart';

class AdminManagerApprovalScreen extends StatefulWidget {
  const AdminManagerApprovalScreen({super.key});

  @override
  State<AdminManagerApprovalScreen> createState() => _AdminManagerApprovalScreenState();
}

class _AdminManagerApprovalScreenState extends State<AdminManagerApprovalScreen> {
  final _managerApi = TeamManagerApi();
  List<TeamManagerProfile> _pendingManagers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    try {
      final managers = await _managerApi.getPendingManagers();
      setState(() {
        _pendingManagers = managers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pending managers: $e')),
        );
      }
    }
  }

  Future<void> _processAction(String userId, bool approve) async {
    setState(() => _isLoading = true);
    try {
      if (approve) {
        await _managerApi.approveManager(userId);
      } else {
        await _managerApi.rejectManager(userId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Manager ${approve ? 'Approved' : 'Rejected'} Successfully')),
      );
      _loadPending();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Approval Dashboard'),
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _pendingManagers.isEmpty
          ? const Center(child: Text('No pending applications.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _pendingManagers.length,
              itemBuilder: (context, index) {
                final mgr = _pendingManagers[index];
                return Card(
                  color: const Color(0xFF2D2D44),
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
                              backgroundColor: Color(0xFFE94560),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${mgr.firstName} ${mgr.lastName}',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    mgr.organizationName ?? 'Independent Manager',
                                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                              child: const Text('PENDING', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 30),
                        _infoRow(Icons.groups, 'Target Team', mgr.teamName ?? 'Unspecified'),
                        _infoRow(Icons.description, 'Identity (CIN)', mgr.cin ?? 'Private'),
                        _infoRow(Icons.phone, 'Contact', mgr.phoneNumber ?? 'None provided'),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _processAction(mgr.userId, false),
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
                                onPressed: () => _processAction(mgr.userId, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('APPROVE'),
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
      backgroundColor: const Color(0xFF1E1E2C),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
