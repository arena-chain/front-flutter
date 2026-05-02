import 'package:flutter/material.dart';

const _kSurface = Color(0xFF111827);
const _kGold = Color(0xFFC89B3C);
const _kRed = Color(0xFFE05B5B);

/// Compact invite card that drops into the same 90px slot used by the
/// game-mode tiles in the create-lobby grid.
///
/// Shows the inviter's name, the queue label derived from gameConfig, and
/// Accept / Decline actions. Accept/Decline are wired in by the parent
/// (LolLobbyScreen) so this widget stays purely presentational.
class ReceivedInviteCard extends StatelessWidget {
  final String fromName;
  final String queueLabel;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool busy;

  const ReceivedInviteCard({
    super.key,
    required this.fromName,
    required this.queueLabel,
    required this.onAccept,
    required this.onDecline,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGold.withValues(alpha: 0.7), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: _kGold.withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline, color: _kGold, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Invite from $fromName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  queueLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RoundIconBtn(
            icon: Icons.close,
            color: _kRed,
            onTap: busy ? null : onDecline,
            tooltip: 'Decline',
          ),
          const SizedBox(width: 6),
          _RoundIconBtn(
            icon: Icons.check,
            color: _kGold,
            filled: true,
            onTap: busy ? null : onAccept,
            tooltip: 'Accept',
          ),
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;
  final String tooltip;

  const _RoundIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final bg = filled ? color.withValues(alpha: disabled ? 0.25 : 1.0) : Colors.transparent;
    final fg = filled ? Colors.black : color.withValues(alpha: disabled ? 0.4 : 1.0);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: filled ? null : Border.all(color: color.withValues(alpha: disabled ? 0.4 : 0.85), width: 1.4),
            ),
            child: Icon(icon, size: 18, color: fg),
          ),
        ),
      ),
    );
  }
}
