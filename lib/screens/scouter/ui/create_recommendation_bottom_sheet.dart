import 'package:flutter/material.dart';

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
  final _orgIdCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _level = 'CONSIDER';
  bool _submitting = false;

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
  void dispose() {
    _orgIdCtrl.dispose();
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
        'organizationId': _orgIdCtrl.text.trim(),
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

              // Organization ID
              _label('Organization ID'),
              TextFormField(
                controller: _orgIdCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Organization ObjectId'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Organization ID is required';
                  }
                  return null;
                },
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
