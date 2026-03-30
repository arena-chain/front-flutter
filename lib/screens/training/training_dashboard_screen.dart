// lib/screens/training/training_dashboard_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/training_api_service.dart';
import '../../core/models/training_models.dart';
import 'training_game_screen.dart';

// ─── COLOUR PALETTE ───────────────────────────────────────────────────────────
const _bg = Color(0xFF0A0D12);
const _surface = Color(0xFF111620);
const _card = Color(0xFF161C28);
const _accent = Color(0xFFE83B3B);
const _accentGlow = Color(0x44E83B3B);
const _gold = Color(0xFFFFD700);
const _silver = Color(0xFFC0C0C0);
const _bronze = Color(0xFFCD7F32);
const _textPrimary = Color(0xFFEEEEEE);
const _textSecondary = Color(0xFF8896A8);
const _border = Color(0xFF1E2736);

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
  String? _leaderboardError;
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
      _leaderboardError = null;
    });
    try {
      final data = await widget.apiService.getLeaderboard(
        limit: 20,
        duration: _selectedDuration,
        difficulty: _selectedDifficulty,
      );
      if (mounted) setState(() => _leaderboard = data);
    } catch (e) {
      if (mounted) setState(() => _leaderboardError = e.toString());
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
              _buildHeader(),
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

  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: _bg,
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _textSecondary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.my_location, color: _accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'TRAINING MODE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Sharpen your aim. Climb the ranks.',
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
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
            final color = diff == 'EASY' ? const Color(0xFF3BE87B) 
                        : diff == 'MEDIUM' ? const Color(0xFF3B9EE8) 
                        : _accent;
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
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.15) : _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? color : _border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      diff,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: selected ? color : _textSecondary,
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
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
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
          const SizedBox(height: 14),
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
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected ? _accent : _surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? _accent : _border,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: _accentGlow,
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                )
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        opt['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : _textSecondary,
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
          // PLAY button
          ScaleTransition(
            scale: _pulseAnimation,
            child: GestureDetector(
              onTap: _startGame,
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE83B3B), Color(0xFFB52020)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'PLAY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: _accent, size: 24),
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
                    color: _accent,
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
            const Icon(Icons.emoji_events, color: _gold, size: 18),
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
            GestureDetector(
              onTap: _fetchLeaderboard,
              child: const Icon(Icons.refresh, color: _textSecondary, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loadingLeaderboard)
          ...List.generate(5, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _shimmerCard(height: 64),
              ))
        else if (_leaderboardError != null)
          _buildErrorCard()
        else if (_leaderboard.isEmpty)
          _buildEmptyLeaderboard()
        else
          ..._leaderboard
              .asMap()
              .entries
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildLeaderboardRow(e.value),
                  ))
              .toList(),
      ],
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry) {
    final isMe = entry.userId == widget.currentUserId;
    Color rankColor;
    Widget rankWidget;

    if (entry.rank == 1) {
      rankColor = _gold;
      rankWidget =
          const Icon(Icons.emoji_events, color: _gold, size: 20);
    } else if (entry.rank == 2) {
      rankColor = _silver;
      rankWidget =
          const Icon(Icons.emoji_events, color: _silver, size: 20);
    } else if (entry.rank == 3) {
      rankColor = _bronze;
      rankWidget =
          const Icon(Icons.emoji_events, color: _bronze, size: 20);
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
        color: isMe ? _accent.withOpacity(0.12) : _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? _accent.withOpacity(0.4) : _border,
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
                    color: isMe ? _accent : _textPrimary,
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

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not load leaderboard. Tap to retry.',
              style: const TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _accent),
            onPressed: _fetchLeaderboard,
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
        borderRadius: BorderRadius.circular(12),
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
        color: _card,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
