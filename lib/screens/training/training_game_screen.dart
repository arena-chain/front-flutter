// lib/screens/training/training_game_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/api/training_api_service.dart';
import '../../core/models/training_models.dart';
import 'training_result_screen.dart';

// ─── CONSTANTS ────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0A0D12);
const _surface = Color(0xFF111620);
const _accent = Color(0xFFE83B3B);
const _accentGlow = Color(0x66E83B3B);
const _targetColor = Color(0xFFE83B3B);
const _targetRing = Color(0xFFFF6B6B);
const _textPrimary = Color(0xFFEEEEEE);
const _textSecondary = Color(0xFF8896A8);

const double _kBottomSafeArea = 20.0;

class _GameConfig {
  final double minRadius;
  final double maxRadius;
  final int lifetimeMs;
  final int spawnIntervalMs;
  final double penaltyChance;
  final int comboTimeoutMs;

  const _GameConfig({
    required this.minRadius,
    required this.maxRadius,
    required this.lifetimeMs,
    required this.spawnIntervalMs,
    required this.penaltyChance,
    required this.comboTimeoutMs,
  });

  static _GameConfig fromDifficulty(String diff) {
    if (diff == 'EASY') {
      return const _GameConfig(
        minRadius: 30.0,
        maxRadius: 50.0,
        lifetimeMs: 1500,
        spawnIntervalMs: 800,
        penaltyChance: 0.0,
        comboTimeoutMs: 3000,
      );
    } else if (diff == 'HARD') {
      return const _GameConfig(
        minRadius: 16.0,
        maxRadius: 30.0,
        lifetimeMs: 600,
        spawnIntervalMs: 400,
        penaltyChance: 0.35,
        comboTimeoutMs: 1000,
      );
    }
    // Default MEDIUM
    return const _GameConfig(
      minRadius: 20.0,
      maxRadius: 40.0,
      lifetimeMs: 1000,
      spawnIntervalMs: 600,
      penaltyChance: 0.20,
      comboTimeoutMs: 1800,
    );
  }
}

class _Target {
  final String id;
  final double x; // center x
  final double y; // center y
  final double radius;
  final int spawnedAt; // DateTime.now().millisecondsSinceEpoch
  final bool isPenalty;
  final int lifetimeMs;

  bool isAlive = true;

  _Target({
    required this.id,
    required this.x,
    required this.y,
    required this.radius,
    required this.spawnedAt,
    required this.isPenalty,
    required this.lifetimeMs,
  });

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch - spawnedAt > lifetimeMs;

  double get aliveRatio {
    final elapsed =
        DateTime.now().millisecondsSinceEpoch - spawnedAt;
    return 1.0 - (elapsed / lifetimeMs).clamp(0.0, 1.0);
  }
}

class TrainingGameScreen extends StatefulWidget {
  final int duration; // seconds
  final String userId;
  final TrainingApiService apiService;
  final String difficulty;

  const TrainingGameScreen({
    super.key,
    required this.duration,
    required this.userId,
    required this.apiService,
    required this.difficulty,
  });

  @override
  State<TrainingGameScreen> createState() => _TrainingGameScreenState();
}

