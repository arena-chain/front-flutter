import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  static const Color _accent = Color(0xFF39FF14);
  static const Color _slotBg = Color(0xFF0A0A0A);
  static const Color _muted = Color(0xFF5C6570);

  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            width: 1,
            color: _accent.withValues(alpha: 0.25),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          // Scaffold gives bottom bar unbounded max height; without a fixed
          // height, Row + Expanded can expand and steal the whole screen.
          child: SizedBox(
            height: 58,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _navTapSlot(
                    index: 0,
                    child: _buildNavPill(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      index: 0,
                    ),
                  ),
                ),
                Expanded(
                  child: _navTapSlot(
                    index: 1,
                    child: _buildNavPill(
                      icon: Icons.podcasts_outlined,
                      label: 'Live',
                      index: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: _navTapSlot(
                    index: 2,
                    child: _buildNavPill(
                      icon: Icons.shield_outlined,
                      activeIcon: Icons.shield_rounded,
                      label: 'Leagues',
                      index: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: _navTapSlot(
                    index: 3,
                    child: _buildNavPill(
                      icon: Icons.emoji_events_outlined,
                      label: 'Tournaments',
                      index: 3,
                    ),
                  ),
                ),
                Expanded(
                  child: _navTapSlot(
                    index: 4,
                    child: _buildNavPill(
                      icon: Icons.fitness_center_outlined,
                      label: 'Training',
                      index: 4,
                    ),
                  ),
                ),
                Expanded(
                  child: _navTapSlot(
                    index: 5,
                    child: _buildNavPill(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_rounded,
                      label: 'Messages',
                      index: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Full-cell tap target; keeps the pill visually compact and centered.
  Widget _navTapSlot({required int index, required Widget child}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: _accent.withValues(alpha: 0.1),
        highlightColor: _accent.withValues(alpha: 0.05),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildNavPill({
    required IconData icon,
    IconData? activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    final IconData resolvedIcon = isSelected ? (activeIcon ?? icon) : icon;

    const double iconBase = 26.0;
    final iconScale = isSelected ? 1.0 : 18.0 / iconBase;
    final labelSize = isSelected ? 9.5 : 7.5;
    final borderAlpha = isSelected ? 0.72 : 0.14;
    final fillAlpha = isSelected ? 0.14 : 0.0;

    // Same width + stadium radius for every tab so long labels (e.g. Tournaments)
    // don't become a "rounded square" while others stay pill-shaped.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillW = (constraints.maxWidth - 4).clamp(46.0, 58.0);
          return SizedBox(
            width: pillW,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: fillAlpha > 0
                    ? _accent.withValues(alpha: fillAlpha)
                    : _slotBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _accent.withValues(alpha: borderAlpha),
                  width: isSelected ? 1.65 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.38),
                          blurRadius: 14,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.18),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: iconScale,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    child: Icon(
                      resolvedIcon,
                      color: isSelected ? _accent : _muted,
                      size: iconBase,
                    ),
                  ),
                  SizedBox(height: isSelected ? 4 : 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: isSelected ? _accent : _muted,
                      fontSize: labelSize,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      height: 1.05,
                      letterSpacing: isSelected ? 0.15 : 0,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
