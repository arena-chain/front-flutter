import 'package:flutter/material.dart';

class CreateReportBottomSheet extends StatefulWidget {
  final String scouterId;
  final String playerId;
  final String? playerNickname;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;
  final VoidCallback? onReportCreated;

  const CreateReportBottomSheet({
    super.key,
    required this.scouterId,
    required this.playerId,
    this.playerNickname,
    required this.onSubmit,
    this.onReportCreated,
  });

  @override
  State<CreateReportBottomSheet> createState() =>
      _CreateReportBottomSheetState();
}

class _CreateReportBottomSheetState extends State<CreateReportBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  double _rating = 75;
  final _strengthsCtrl = TextEditingController();
  final _weaknessesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _matchIdCtrl = TextEditingController();
  String? _role;
  bool _submitting = false;

  static const _roles = [
    'Duelist', 'IGL', 'Support', 'Lurker',
    'Rifler', 'AWPer', 'Jungler', 'Carry',
    'Tank', 'Controller', 'Sentinel', 'Initiator',
  ];

  @override
  void dispose() {
    _strengthsCtrl.dispose();
    _weaknessesCtrl.dispose();
    _notesCtrl.dispose();
    _matchIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{
        'scouterId': widget.scouterId,
        'playerId': widget.playerId,
        if (widget.playerNickname != null) 'playerNickname': widget.playerNickname,
        'rating': _rating.round(),
        if (_strengthsCtrl.text.trim().isNotEmpty)
          'strengths': _strengthsCtrl.text.trim(),
        if (_weaknessesCtrl.text.trim().isNotEmpty)
          'weaknesses': _weaknessesCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty)
          'notes': _notesCtrl.text.trim(),
        if (_role != null) 'recommendedRole': _role,
        if (_matchIdCtrl.text.trim().isNotEmpty)
          'matchId': _matchIdCtrl.text.trim(),
      };
      await widget.onSubmit(body);
      if (mounted) {
        widget.onReportCreated?.call();
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingColor = _rating >= 80
        ? const Color(0xFF00FF00)
        : _rating >= 60
            ? const Color(0xFFFFAA00)
            : const Color(0xFFFF0055);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
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
                'New Scouting Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Rating
              Row(
                children: [
                  const Text('Rating',
                      style: TextStyle(
                          color: Color(0xFF7A86AC), fontSize: 12)),
                  const Spacer(),
                  Text(
                    '${_rating.round()}',
                    style: TextStyle(
                      color: ratingColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: ratingColor,
                  thumbColor: ratingColor,
                  inactiveTrackColor: const Color(0xFF1A1F36),
                  overlayColor: ratingColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: _rating,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  onChanged: (v) => setState(() => _rating = v),
                ),
              ),
              const SizedBox(height: 16),

              // Role
              _label('Recommended Role'),
              DropdownButtonFormField<String>(
                value: _role,
                dropdownColor: const Color(0xFF1A1F36),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Select role'),
                items: _roles
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _role = v),
              ),
              const SizedBox(height: 14),

              // Strengths
              _label('Strengths'),
              TextFormField(
                controller: _strengthsCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: _inputDecoration('Strong aim, good positioning…'),
              ),
              const SizedBox(height: 14),

              // Weaknesses
              _label('Weaknesses'),
              TextFormField(
                controller: _weaknessesCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: _inputDecoration('Communication, map awareness…'),
              ),
              const SizedBox(height: 14),

              // Notes
              _label('Notes'),
              TextFormField(
                controller: _notesCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: _inputDecoration('Additional observations…'),
              ),
              const SizedBox(height: 14),

              // Match ID (optional)
              _label('Match ID (optional)'),
              TextFormField(
                controller: _matchIdCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Match reference ID'),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF00),
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
                              strokeWidth: 2,
                              color: Color(0xFF0A0E1A)),
                        )
                      : const Text(
                          'Submit Report',
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
          borderSide: const BorderSide(color: Color(0xFF00FF00)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
