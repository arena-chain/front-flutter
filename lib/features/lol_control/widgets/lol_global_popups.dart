// SPDX-License-Identifier: proprietary
// Global driver that listens to RiftService and shows two ambient dialogs:
//  1. "Invite received" — when a new LoL lobby invite arrives.
//  2. "Ongoing game"    — when LoL gameflow phase becomes InProgress / GameStart.
// Mounted once in MaterialApp.builder so it's alive on every screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:arena_chain_flutter/services/rift_service.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_in_game_screen.dart';

const _kLolBlue = Color(0xFF4DB8FF);
const _kSurface = Color(0xFF111827);

class LolGlobalPopups extends StatefulWidget {
  final Widget child;
  const LolGlobalPopups({super.key, required this.child});

  @override
  State<LolGlobalPopups> createState() => _LolGlobalPopupsState();
}

class _LolGlobalPopupsState extends State<LolGlobalPopups> {
  static final GlobalKey _rootKey = GlobalKey();

  RiftService? _rift;
  final Set<String> _shownInviteIds = <String>{};
  bool _inviteDialogOpen = false;
  bool _gameDialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = context.read<RiftService>();
    if (!identical(r, _rift)) {
      _rift?.removeListener(_onRiftChanged);
      _rift = r;
      _rift!.addListener(_onRiftChanged);
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
    if (r == null || !r.isLolControlConnected) {
      _shownInviteIds.clear();
      return;
    }

    // 1) Invite popup
    if (!_inviteDialogOpen) {
      Map<String, dynamic>? next;
      for (final inv in r.receivedInvites) {
        final id = inv['invitationId']?.toString() ?? '';
        if (id.isEmpty || _shownInviteIds.contains(id)) continue;
        next = inv;
        break;
      }
      if (next != null) {
        _showInviteDialog(next);
      }
    }

    // 2) Live-game popup
    final phase = r.gameflowPhase;
    final inLiveGame = phase == 'InProgress' || phase == 'GameStart';
    if (inLiveGame &&
        !_gameDialogOpen &&
        !r.liveGamePromptShownThisGame) {
      r.liveGamePromptShownThisGame = true;
      _showOngoingGameDialog();
    }
  }

  Future<void> _showInviteDialog(Map<String, dynamic> invite) async {
    final ctx = _rootCtx();
    if (ctx == null) return;
    final invId = invite['invitationId']?.toString() ?? '';
    if (invId.isEmpty) return;
    _shownInviteIds.add(invId);
    final fromName =
        (invite['fromSummonerName']?.toString().trim() ?? '').isEmpty
            ? 'a Summoner'
            : invite['fromSummonerName'].toString().trim();

    _inviteDialogOpen = true;
    final accepted = await showDialog<bool>(
      context: ctx,
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
          '$fromName has invited you to a League of Legends lobby.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('Refuse',
                style: TextStyle(color: Color(0xFFC84B4B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kLolBlue,
              foregroundColor: Colors.black,
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
    } else if (accepted == false) {
      r.sendLcuRequest(
        'POST',
        '/lol-lobby/v2/received-invitations/$invId/decline',
      );
    }
  }

  Future<void> _showOngoingGameDialog() async {
    final ctx = _rootCtx();
    if (ctx == null) return;
    _gameDialogOpen = true;
    final viewLive = await showDialog<bool>(
      context: ctx,
      barrierDismissible: true,
      builder: (dCtx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Live Match Detected',
          style: TextStyle(color: _kLolBlue, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'A League of Legends game is in progress on your client.\n\n'
          'Would you like to view live data for the current match?',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('No', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kLolBlue,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: const Text('Yes — view live data',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    _gameDialogOpen = false;
    if (!mounted) return;

    if (viewLive == true) {
      final r = _rift;
      if (r == null) return;
      final ip = r.lastRelayHostIp ?? '127.0.0.1';
      final navCtx = _rootCtx();
      if (navCtx == null || !navCtx.mounted) return;
      Navigator.of(navCtx).push(
        MaterialPageRoute(
          builder: (_) => LolInGameScreen(serverIp: ip, serverPort: 3000),
        ),
      );
    }
  }

  /// Pulls a context from the navigator that's safe to call `showDialog` /
  /// `Navigator.push` on, regardless of which screen is on top.
  BuildContext? _rootCtx() {
    if (!mounted) return null;
    return _rootKey.currentContext ?? context;
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _rootKey, child: widget.child);
  }
}
