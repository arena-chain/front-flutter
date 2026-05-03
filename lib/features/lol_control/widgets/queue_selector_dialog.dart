// SPDX-License-Identifier: proprietary
// "Where will you play next?" picker shown when the player taps Play Now on
// the LoL game card. Coordinates Arena-Chain queue, LoL invite acceptance,
// and direct LoL Control queue.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/services/rift_service.dart';
import 'package:arena_chain_flutter/core/models/linked_accounts/linked_game_account.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_lobby_screen.dart';

const _kLolBlue = Color(0xFF4DB8FF);
const _kArenaGreen = Color(0xFF00FF00);
const _kBg = Color(0xFF0A0E1A);
const _kCard = Color(0xFF111827);
const _kBorder = Color(0xFF1F2A44);
const _kAccept = Color(0xFF44B37B);
const _kReject = Color(0xFFC84B4B);

Future<void> showQueueSelectorDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const _QueueSelectorDialog(),
  );
}

class _QueueSelectorDialog extends StatefulWidget {
  const _QueueSelectorDialog();
  @override
  State<_QueueSelectorDialog> createState() => _QueueSelectorDialogState();
}

class _QueueSelectorDialogState extends State<_QueueSelectorDialog> {
  // When true: middle row shows accept/refuse instead of chevron.
  bool _arenaArmed = false;

  @override
  Widget build(BuildContext context) {
    final rift = context.watch<RiftService>();
    final hasInvite = rift.receivedInvites.isNotEmpty;

    return Dialog(
      backgroundColor: _kBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Queue Selector',
              style: TextStyle(
                color: _kLolBlue,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Where will you play next? Select your battleground:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 18),

            // Row 1 — Queue on Arena-Chain
            _row(
              icon: Icons.shield_outlined,
              accent: _kArenaGreen,
              title: 'Queue on Arena-Chain',
              subtitle: 'Play in the general esports ecosystem.',
              trailing: _arenaArmed
                  ? const Icon(Icons.check_circle,
                      color: _kArenaGreen, size: 24)
                  : const Icon(Icons.chevron_right,
                      color: Colors.white54, size: 24),
              onTap: _onArenaChainTap,
            ),
            const SizedBox(height: 10),

            // Row 2 — Accept invite on LoL  (visible only when invite pending)
            if (hasInvite)
              _row(
                icon: Icons.mail_outline,
                accent: _kLolBlue,
                title: 'Accept invite on LoL?',
                subtitle: 'MOBILE INVITE RECEIVED',
                trailing: _arenaArmed
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Refuse',
                            icon: const Icon(Icons.close, color: _kReject),
                            onPressed: _onInviteRefuse,
                          ),
                          IconButton(
                            tooltip: 'Accept',
                            icon: const Icon(Icons.check, color: _kAccept),
                            onPressed: _onInviteAccept,
                          ),
                        ],
                      )
                    : const Icon(Icons.chevron_right,
                        color: Colors.white54, size: 24),
                onTap: null, // tapping the row itself does nothing in either state
              ),
            if (hasInvite) const SizedBox(height: 10),

            // Row 3 — Queue on LoL
            _row(
              icon: Icons.sports_esports_outlined,
              accent: _kLolBlue,
              title: 'Queue on LoL',
              subtitle: "Play on Summoner's Rift (Ranked / Normal).",
              trailing: const Icon(Icons.chevron_right,
                  color: Colors.white54, size: 24),
              onTap: _onQueueOnLol,
            ),

            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                    color: Colors.white60, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Row builder ──────────────────────────────────────────────

  Widget _row({
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11.5)),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  // ─── Workflow handlers ───────────────────────────────────────

  void _onArenaChainTap() {
    final rift = context.read<RiftService>();
    final hasInvite = rift.receivedInvites.isNotEmpty;

    // Spec: clicking Queue-on-Arena-Chain "highlights" the invite row's
    // accept/refuse icons. Clicking it AGAIN while the icons are shown
    // navigates to Matchmaking (= treats the click as the player choosing
    // Arena-Chain over the invite).
    if (hasInvite && !_arenaArmed) {
      setState(() => _arenaArmed = true);
      return;
    }
    _goToMatchmaking();
  }

  void _onInviteRefuse() {
    final rift = context.read<RiftService>();
    final invId = rift.receivedInvites.isNotEmpty
        ? (rift.receivedInvites.first['invitationId']?.toString() ?? '')
        : '';
    if (invId.isNotEmpty) {
      rift.sendLcuRequest(
        'POST',
        '/lol-lobby/v2/received-invitations/$invId/decline',
      );
    }
    _goToMatchmaking();
  }

  Future<void> _onInviteAccept() async {
    final rift = context.read<RiftService>();
    final invId = rift.receivedInvites.isNotEmpty
        ? (rift.receivedInvites.first['invitationId']?.toString() ?? '')
        : '';

    if (rift.isLolControlConnected) {
      if (invId.isNotEmpty) {
        rift.sendLcuRequest(
          'POST',
          '/lol-lobby/v2/received-invitations/$invId/accept',
        );
      }
      // Per spec: accept → directly to LoL matchmaking screen (== LolLobbyScreen,
      // which auto-routes to LolQueueScreen / ChampSelect / InGame as the
      // gameflow phase advances).
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const LolLobbyScreen()));
      return;
    }

    // Not connected: open LoL Access Control (pairing) screen INSIDE the dialog
    // (i.e. as a full-screen route on top). After it pops with a connected
    // status, push LobbyScreen.
    if (!mounted) return;
    Navigator.of(context).pop(); // close the selector first
    await Navigator.of(context).pushNamed(AppRoutes.lolControl);
    if (!mounted) return;
    final r = context.read<RiftService>();
    if (!r.isLolControlConnected) return;
    if (invId.isNotEmpty) {
      r.sendLcuRequest(
        'POST',
        '/lol-lobby/v2/received-invitations/$invId/accept',
      );
    }
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const LolLobbyScreen()));
  }

  void _onQueueOnLol() {
    final rift = context.read<RiftService>();
    Navigator.of(context).pop();
    if (rift.isLolControlConnected) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const LolLobbyScreen()));
    } else {
      Navigator.of(context).pushNamed(AppRoutes.lolControl);
    }
  }

  void _goToMatchmaking() {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(
      AppRoutes.matchmaking,
      arguments: LinkedGameId.lol,
    );
  }
}
