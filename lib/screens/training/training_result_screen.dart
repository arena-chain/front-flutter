// lib/screens/training/training_result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/training_api_service.dart';
import '../../core/models/training_models.dart';
import 'training_dashboard_screen.dart';
import 'training_game_screen.dart';

// ─── COLOURS ──────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0A0D12);
const _surface = Color(0xFF111620);
const _card = Color(0xFF161C28);
const _accent = Color(0xFFE83B3B);
const _green = Color(0xFF3BE87B);
const _blue = Color(0xFF3B9EE8);
const _yellow = Color(0xFFE8C83B);
const _textPrimary = Color(0xFFEEEEEE);
const _textSecondary = Color(0xFF8896A8);
const _border = Color(0xFF1E2736);

class TrainingResultScreen extends StatefulWidget {
  final TrainingResult result;
  final TrainingApiService apiService;

  /// Optional: pass these if you want the "Play Again" flow to work without
  /// re-authenticating. If null, the user is sent back to the dashboard.
  final String? username;

  const TrainingResultScreen({
    super.key,
    required this.result,
    required this.apiService,
    this.username,
  });

  @override
  State<TrainingResultScreen> createState() => _TrainingResultScreenState();
}

class _TrainingResultScreenState extends State<TrainingResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  // ── Derived Stats ─────────────────────────────────────────────────────────
  double get _accuracy => widget.result.accuracy;
  double get _shotsPerSecond => widget.result.shotsPerSecond;
  double get _avgResponseTime => widget.result.avgResponseTime;
  int get _score => widget.result.score;
  int get _hits => widget.result.hits;
  int get _misses => widget.result.misses;
  int get _totalShots => widget.result.totalShots;

  String get _durationLabel {
    final mins = widget.result.duration ~/ 60;
    return '$mins MIN';
  }

  String get _difficulty => widget.result.difficulty;

  String get _grade {
    if (_accuracy >= 90) return 'S';
    if (_accuracy >= 75) return 'A';
    if (_accuracy >= 60) return 'B';
    if (_accuracy >= 45) return 'C';
    return 'D';
  }

  Color get _gradeColor {
    switch (_grade) {
      case 'S':
        return const Color(0xFFFFD700);
      case 'A':
        return _green;
      case 'B':
        return _blue;
      case 'C':
        return _yellow;
      default:
        return _accent;
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _playAgain() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TrainingGameScreen(
          duration: widget.result.duration,
          userId: widget.result.userId,
          apiService: widget.apiService,
          difficulty: widget.result.difficulty,
        ),
      ),
    );
  }

  void _backToDashboard() {
    // Pop back until we reach the dashboard or the first route
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildScoreCard(),
                        const SizedBox(height: 20),
                        _buildStatsGrid(),
                        const SizedBox(height: 20),
                        _buildShotBreakdown(),
                        const SizedBox(height: 36),
                        _buildActions(),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.my_location, color: _accent, size: 16),
            const SizedBox(width: 8),
            const Text(
              'SESSION COMPLETE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _textSecondary,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _border),
              ),
              child: Text(
                '$_difficulty / $_durationLabel',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _card,
            _card.withBlue(35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.06),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Grade circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gradeColor.withOpacity(0.12),
              border: Border.all(color: _gradeColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: _gradeColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _grade,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: _gradeColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'FINAL SCORE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_score',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
              height: 1,
            ),
          ),
          const Text(
            'POINTS',
            style: TextStyle(
              fontSize: 11,
              color: _textSecondary,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'ACCURACY',
            value: '${_accuracy.toStringAsFixed(1)}%',
            icon: Icons.gps_fixed,
            color: _accuracy >= 70 ? _green : _accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'SHOTS/SEC',
            value: _shotsPerSecond.toStringAsFixed(2),
            icon: Icons.flash_on,
            color: _blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'AVG REACT',
            value: '${_avgResponseTime.toStringAsFixed(0)}ms',
            icon: Icons.speed,
            color: _yellow,
          ),
        ),
      ],
    );
  }

  Widget _buildShotBreakdown() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SHOT BREAKDOWN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _buildBreakdownRow('Total Evaluation', '$_totalShots', _textPrimary),
          _buildBreakdownRow('Valid Hits', '$_hits', _green),
          _buildBreakdownRow('Penalized / Misses', '$_misses', _accent),
          _buildBreakdownRow('Max Combo', '${widget.result.maxCombo}', const Color(0xFFE8C83B)),
          const SizedBox(height: 12),
          // Accuracy bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_accuracy / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: _surface,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_accuracy >= 70 ? _green : _accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: _textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        // Play Again
        GestureDetector(
          onTap: _playAgain,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE83B3B), Color(0xFFB52020)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.replay, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'PLAY AGAIN',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Back to Dashboard
        GestureDetector(
          onTap: _backToDashboard,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.grid_view_rounded, color: _textSecondary, size: 18),
                SizedBox(width: 10),
                Text(
                  'BACK TO DASHBOARD',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textSecondary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: _textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
