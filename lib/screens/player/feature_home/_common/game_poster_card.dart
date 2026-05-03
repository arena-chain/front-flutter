import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/models/linked_accounts/linked_game_account.dart';

// ignore: unused_element
const Color _kNeon = Color(0xFF39FF14);

/// Per-game brand accent color used for borders, glow, button outline,
/// page-indicator highlight, and loading spinner. Drives the visual
/// identity of each game card so the UI doesn't feel static.
Color gameAccentColor(LinkedGameId id) {
  switch (id) {
    case LinkedGameId.lol:
      return const Color(0xFF4DB8FF); // electric blue (Jinx-inspired)
    case LinkedGameId.valorant:
      return const Color(0xFFFF4655); // Valorant red
    case LinkedGameId.cs2:
      return const Color(0xFFFFA726); // warm amber/orange
    case LinkedGameId.dota2:
      return const Color(0xFF7CFF6B); // Dota 2 green
  }
}

String _bgPath(LinkedGameId id) {
  switch (id) {
    case LinkedGameId.lol:
      return 'assets/images/games/lol_bg.png';
    case LinkedGameId.valorant:
      return 'assets/images/games/valorant_bg.png';
    case LinkedGameId.cs2:
      return 'assets/images/games/cs2_bg.png';
    case LinkedGameId.dota2:
      return 'assets/images/games/dota2_bg.png';
  }
}

String _fallbackWordmark(LinkedGameId id) {
  switch (id) {
    case LinkedGameId.lol:
      return 'LEAGUE OF LEGENDS';
    case LinkedGameId.valorant:
      return 'VALORANT';
    case LinkedGameId.cs2:
      return 'COUNTER-STRIKE 2';
    case LinkedGameId.dota2:
      return 'DOTA 2';
  }
}

List<Color> _fallbackGradientColors(LinkedGameId id) {
  switch (id) {
    case LinkedGameId.lol:
      return const [Color(0xFF0A1F44), Color(0xFF0E2A66), Color(0xFF1F4FA8)];
    case LinkedGameId.valorant:
      return const [Color(0xFF1E0006), Color(0xFF6E0014), Color(0xFFCF1739)];
    case LinkedGameId.cs2:
      return const [Color(0xFF1A1A1A), Color(0xFF2C2C2C), Color(0xFF8A6A2A)];
    case LinkedGameId.dota2:
      return const [Color(0xFF050505), Color(0xFF11160B), Color(0xFF2E5C1F)];
  }
}

Widget _fallbackGradient(LinkedGameId id) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _fallbackGradientColors(id),
      ),
    ),
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(
      _fallbackWordmark(id),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 1.2,
        shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
      ),
    ),
  );
}

/// Full-bleed per-game poster for the home carousel (linked account + PLAY NOW).
class GamePosterCard extends StatelessWidget {
  const GamePosterCard({
    super.key,
    required this.account,
    required this.totalPages,
    required this.activePage,
    required this.isLoading,
    required this.onPlayNow,
    required this.onOpenStats,
    this.onLive,
  });

  final LinkedGameAccount account;
  final int totalPages;
  final int activePage;
  final bool isLoading;
  final VoidCallback onPlayNow;
  final VoidCallback onOpenStats;
  final VoidCallback? onLive;

  @override
  Widget build(BuildContext context) {
    final id = account.gameId;
    final path = _bgPath(id);
    final accent = gameAccentColor(id);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            path,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            cacheWidth: 720,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('[GamePosterCard] Failed to load $path: $error');
              return _fallbackGradient(id);
            },
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.15),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpenStats,
          ),
        ),
        if (onLive != null)
          Positioned(
            right: 14,
            bottom: 56,
            child: GestureDetector(
              onTap: onLive,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFC84B4B),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66C84B4B),
                      blurRadius: 12,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.fiber_manual_record, size: 10, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: 14,
          bottom: 14,
          child: GestureDetector(
            onTap: onPlayNow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent, width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: const Text(
                'PLAY NOW  >',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.4,
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Color(0xB3000000),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          bottom: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalPages, (i) {
              final active = i == activePage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 12 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? accent.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              color: Colors.black.withValues(alpha: 0.35),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              ),
            ),
          ),
      ],
    );
  }
}
