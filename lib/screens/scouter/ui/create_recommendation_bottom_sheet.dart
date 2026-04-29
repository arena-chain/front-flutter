import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/feature_scouter/players_directory_api.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/directory_models.dart' show TeamItem;

class CreateRecommendationBottomSheet extends StatefulWidget {
  final String scouterId;
  final String playerId;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;

  const CreateRecommendationBottomSheet({
    super.key,
    required this.scouterId,
    required this.playerId,
    required this.onSubmit,
  });

  @override
  State<CreateRecommendationBottomSheet> createState() =>
      _CreateRecommendationBottomSheetState();
}

class _CreateRecommendationBottomSheetState
    extends State<CreateRecommendationBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  String _level = 'CONSIDER';
  bool _submitting = false;

  // Team picker state
  List<TeamItem> _teams = [];
  bool _loadingTeams = true;
  TeamItem? _selectedTeam;

  static const _levels = [
    'CONSIDER',
    'STRONGLY_RECOMMEND',
    'MUST_SIGN',
  ];

  static const _levelLabels = {
    'CONSIDER': 'Consider',
    'STRONGLY_RECOMMEND': 'Strongly Recommend',
    'MUST_SIGN': 'Must Sign',
  };

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    try {
      final teams = await PlayersDirectoryApi().getTeams();
      if (mounted) setState(() { _teams = teams; _loadingTeams = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTeams = false);
    }
  }

  void _openTeamPicker() {
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1221),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final filtered = _teams.where((t) {
            if (search.isEmpty) return true;
            return t.name.toLowerCase().contains(search.toLowerCase()) ||
                (t.organizationName?.toLowerCase().contains(search.toLowerCase()) ?? false);
          }).toList();
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF2A2F46), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Select Organization', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    autofocus: true,
                    onChanged: (v) => setModal(() => search = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search teams…',
                      hintStyle: const TextStyle(color: Color(0xFF4A5568)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF4A5568), size: 18),
                      filled: true,
                      fillColor: const Color(0xFF1A1F36),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _loadingTeams
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFAA44FF), strokeWidth: 2))
                      : filtered.isEmpty
                          ? const Center(child: Text('No teams found', style: TextStyle(color: Color(0xFF4A5568))))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final t = filtered[i];
                                final selected = _selectedTeam?.id == t.id;
                                return ListTile(
                                  onTap: () {
                                    setState(() => _selectedTeam = t);
                                    Navigator.pop(ctx);
                                  },
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  tileColor: selected ? const Color(0xFFAA44FF).withOpacity(0.12) : null,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFFAA44FF).withOpacity(0.15),
                                    backgroundImage: (t.logo != null && t.logo!.isNotEmpty) ? NetworkImage(t.logo!) : null,
                                    child: (t.logo == null || t.logo!.isEmpty)
                                        ? Text(t.name.isNotEmpty ? t.name[0].toUpperCase() : 'T',
                                            style: const TextStyle(color: Color(0xFFAA44FF), fontWeight: FontWeight.bold))
                                        : null,
                                  ),
                                  title: Text(t.name, style: TextStyle(color: selected ? const Color(0xFFAA44FF) : Colors.white, fontWeight: FontWeight.w600)),
                                  subtitle: t.organizationName != null
                                      ? Text(t.organizationName!, style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 11))
                                      : null,
                                  trailing: selected ? const Icon(Icons.check_circle, color: Color(0xFFAA44FF), size: 18) : null,
                                );
                              },
                            ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final body = {
        'scouterId': widget.scouterId,
        'playerId': widget.playerId,
        if (_selectedTeam != null) 'organizationId': _selectedTeam!.id,
        'recommendationLevel': _level,
        if (_messageCtrl.text.trim().isNotEmpty)
          'message': _messageCtrl.text.trim(),
      };
      await widget.onSubmit(body);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2F46),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Recommend Player',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Level selector
              _label('Recommendation Level'),
              Column(
                children: _levels.map((l) {
                  final color = l == 'MUST_SIGN'
                      ? const Color(0xFFFF0055)
                      : l == 'STRONGLY_RECOMMEND'
                          ? const Color(0xFFFFAA00)
                          : const Color(0xFF00AAFF);
                  return GestureDetector(
                    onTap: () => setState(() => _level = l),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _level == l
                            ? color.withOpacity(0.12)
                            : const Color(0xFF1A1F36),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _level == l
                              ? color
                              : const Color(0xFF2A2F46),
                          width: _level == l ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _level == l
                                      ? color
                                      : const Color(0xFF4A5568),
                                  width: 2),
                              color: _level == l
                                  ? color.withOpacity(0.2)
                                  : Colors.transparent,
                            ),
                            child: _level == l
                                ? Icon(Icons.check, color: color, size: 12)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _levelLabels[l] ?? l,
                            style: TextStyle(
                              color: _level == l ? color : const Color(0xFF7A86AC),
                              fontSize: 14,
                              fontWeight: _level == l
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Organization picker
              _label('Organization (optional)'),
              GestureDetector(
                onTap: _openTeamPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F36),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedTeam != null ? const Color(0xFFAA44FF) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_selectedTeam != null) ...[
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFAA44FF).withOpacity(0.15),
                          backgroundImage: (_selectedTeam!.logo != null && _selectedTeam!.logo!.isNotEmpty)
                              ? NetworkImage(_selectedTeam!.logo!) : null,
                          child: (_selectedTeam!.logo == null || _selectedTeam!.logo!.isEmpty)
                              ? Text(_selectedTeam!.name[0].toUpperCase(),
                                  style: const TextStyle(color: Color(0xFFAA44FF), fontSize: 11, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_selectedTeam!.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                        GestureDetector(
                          onTap: () => setState(() => _selectedTeam = null),
                          child: const Icon(Icons.close, color: Color(0xFF4A5568), size: 16),
                        ),
                      ] else ...[
                        _loadingTeams
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFAA44FF)))
                            : const Icon(Icons.business_outlined, color: Color(0xFF4A5568), size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _loadingTeams ? 'Loading teams…' : 'Select a team (optional)',
                          style: const TextStyle(color: Color(0xFF4A5568)),
                        ),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4A5568), size: 18),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Message
              _label('Message (optional)'),
              TextFormField(
                controller: _messageCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: _inputDecoration(
                    'Strong performance in recent matches…'),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAA44FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Send Recommendation',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF4A5568)),
        filled: true,
        fillColor: const Color(0xFF1A1F36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFAA44FF)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
