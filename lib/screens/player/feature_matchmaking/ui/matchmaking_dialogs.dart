import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:arena_chain_flutter/core/models/feature_matchmaking/ticket_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_matchmaking/view_model/matchmaking_view_model.dart';

/// Dialog that lets the player accept or decline a found match.
/// The countdown is computed from the server-side game creation time so
/// that it stays accurate regardless of when the dialog appeared.
/// If another player declines, a brief message is shown before the dialog
/// auto-dismisses.
class AcceptMatchDialog extends StatefulWidget {
  final MatchmakingViewModel vm;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  /// Called when the dialog self-closes because another player declined.
  final VoidCallback onDeclinedByOther;

  /// Server-side creation time of the game (used to sync the countdown).
  final DateTime? gameCreatedAt;

  const AcceptMatchDialog({
    super.key,
    required this.vm,
    required this.onAccept,
    required this.onDecline,
    required this.onDeclinedByOther,
    this.gameCreatedAt,
  });

  @override
  State<AcceptMatchDialog> createState() => _AcceptMatchDialogState();
}

class _AcceptMatchDialogState extends State<AcceptMatchDialog> {
  static const int _totalSeconds = 15;
  late int _remaining;
  Timer? _timer;
  bool _declinedByOther = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    // Compute the real remaining time from the server-side creation timestamp.
    if (widget.gameCreatedAt != null) {
      final elapsed =
          DateTime.now().toUtc().difference(widget.gameCreatedAt!).inSeconds;
      _remaining = (_totalSeconds - elapsed).clamp(0, _totalSeconds);
    } else {
      _remaining = _totalSeconds;
    }

