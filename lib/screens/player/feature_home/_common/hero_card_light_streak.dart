import 'package:flutter/material.dart';

/// Full-screen diagonal accent sweep when [triggerKey] changes (e.g. carousel
/// index). [accentColor] should match the same animated accent as the rest of
/// the home chrome so the streak follows the color crossfade.
class HomeLightStreakOverlay extends StatefulWidget {
  const HomeLightStreakOverlay({
    super.key,
    required this.triggerKey,
    required this.accentColor,
    this.duration = const Duration(milliseconds: 1200),
  });

  final Object triggerKey;
  final Color accentColor;
  final Duration duration;

  @override
  State<HomeLightStreakOverlay> createState() => _HomeLightStreakOverlayState();
}

class _HomeLightStreakOverlayState extends State<HomeLightStreakOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(covariant HomeLightStreakOverlay old) {
    super.didUpdateWidget(old);
    if (old.triggerKey != widget.triggerKey) {
      _controller.forward(from: 0);
    }
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
      builder: (context, _) {
        final t = _controller.value;
        if (t <= 0.001 || t >= 0.999) {
          return const SizedBox.expand();
        }
        final eased = Curves.easeOutCubic.transform(t);
        return IgnorePointer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return CustomPaint(
                size: size,
                painter: _AccentSweepPainter(
                  progress: eased,
                  accent: widget.accentColor,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AccentSweepPainter extends CustomPainter {
  _AccentSweepPainter({
    required this.progress,
    required this.accent,
  });

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final start = -1.25 + 2.75 * progress;
    final glow = Color.lerp(accent, Colors.white, 0.45)!.withValues(alpha: 0.45);
    final core = accent.withValues(alpha: 0.28);
    final edge = accent.withValues(alpha: 0.06);

    final sweep = Paint()
      ..shader = LinearGradient(
        begin: Alignment(start, start * 0.88),
        end: Alignment(start + 1.05, start * 0.88 + 1.05),
        colors: [
          Colors.transparent,
          edge,
          core,
          glow,
          core,
          edge,
          Colors.transparent,
        ],
        stops: const [0.0, 0.34, 0.43, 0.5, 0.57, 0.66, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.softLight;

    canvas.drawRect(rect, sweep);

    final veil = Paint()
      ..shader = LinearGradient(
        begin: Alignment(start + 0.15, start * 0.88 + 0.12),
        end: Alignment(start + 0.85, start * 0.88 + 0.88),
        colors: [
          Colors.transparent,
          accent.withValues(alpha: 0.07),
          accent.withValues(alpha: 0.14),
          accent.withValues(alpha: 0.07),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.screen;

    canvas.drawRect(rect, veil);
  }

  @override
  bool shouldRepaint(covariant _AccentSweepPainter old) =>
      old.progress != progress || old.accent != accent;
}
