import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Center header logo: letter wave + slow chromatic split + pulsing bloom (gaming HUD).
class ArenaChainAnimatedTitle extends StatefulWidget {
  const ArenaChainAnimatedTitle({
    super.key,
    this.fontSize = 22,
  });

  final double fontSize;

  @override
  State<ArenaChainAnimatedTitle> createState() => _ArenaChainAnimatedTitleState();
}

class _ArenaChainAnimatedTitleState extends State<ArenaChainAnimatedTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  static const Color _neon = Color(0xFF39FF14);
  static const String _label = 'Arena-Chain';

  /// Cyan / magenta accents for a subtle “holographic” split (low opacity).
  static const Color _chromaCyan = Color(0xFF00E5FF);
  static const Color _chromaMagenta = Color(0xFFFF2D95);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 0.35;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle get _glyphStyle => TextStyle(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w800,
        height: 1.0,
      );

  double _waveDy(double t, int index) =>
      2.4 * math.sin(2 * math.pi * t * 1.18 + index * 0.56);

  /// How far RGB “ghosts” drift apart (0…1), slow breathe.
  double _chromaAmount(double t) =>
      0.35 + 0.65 * math.pow((math.sin(2 * math.pi * t * 0.42) + 1) * 0.5, 1.2);

  Widget _letterRow(
    double t, {
    required Color color,
    required double opacity,
    Offset chromaShift = Offset.zero,
    List<Shadow> shadows = const [],
  }) {
    final chars = _label.split('');
    const gap = 0.65;

    return Transform.translate(
      offset: chromaShift,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < chars.length; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            Transform.translate(
              offset: Offset(0, _waveDy(t, i)),
              child: Text(
                chars[i],
                style: _glyphStyle.copyWith(
                  color: color.withValues(alpha: opacity),
                  shadows: shadows,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final pulse = 0.55 + 0.45 * math.sin(2 * math.pi * t);
          final chroma = _chromaAmount(t);
          final split = 1.15 * widget.fontSize * 0.045 * chroma;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Cyan ghost (left)
              _letterRow(
                t,
                color: _chromaCyan,
                opacity: 0.32 * chroma,
                chromaShift: Offset(-split, 0),
              ),
              // Magenta ghost (right)
              _letterRow(
                t,
                color: _chromaMagenta,
                opacity: 0.28 * chroma,
                chromaShift: Offset(split, 0),
              ),
              // Core glyph + neon bloom
              _letterRow(
                t,
                color: _neon,
                opacity: 1,
                shadows: [
                  Shadow(
                    color: _neon.withValues(alpha: 0.72 * pulse),
                    blurRadius: 10 * pulse,
                  ),
                  Shadow(
                    color: _neon.withValues(alpha: 0.42 * pulse),
                    blurRadius: 22 * pulse,
                  ),
                  Shadow(
                    color: _neon.withValues(alpha: 0.2 * pulse),
                    blurRadius: 36 * pulse,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
