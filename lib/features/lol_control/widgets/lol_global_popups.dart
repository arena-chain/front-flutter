// SPDX-License-Identifier: proprietary
// Global driver that listens to [RiftService] and shows a single ambient
// dialog: an "Invite received" popup any time a new LoL lobby invitation
// lands while LoL Control is connected. The "Live match detected" popup
// has been intentionally removed in favor of the dedicated LIVE button on
// the LoL game card on the home carousel.
//
// IMPORTANT: this widget is mounted via [MaterialApp.builder], which means
// it lives ABOVE the [Navigator]. We CANNOT use this widget's [BuildContext]
// for [showDialog] / [Navigator.push] — there is no ancestor Navigator from
// here. Instead we go through [rootNavigatorKey] (declared in navigation.dart),
// which gives us a context where the Navigator IS the StatefulElement.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:arena_chain_flutter/navigation.dart' show rootNavigatorKey;
import 'package:arena_chain_flutter/services/rift_service.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_lobby_screen.dart';

const _kLolBlue = Color(0xFF4DB8FF);
const _kSurface = Color(0xFF111827);
const _kAccept = Color(0xFF44B37B);
const _kReject = Color(0xFFC84B4B);

class LolGlobalPopups extends StatefulWidget {
  final Widget child;
  const LolGlobalPopups({super.key, required this.child});

  @override
  State<LolGlobalPopups> createState() => _LolGlobalPopupsState();
}

class _LolGlobalPopupsState extends State<LolGlobalPopups> {
  RiftService? _rift;
  final Set<String> _shownInviteIds = <String>{};
  bool _inviteDialogOpen = false;
  bool _wasConnected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = context.read<RiftService>();
    if (!identical(r, _rift)) {
      _rift?.removeListener(_onRiftChanged);
      _rift = r;
      _rift!.addListener(_onRiftChanged);
      // Synthesize a tick in case we attached after a state change.
      _onRiftChanged();
    }
  }

  @override
  void dispose() {
    _rift?.removeListener(_onRiftChanged);
    super.dispose();
  }

  void _onRiftChanged() {
    if (!mounted) return;
    final r = _rift;
    if (r == null) return;

    final connected = r.isLolControlConnected;

    // Edge: just connected → refetch any invitations / phase that may have
    // existed before we started listening (the LCU only PUSHes deltas).
    if (connected && !_wasConnected) {
      r.sendLcuRequest('GET', '/lol-lobby/v2/received-invitations');
      r.sendLcuRequest('GET', '/lol-gameflow/v1/gameflow-phase');
    }
    _wasConnected = connected;

    if (!connected) {
      _shownInviteIds.clear();
      return;
    }

    // Suppress the global popup when the user is on the lobby screen — it
    // shows the same invite inline already (received_invite_card.dart).
    if (_inviteDialogOpen || LolLobbyScreen.isAliveAnywhere) return;

    Map<String, dynamic>? next;
    for (final inv in r.receivedInvites) {
      final id = inv['invitationId']?.toString() ?? '';
      if (id.isEmpty || _shownInviteIds.contains(id)) continue;
      next = inv;
      break;
    }
    if (next != null) {
      // Schedule out of the listener tick so we don't showDialog during a
      // notifyListeners frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showInviteDialog(next!);
      });
    }
  }

  Future<void> _showInviteDialog(Map<String, dynamic> invite) async {
    final navState = rootNavigatorKey.currentState;
    if (navState == null) return; // root navigator not mounted yet

    final invId = invite['invitationId']?.toString() ?? '';
    if (invId.isEmpty) return;
    _shownInviteIds.add(invId);

    final fromName =
        (invite['fromSummonerName']?.toString().trim() ?? '').isEmpty
            ? 'a Summoner'
            : invite['fromSummonerName'].toString().trim();
    final modeLabel = _modeLabelFromInvite(invite);

    _inviteDialogOpen = true;
    final accepted = await showDialog<bool>(
      context: navState.context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'LoL Lobby Invite',
          style: TextStyle(color: _kLolBlue, fontWeight: FontWeight.w700),
        ),
        content: Text(
          modeLabel.isEmpty
              ? '$fromName has invited you to a League of Legends lobby.'
              : '$fromName invited you to a $modeLabel lobby.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('Refuse', style: TextStyle(color: _kReject)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccept,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: const Text('Accept',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    _inviteDialogOpen = false;
    if (!mounted) return;

    final r = _rift;
    if (r == null) return;
    if (accepted == true) {
      r.sendLcuRequest(
        'POST',
        '/lol-lobby/v2/received-invitations/$invId/accept',
      );
      // Mirror queue_selector_dialog._onInviteAccept: drop into the lobby
      // so the existing gameflow auto-router takes over.
      final navState2 = rootNavigatorKey.currentState;
      if (navState2 != null && !LolLobbyScreen.isAliveAnywhere) {
        navState2.push(
          MaterialPageRoute(builder: (_) => const LolLobbyScreen()),
        );
      }
    } else if (accepted == false) {
      r.sendLcuRequest(
        'POST',
        '/lol-lobby/v2/received-invitations/$invId/decline',
      );
    }

    // After closing, re-evaluate in case more invites are pending.
    _onRiftChanged();
  }

  String _modeLabelFromInvite(Map<String, dynamic> invite) {
    final gc = invite['gameConfig'];
    if (gc is Map) {
      final id = gc['queueId'];
      if (id is num) {
        switch (id.toInt()) {
          case 420:
            return 'Ranked Solo/Duo';
          case 430:
            return 'Normal (5v5)';
          case 400:
            return 'Normal (Draft)';
          case 440:
            return 'Ranked Flex';
          case 450:
            return 'ARAM';
          case 700:
            return 'Clash';
          case 1090:
            return 'TFT';
        }
      }
      final mode = gc['gameMode']?.toString();
      if (mode != null && mode.isNotEmpty) return mode;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
