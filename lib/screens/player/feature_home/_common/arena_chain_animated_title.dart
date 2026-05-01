import 'package:flutter/material.dart';

/// Header logo: rotates a single full 360° turn once on first mount, then stops.
class ArenaChainAnimatedTitle extends StatefulWidget {
  const ArenaChainAnimatedTitle({super.key, this.size = 36});

  final double size;

  @override
  State<ArenaChainAnimatedTitle> createState() =>
      _ArenaChainAnimatedTitleState();
}

class _ArenaChainAnimatedTitleState extends State<ArenaChainAnimatedTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _rotation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotation,
      child: Image.asset(
        'assets/images/logo_arena.png',
        height: widget.size,
        width: widget.size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            '[ArenaChainAnimatedTitle] Failed to load logo_arena.png: $error',
          );
          return SizedBox(width: widget.size, height: widget.size);
        },
      ),
    );
  }
}
