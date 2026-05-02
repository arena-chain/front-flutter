import 'dart:ui';

import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  static const Color _activeColor = Color(0xFFB3B3B3);
  static const Color _inactiveColor = Color(0xFF717171);
  static const Color _glassTopBorder = Color(0xFF2A2A2A);

  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _glassTopBorder,
                  width: 1,
                ),
              ),
              child: SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
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
        splashColor: _activeColor.withValues(alpha: 0.10),
        highlightColor: _activeColor.withValues(alpha: 0.05),
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
    final Color tint = isSelected ? _activeColor : _inactiveColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          resolvedIcon,
          color: tint,
          size: isSelected ? 22 : 20,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tint,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            height: 1,
          ),
        ),
      ],
    );
  }
}
