import 'package:flutter/material.dart';

/// Center header wordmark: compact static neon type (no motion / chroma / bloom).
class ArenaChainAnimatedTitle extends StatelessWidget {
  const ArenaChainAnimatedTitle({
    super.key,
    this.fontSize = 17,
  });

  final double fontSize;

  static const Color _neon = Color(0xFF39FF14);
  static const String _label = 'Arena-Chain';

  @override
  Widget build(BuildContext context) {
    return Text(
      _label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: 0.6,
        color: _neon,
        shadows: [
          Shadow(
            color: _neon.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