    if (_remaining <= 0) {
      // Already expired by the time the dialog appeared — auto-decline.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_dismissed) widget.onDecline();
      });
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _declinedByOther) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _timer?.cancel();
        if (!_dismissed) widget.onDecline();
      }
    });

    // Listen for external cancellation (another player declined).
    widget.vm.addListener(_onVmChanged);
  }

  void _onVmChanged() {
    if (!mounted || _dismissed || _declinedByOther) return;

    final status = widget.vm.status;
    if (status == MatchmakingStatus.expired ||
        status == MatchmakingStatus.cancelled) {
      _timer?.cancel();
      setState(() => _declinedByOther = true);

      // Show the message for 2 seconds, then dismiss.
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_dismissed) {
          _dismissed = true;
          widget.onDeclinedByOther();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVmChanged);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / _totalSeconds;
    final color =
        _remaining <= 5 ? const Color(0xFFFF4444) : const Color(0xFF00FF00);

    // ── "Another player declined" overlay ──────────────────────────────────
    if (_declinedByOther) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0F1221),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFF4444), width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Color(0xFFFF4444)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Match Cancelled',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off, color: Color(0xFFFF4444), size: 48),
            SizedBox(height: 16),
            Text(
              'Another player declined the match.\nReturning to queue...',
              style: TextStyle(color: Color(0xFF7A86AC), fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // ── Normal accept / decline UI ────────────────────────────────────────
    return AlertDialog(
      backgroundColor: const Color(0xFF0F1221),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 1),
      ),
      title: const Row(
        children: [
          Icon(Icons.sports_esports, color: Color(0xFF00FF00)),
          SizedBox(width: 8),
          Text(
            'Match Found!',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mode: ${widget.vm.activeGame?.mode ?? widget.vm.selectedMode}',
            style: const TextStyle(color: Color(0xFF7A86AC)),
          ),
          const SizedBox(height: 4),
          Text(
            'Players: ${widget.vm.activeGame?.numberOfParticipant ?? "-"}',
            style: const TextStyle(color: Color(0xFF7A86AC)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: const Color(0xFF1A1F36),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Text(
                    '$_remaining',
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Do you want to accept this match?',
            style: TextStyle(color: Colors.white, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onDecline,
          child: const Text(
            'Decline',
            style: TextStyle(color: Color(0xFFFF4444)),
          ),
        ),
        ElevatedButton(
          onPressed: widget.onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FF00),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Accept',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global helper: show the Accept / Decline dialog on top of any screen
// ─────────────────────────────────────────────────────────────────────────────

void showMatchAcceptDialog({
  required BuildContext context,
  required MatchmakingViewModel vm,
  required VoidCallback onDismissed,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (ctx) => AcceptMatchDialog(
      vm: vm,
      gameCreatedAt: vm.activeGame?.createdAt,
      onAccept: () {
        Navigator.of(ctx, rootNavigator: true).pop();
        onDismissed();
        vm.acceptMatch();
      },
      onDecline: () {
        Navigator.of(ctx, rootNavigator: true).pop();
        onDismissed();
        vm.declineMatch();
      },
      onDeclinedByOther: () {
        Navigator.of(ctx, rootNavigator: true).pop();
        onDismissed();
      },
    ),
  ).then((_) => onDismissed());
}

// ─────────────────────────────────────────────────────────────────────────────
// Global helper: show the Room-Code bottom sheet on top of any screen
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Schedule conflict dialog — shown when an instant search conflicts with an
// upcoming scheduled game within the next 30 minutes.
// ─────────────────────────────────────────────────────────────────────────────

void showScheduleConflictDialog({
  required BuildContext context,
  required MatchmakingViewModel vm,
}) {
  final ticket = vm.conflictingTicket;
  if (ticket == null) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (ctx) => _ScheduleConflictDialog(
      ticket: ticket,
      onCancelAndSearch: () {
        Navigator.of(ctx, rootNavigator: true).pop();
        vm.cancelConflictAndSearch();
      },
      onWaitForScheduled: () {
        Navigator.of(ctx, rootNavigator: true).pop();
        vm.clearConflict();
      },
    ),
  );
}

class _ScheduleConflictDialog extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onCancelAndSearch;
  final VoidCallback onWaitForScheduled;

  const _ScheduleConflictDialog({
    required this.ticket,
    required this.onCancelAndSearch,
    required this.onWaitForScheduled,
  });

  String get _modeLabel {
    switch (ticket.mode) {
      case 'CUSTOM_1V1':
        return '1v1';
      case 'CUSTOM_2V2':
        return '2v2';
      case 'CUSTOM_5V5':
        return '5v5';
      default:
        return ticket.mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = ticket.scheduledAt != null
        ? DateFormat('EEE, MMM d  ·  HH:mm').format(ticket.scheduledAt!)
        : '—';

    final remaining = ticket.scheduledAt != null
        ? ticket.scheduledAt!.difference(DateTime.now())
        : Duration.zero;
    final mins = remaining.inMinutes;

    return AlertDialog(
      backgroundColor: const Color(0xFF0F1221),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF00CCFF), width: 1),
      ),
      title: const Row(
        children: [
          Icon(Icons.schedule, color: Color(0xFF00CCFF)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Scheduled Game Reminder',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF00CCFF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00CCFF).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.event, color: Color(0xFF00CCFF), size: 36),
                const SizedBox(height: 10),
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_modeLabel  ·  ${ticket.server}',
                  style: const TextStyle(
                    color: Color(0xFF7A86AC),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CCFF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Starts in ~$mins min',
                    style: const TextStyle(
                      color: Color(0xFF00CCFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You have a scheduled game coming up soon.\nWould you like to cancel it and search now, or wait for the scheduled match?',
            style: TextStyle(color: Color(0xFF7A86AC), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCancelAndSearch,
                icon: const Icon(Icons.search, size: 18),
                label: const Text(
                  'Cancel Scheduled & Search Now',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onWaitForScheduled,
                icon: const Icon(Icons.schedule, size: 18),
                label: const Text(
                  'Wait for Scheduled Game',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00CCFF),
                  side: const BorderSide(color: Color(0xFF00CCFF)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global helper: show the Room-Code bottom sheet on top of any screen
// ─────────────────────────────────────────────────────────────────────────────

void showRoomCodeSheet({
  required BuildContext context,
  required MatchmakingViewModel vm,
  required VoidCallback onDismissed,
}) {
  final roomId = vm.activeGame?.roomInfo?.roomId ?? '';
  final map = vm.activeGame?.roomInfo?.map ?? "Summoner's Rift";

  showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (_, scrollController) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0F1221),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F36),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(
                  Icons.check_circle, color: Color(0xFF00FF00), size: 56),
              const SizedBox(height: 12),
              const Text(
                'Room Ready',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Room ID',
                style: TextStyle(color: Color(0xFF7A86AC), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F36),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00FF00).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  roomId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: roomId));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Room ID copied!'),
                      backgroundColor: Color(0xFF00FF00),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Room ID'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF00),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Map: $map',
                style:
                    const TextStyle(color: Color(0xFF7A86AC), fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Open LoL on your PC > Join Custom Game > use this ID as the room name.',
                        style: TextStyle(
                            color: Colors.orangeAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx, rootNavigator: true).pop();
                    onDismissed();
                    vm.resetState();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF1A1F36)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  ).then((_) => onDismissed());
}
