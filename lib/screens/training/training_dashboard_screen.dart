// lib/screens/training/training_dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/training_api_service.dart';
import '../../core/models/training_models.dart';
import 'training_game_screen.dart';

// ─── COLOUR PALETTE (single accent: neon green, matches Home / bottom nav) ───
const _bg = Color(0xFF000000);
const _surface = Color(0xFF14151C);
const _card = Color(0xFF1A1C23);
const _neon = Color(0xFF39FF14);
const _neonDeep = Color(0xFF1FA34A);
const _neonGlow = Color(0x5539FF14);
const _rank2 = Color(0xFF7AE582);
const _rank3 = Color(0xFF4CAF50);
const _textPrimary = Color(0xFFEEEEEE);
const _textSecondary = Color(0xFF8B95A5);
const _border = Color(0xFF2A2D36);

class TrainingDashboardScreen extends StatefulWidget {
  /// Inject the API service (or construct it here if you use a DI container).
  final TrainingApiService apiService;
  final String currentUserId;
  final String currentUsername;

  const TrainingDashboardScreen({
    super.key,
    required this.apiService,
    required this.currentUserId,
    required this.currentUsername,
  });

  @override
  State<TrainingDashboardScreen> createState() =>
      _TrainingDashboardScreenState();
}

class _TrainingDashboardScreenState extends State<TrainingDashboardScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  int _selectedDuration = 60; // seconds
  String _selectedDifficulty = 'MEDIUM'; // 'EASY', 'MEDIUM', 'HARD'
  List<LeaderboardEntry> _leaderboard = [];
  PersonalStats? _myStats;
  bool _loadingLeaderboard = true;
  bool _loadingStats = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _durationOptions = [
    {'label': '1 MIN', 'value': 60},
    {'label': '2 MIN', 'value': 120},
    {'label': '3 MIN', 'value': 180},
  ];

  final List<String> _difficultyOptions = ['EASY', 'MEDIUM', 'HARD'];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Data Loading ──────────────────────────────────────────────────────────
  Future<void> _fetchData() async {
    await Future.wait([_fetchLeaderboard(), _fetchMyStats()]);
  }

  Future<void> _fetchLeaderboard() async {
    if (!mounted) return;
    setState(() {
      _loadingLeaderboard = true;
    });
    try {
      final data = await widget.apiService.getLeaderboard(
        limit: 20,
        duration: _selectedDuration,
        difficulty: _selectedDifficulty,
      );
      if (mounted) setState(() => _leaderboard = data);
    } catch (_) {
      if (mounted) setState(() => _leaderboard = []);
    } finally {
      if (mounted) setState(() => _loadingLeaderboard = false);
    }
  }

  Future<void> _fetchMyStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);
    try {
      final stats = await widget.apiService.getMyStats(widget.currentUserId);
      if (mounted) setState(() => _myStats = stats);
    } catch (_) {
      // Personal stats failure is non-critical
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  Future<void> _startGame() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.of(context).push<TrainingResult>(
      MaterialPageRoute(
        builder: (_) => TrainingGameScreen(
          duration: _selectedDuration,
          userId: widget.currentUserId,
          apiService: widget.apiService,
          difficulty: _selectedDifficulty,
        ),
      ),
    );
    // After returning from game (result was submitted inside game screen)
    if (result != null && mounted) {
      _fetchData(); // Refresh leaderboard
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildHeaderSliver(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    _buildDifficultySection(),
                    const SizedBox(height: 20),
                    _buildPlaySection(),
                    const SizedBox(height: 32),
                    _buildMyRankCard(),
                    const SizedBox(height: 32),
                    _buildLeaderboardSection(),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSliver() {
    final canPop = Navigator.of(context).canPop();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _neon.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _neon.withValues(alpha: 0.35)),
                        boxShadow: [
                          BoxShadow(
                            color: _neon.withValues(alpha: 0.12),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.filter_center_focus, color: _neon, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'TRAINING MODE',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: _textPrimary,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Sharpen your aim. Climb the ranks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (canPop)
              Positioned(
                left: 0,
                top: 0,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: const Icon(Icons.arrow_back_ios_new, color: _textSecondary, size: 18),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DIFFICULTY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _textSecondary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _difficultyOptions.map((diff) {
            final selected = _selectedDifficulty == diff;
            const Color accentColor = _neon;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDifficulty = diff);
                    _fetchLeaderboard();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected ? accentColor.withValues(alpha: 0.14) : _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? accentColor : _border,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.22),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      diff,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: selected ? accentColor : _textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlaySection() {
    const accentColor = _neon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELECT DURATION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _textSecondary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _durationOptions.map((opt) {
            final selected = _selectedDuration == opt['value'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDuration = opt['value'] as int);
                    _fetchLeaderboard();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected ? accentColor.withValues(alpha: 0.14) : _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? accentColor : _border,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.22),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      opt['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: selected ? accentColor : _textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: _startGame,
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_neon, _neonDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _neonGlow,
                    blurRadius: 18,
                    spreadRadius: 0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'PLAY',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyRankCard() {
    if (_loadingStats) {
      return _shimmerCard(height: 90);
    }
    final personalBest = _myStats?.personalBests
        .where((b) => b.duration == _selectedDuration)
        .firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2818),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _neon.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.person_rounded, color: _neon.withValues(alpha: 0.95), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentUsername,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  personalBest != null
                      ? 'Best: ${personalBest.bestScore} pts  •  ${personalBest.totalSessions} sessions'
                      : 'No sessions yet for this duration',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_myStats?.globalRank != null)
            Column(
              children: [
                const Text(
                  'RANK',
                  style: TextStyle(
                      fontSize: 10, color: _textSecondary, letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${_myStats!.globalRank}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _neon,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: _neon.withValues(alpha: 0.9), size: 20),
            const SizedBox(width: 8),
            const Text(
              'LEADERBOARD',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _fetchLeaderboard,
              icon: Icon(Icons.refresh_rounded, color: _textSecondary.withValues(alpha: 0.85), size: 22),
              style: IconButton.styleFrom(
                backgroundColor: _surface,
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loadingLeaderboard)
          ...List.generate(5, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _shimmerCard(height: 64),
              ))
        else if (_leaderboard.isEmpty)
          _buildEmptyLeaderboard()
        else
          ..._leaderboard.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildLeaderboardRow(e),
            ),
          ),
      ],
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry) {
    final isMe = entry.userId == widget.currentUserId;
    Color rankColor;
    Widget rankWidget;

    if (entry.rank == 1) {
      rankColor = _neon;
      rankWidget = const Icon(Icons.emoji_events_rounded, color: _neon, size: 20);
    } else if (entry.rank == 2) {
      rankColor = _rank2;
      rankWidget = const Icon(Icons.emoji_events_rounded, color: _rank2, size: 20);
    } else if (entry.rank == 3) {
      rankColor = _rank3;
      rankWidget = const Icon(Icons.emoji_events_rounded, color: _rank3, size: 20);
    } else {
      rankColor = _textSecondary;
      rankWidget = Text(
        '#${entry.rank}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: rankColor,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isMe ? _neon.withValues(alpha: 0.08) : _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? _neon.withValues(alpha: 0.4) : _border,
          width: isMe ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 32, child: Center(child: rankWidget)),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundColor: _surface,
            backgroundImage: entry.avatar != null && entry.avatar!.isNotEmpty
                ? NetworkImage(entry.avatar!)
                : null,
            child: entry.avatar == null || entry.avatar!.isEmpty
                ? Text(
                    entry.username.isNotEmpty
                        ? entry.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${entry.username} (You)' : entry.username,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isMe ? _neon : _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${entry.accuracy.toStringAsFixed(1)}% acc  •  '
                  '${entry.avgResponseTime.toStringAsFixed(0)}ms',
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _textPrimary,
                ),
              ),
              const Text(
                'pts',
                style: TextStyle(fontSize: 10, color: _textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLeaderboard() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: const [
          Icon(Icons.leaderboard_outlined, color: _textSecondary, size: 40),
          SizedBox(height: 12),
          Text(
            'No sessions yet.\nBe the first on the board!',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _shimmerCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
    );
  }
}