class _TrainingGameScreenState extends State<TrainingGameScreen>
    with TickerProviderStateMixin {
  // ── Game State ────────────────────────────────────────────────────────────
  final _random = Random();
  final List<_Target> _targets = [];
  final List<int> _reactionTimes = []; // ms per hit

  int _timeRemaining = 0;
  int _score = 0;
  int _hits = 0;
  int _misses = 0; // tap misses
  int _expiredTargets = 0; // targets that disappeared without being hit
  bool _gameStarted = false;
  bool _gameOver = false;
  bool _resultSubmitted = false;

  // ── Combo Systems ─────────────────────────────────────────────────────────
  int _comboCount = 0;
  int _maxCombo = 0;
  double _comboMultiplier = 1.0;
  int _lastHitTime = 0;
  bool _showComboBreak = false;
  Timer? _comboBreakTimer;

  // ── Timers & Controllers ──────────────────────────────────────────────────
  Timer? _countdownTimer;
  Timer? _targetSpawnTimer;
  Timer? _targetExpiryTimer;
  late AnimationController _countdownAnimController;

  // ── Hit feedback animations (ripples) ────────────────────────────────────
  final List<Map<String, dynamic>> _ripples = [];

  // ── Layout ────────────────────────────────────────────────────────────────
  Size _gameAreaSize = Size.zero;
  static const double _kTopBarHeight = 80.0;
  static const double _kBottomSafeArea = 20.0;

  // ── Audio ─────────────────────────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundMuted = false;

  late final _GameConfig _config;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.duration;
    _config = _GameConfig.fromDifficulty(widget.difficulty);
    _countdownAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    // Audio preloading
    _audioPlayer.setSource(AssetSource('sounds/shoot.mp3'));

    // Start game after a short delay so layout is computed
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _targetSpawnTimer?.cancel();
    _targetExpiryTimer?.cancel();
    _comboBreakTimer?.cancel();
    _countdownAnimController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Game Logic ─────────────────────────────────────────────────────────────
  void _breakCombo() {
    if (_comboCount > 0 || _comboMultiplier > 1.0) {
      if (mounted) {
        setState(() {
          _comboCount = 0;
          _comboMultiplier = 1.0;
          _showComboBreak = true;
        });
      }
      _comboBreakTimer?.cancel();
      _comboBreakTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _showComboBreak = false);
        }
      });
    }
  }

  void _startGame() {
    if (!mounted) return;
    setState(() => _gameStarted = true);

    // Countdown timer (1-second ticks)
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _onTimerTick());

    // Target spawn timer
    _targetSpawnTimer = Timer.periodic(
      Duration(milliseconds: _config.spawnIntervalMs),
      (_) => _spawnTarget(),
    );

    // Target expiry checker
    _targetExpiryTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _checkExpiredTargets(),
    );

    // Spawn first target immediately
    _spawnTarget();
  }

  void _onTimerTick() {
    if (!mounted || _gameOver) return;
    setState(() => _timeRemaining--);
    if (_timeRemaining <= 0) {
      _endGame();
    }
  }

  void _spawnTarget() {
    if (_gameOver || !mounted || _gameAreaSize == Size.zero) return;

    final radius = _config.minRadius +
        _random.nextDouble() * (_config.maxRadius - _config.minRadius);

    final maxX = _gameAreaSize.width - radius;
    final maxY = _gameAreaSize.height - radius;

    if (maxX <= radius || maxY <= radius) return;

    final isPenalty = _random.nextDouble() < _config.penaltyChance;

    final target = _Target(
      id: '${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(9999)}',
      x: radius + _random.nextDouble() * (maxX - radius),
      y: radius + _random.nextDouble() * (maxY - radius),
      radius: radius,
      spawnedAt: DateTime.now().millisecondsSinceEpoch,
      isPenalty: isPenalty,
      lifetimeMs: _config.lifetimeMs,
    );

    setState(() => _targets.add(target));
  }

  void _checkExpiredTargets() {
    if (_gameOver || !mounted) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_comboCount > 0 && now - _lastHitTime > _config.comboTimeoutMs) {
      _breakCombo();
    }

    final expiredIds = _targets
        .where((t) => t.isAlive && t.isExpired)
        .map((t) => t.id)
        .toList();

    if (expiredIds.isNotEmpty) {
      setState(() {
        for (final id in expiredIds) {
          final t = _targets.firstWhere((t) => t.id == id, orElse: () =>
              _Target(id: id, x: 0, y: 0, radius: 0, spawnedAt: 0, isPenalty: false, lifetimeMs: 1000));
          t.isAlive = false;
          if (!t.isPenalty) {
            _expiredTargets++;
            _breakCombo();
          }
        }
        _targets.removeWhere((t) => !t.isAlive);
      });
    }
  }

  void _onTargetHit(_Target target, Offset tapPos) {
    if (_gameOver || !mounted) return;
    HapticFeedback.lightImpact();

    final now = DateTime.now().millisecondsSinceEpoch;
    final reactionTime = now - target.spawnedAt;

    debugPrint('HIT TARGET => Tap: $tapPos | Target ID: ${target.id} | Center: (${target.x}, ${target.y}) | TRIGGERING GREEN CIRCLE');

    if (!_isSoundMuted) {
      _audioPlayer.stop().then((_) {
        _audioPlayer.play(AssetSource('sounds/shoot.mp3')).catchError((e) {
          debugPrint('Audio Play Error: $e');
        });
      });
    }

    setState(() {
      target.isAlive = false;
      _targets.remove(target);

      if (target.isPenalty) {
        _misses++;
        int penaltyAmount = widget.difficulty == 'HARD' ? 20 : 10;
        _score = max(0, _score - penaltyAmount);
        _breakCombo();

        _ripples.add({
          'id': UniqueKey().toString(),
          'x': target.x,
          'y': target.y,
          'time': now,
          'isPenalty': true,
        });
      } else {
        _hits++;
        _comboCount++;
        if (_comboCount > _maxCombo) _maxCombo = _comboCount;
        _lastHitTime = now;

        if (_comboCount >= 40) _comboMultiplier = 4.0;
        else if (_comboCount >= 20) _comboMultiplier = 3.0;
        else if (_comboCount >= 10) _comboMultiplier = 2.0;
        else if (_comboCount >= 5) _comboMultiplier = 1.5;
        else _comboMultiplier = 1.0;

        final basePoints = _calculateScore(reactionTime, target.radius);
        _score += (basePoints * _comboMultiplier).toInt();
        _reactionTimes.add(reactionTime);

        // Add regular ripple feedback
        _ripples.add({
          'id': UniqueKey().toString(),
          'x': target.x,
          'y': target.y,
          'time': now,
          'isPenalty': false,
        });
      }
    });

    // Clean up ripple after animation
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        setState(() => _ripples.removeWhere(
            (r) => currentTime - (r['time'] as int) >= 350));
      }
    });
  }

  void _onMissTap() {
    if (_gameOver || !mounted) return;
    setState(() {
      _misses++;
      _breakCombo();
    });
  }

  int _calculateScore(int reactionMs, double radius) {
    // Faster reaction and smaller target = more points
    final speedBonus = (1000 - reactionMs.clamp(0, 1000)) ~/ 10;
    final sizeBonus = ((_config.maxRadius - radius) / _config.maxRadius * 50)
        .toInt();
    return 10 + speedBonus + sizeBonus;
  }

  void _endGame() {
    if (_gameOver) return; // prevent double calls
    _countdownTimer?.cancel();
    _targetSpawnTimer?.cancel();
    _targetExpiryTimer?.cancel();

    setState(() {
      _gameOver = true;
      _targets.clear();
    });

    // Submit results after a brief pause so the "0" shows on screen
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _submitAndNavigate();
    });
  }

  Future<void> _submitAndNavigate() async {
    if (_resultSubmitted) return;
    _resultSubmitted = true;

    final totalShots = _hits + _misses;
    final accuracy =
        totalShots > 0 ? (_hits / totalShots) * 100 : 0.0;
    final shotsPerSecond = totalShots / widget.duration;
    final avgResponseTime = _reactionTimes.isNotEmpty
        ? _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length
        : 0.0;

    final result = TrainingResult(
      userId: widget.userId,
      score: _score,
      accuracy: accuracy,
      shotsPerSecond: shotsPerSecond,
      avgResponseTime: avgResponseTime,
      duration: widget.duration,
      difficulty: widget.difficulty,
      totalShots: totalShots,
      hits: _hits,
      misses: _misses + _expiredTargets,
      maxCombo: _maxCombo,
    );

    // Try to submit; failure is non-fatal – user can still see their result
    try {
      await widget.apiService.saveResult(result);
    } catch (e) {
      debugPrint('Save Result Error: $e');
    }

    if (mounted) {
      // Replace current route with result screen, PASSING result back to dashboard
      // to trigger auto-refresh.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TrainingResultScreen(
            result: result,
            apiService: widget.apiService,
          ),
        ),
        result: result,
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHUD(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _gameAreaSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight - _kBottomSafeArea,
                    );
                    return _buildGameArea();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHUD() {
    final timerColor = _timeRemaining <= 10 ? _accent : _textPrimary;

    return Container(
      height: _kTopBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1E2736), width: 1),
        ),
      ),
      child: Row(
        children: [
          // SCORE & MUTE
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isSoundMuted ? Icons.volume_off : Icons.volume_up,
                    color: _isSoundMuted ? _accent : _textSecondary,
                    size: 22,
                  ),
                  onPressed: () => setState(() => _isSoundMuted = !_isSoundMuted),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SCORE',
                      style: TextStyle(
                        fontSize: 10,
                        color: _textSecondary,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_score',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: _textPrimary,
                          ),
                        ),
                        if (_comboMultiplier > 1.0)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              'x${_comboMultiplier.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _comboMultiplier >= 4.0 ? const Color(0xFFE83B3B)
                                     : _comboMultiplier >= 3.0 ? const Color(0xFFE8C83B)
                                     : const Color(0xFF3B9EE8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TIMER (centre)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: timerColor,
                  shadows: _timeRemaining <= 10
                      ? [
                          Shadow(
                            color: _accent.withOpacity(0.6),
                            blurRadius: 20,
                          )
                        ]
                      : [],
                ),
                child: Text('$_timeRemaining'),
              ),
              const Text(
                'SEC',
                style: TextStyle(
                  fontSize: 10,
                  color: _textSecondary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          // HITS / MISSES
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF3BE87B), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$_hits',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3BE87B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.cancel, color: _accent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${_misses + _expiredTargets}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final tapPos = details.localPosition;
        debugPrint('TAP DETECTED => Position: $tapPos');
        
        // Check if any target was hit
        bool hitSomething = false;
        for (final target in List.from(_targets)) {
          if (!target.isAlive) continue; // Only check alive targets
          final dx = tapPos.dx - target.x;
          final dy = tapPos.dy - target.y;
          final dist = sqrt(dx * dx + dy * dy);
          
          // Strict click validation, no 8px forgiveness
          if (dist <= target.radius) {
            _onTargetHit(target, tapPos);
            hitSomething = true;
            break;
          }
        }
        
        if (!hitSomething) {
          debugPrint('MISS TARGET => Tap: $tapPos');
          _onMissTap();
        }
      },
      child: Stack(
        children: [
          // Subtle crosshair grid background
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(),
          ),

          // COMBO INDICATOR WATERMARK
          Center(
            child: IgnorePointer(
              child: _buildComboIndicator(),
            ),
          ),

          // Targets
          ..._targets.map((t) => _buildTarget(t)),

          // Hit ripples
          ..._ripples.map((r) => _buildRipple(r)),

          // Game over overlay
          if (_gameOver) _buildGameOverOverlay(),
        ],
      ),
    );
  }

  Widget _buildComboIndicator() {
    if (_showComboBreak) {
      return TweenAnimationBuilder<double>(
        key: const ValueKey('combo_break'),
        tween: Tween(begin: 1.2, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: const Text(
            'COMBO BREAK',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Color(0xAAE83B3B),
              shadows: [Shadow(color: Colors.redAccent, blurRadius: 20)],
            ),
          ),
        ),
      );
    }

    if (_comboCount < 5) return const SizedBox.shrink();

    Color comboColor = Colors.white;
    if (_comboMultiplier >= 4.0) comboColor = const Color(0xFFE83B3B);
    else if (_comboMultiplier >= 3.0) comboColor = const Color(0xFFE8C83B);
    else if (_comboMultiplier >= 2.0) comboColor = const Color(0xFF3B9EE8);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        ),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Text(
        '$_comboCount COMBO (x${_comboMultiplier.toStringAsFixed(1)})',
        key: ValueKey(_comboCount),
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: comboColor.withOpacity(0.15),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildTarget(_Target target) {
    return Positioned(
      key: ValueKey('target_${target.id}'),
      left: target.x - target.radius,
      top: target.y - target.radius,
      width: target.radius * 2,
      height: target.radius * 2,
      child: _TargetWidget(target: target),
    );
  }

  Widget _buildRipple(Map<String, dynamic> ripple) {
    return Positioned(
      key: ValueKey('ripple_${ripple['id']}'),
      left: (ripple['x'] as double) - 40,
      top: (ripple['y'] as double) - 40,
      width: 80,
      height: 80,
      child: _RippleEffect(isPenalty: ripple['isPenalty'] as bool? ?? false),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(color: _accent),
          SizedBox(height: 16),
          Text(
            'Calculating results...',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Target Widget ─────────────────────────────────────────────────────────────
class _TargetWidget extends StatefulWidget {
  final _Target target;
  const _TargetWidget({required this.target});

  @override
  State<_TargetWidget> createState() => _TargetWidgetState();
}

class _TargetWidgetState extends State<_TargetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: CustomPaint(
        painter: _TargetPainter(aliveRatio: widget.target.aliveRatio, isPenalty: widget.target.isPenalty),
      ),
    );
  }
}

class _TargetPainter extends CustomPainter {
  final double aliveRatio;
  final bool isPenalty;
  _TargetPainter({required this.aliveRatio, required this.isPenalty});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final alpha = (aliveRatio * 255).toInt().clamp(60, 255);

    final baseColor = isPenalty ? const Color(0xFFE83B3B) : const Color(0xFF3BE87B);
    final ringColor = isPenalty ? const Color(0xFFFF6B6B) : const Color(0xFF6BFF9A);

    // Outer glow
    final glowPaint = Paint()
      ..color = baseColor.withAlpha((alpha * 0.3).toInt())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, outerRadius * 1.2, glowPaint);

    // Outer ring (fades as target ages)
    final outerPaint = Paint()
      ..color = ringColor.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, outerRadius - 2, outerPaint);

    // Middle ring
    final midPaint = Paint()
      ..color = baseColor.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, outerRadius * 0.6, midPaint);

    // Inner filled dot
    final innerPaint = Paint()
      ..color = baseColor.withAlpha(alpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius * 0.2, innerPaint);

    // Countdown arc (shrinks as target expires)
    final arcPaint = Paint()
      ..color = baseColor.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius - 2),
      -pi / 2,
      2 * pi * aliveRatio,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_TargetPainter oldDelegate) =>
      oldDelegate.aliveRatio != aliveRatio || oldDelegate.isPenalty != isPenalty;
}

// ─── Ripple Effect ────────────────────────────────────────────────────────────
class _RippleEffect extends StatefulWidget {
  final bool isPenalty;
  const _RippleEffect({required this.isPenalty});

  @override
  State<_RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<_RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isPenalty ? const Color(0xFFE83B3B) : const Color(0xFF3BE87B),
                width: 2.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Background Grid ──────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2030)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Centre crosshair
    final crossPaint = Paint()
      ..color = const Color(0xFF2A3545)
      ..strokeWidth = 1;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx - 12, cy), Offset(cx + 12, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - 12), Offset(cx, cy + 12), crossPaint);
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
