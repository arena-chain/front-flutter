import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  static const Color _accent = Color(0xFF39FF14);
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
          top: BorderSide(width: 1, color: _accent.withValues(alpha: 0.25)),
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
          // Scaffold gives bottom bar unbounded max height; without a fixed
          // height, Row + Expanded can expand and steal the whole screen.
          child: SizedBox(
            height: 64,
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
                      icon: Icons.view_carousel_outlined,
                      activeIcon: Icons.view_carousel_rounded,
                      label: 'Reels',
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
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_rounded,
                      label: 'Messages',
                      index: 4,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemW = (constraints.maxWidth - 4).clamp(48.0, 64.0);
        return SizedBox(
          width: itemW,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 22,
                height: 3,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: isSelected ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(top: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      resolvedIcon,
                      color: isSelected ? _accent : _muted,
                      size: isSelected ? 22 : 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? _accent : _muted,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
