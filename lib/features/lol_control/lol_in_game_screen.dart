import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:arena_chain_flutter/services/rift_service.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_control_pairing_screen.dart';

const _kBg = Color(0xFF0A0E1A);
const _kGold = Color(0xFFC89B3C);
const _kSurface = Color(0xFF111827);

/// In-game live stats via Nest Socket.IO (`/live-game`). [serverIp] defaults from [RiftService.lastRelayHostIp].
class LolInGameScreen extends StatefulWidget {
  const LolInGameScreen({
    super.key,
    this.serverIp,
    this.serverPort = 3000,
  });

  final String? serverIp;
  final int serverPort;

  @override
  State<LolInGameScreen> createState() => _LolInGameScreenState();
}

class _LolInGameScreenState extends State<LolInGameScreen> {
  Map<String, dynamic>? _gameState;
  final List<Map<String, dynamic>> _events = [];
  bool _gameEnded = false;
  bool? _lastVictory;
  io.Socket? _socket;
  StreamSubscription<LcuEvent>? _riftSub;
  static const int _maxEvents = 120;

  String get _effectiveHost =>
      widget.serverIp ??
      Provider.of<RiftService>(context, listen: false).lastRelayHostIp ??
      '127.0.0.1';

  String _formatGameTime(double seconds) {
    final s = seconds.floor();
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  String? _localSummonerFromState() {
    final n = _gameState?['summonerName'];
    if (n == null) return null;
    return n.toString();
  }

  String _describeEvent(Map<String, dynamic> e) {
    final name = e['EventName']?.toString() ?? '';
    final local = _localSummonerFromState() ?? '';

    String killer = e['KillerName']?.toString() ?? '';
    String victim = e['VictimName']?.toString() ?? '';

    switch (name) {
      case 'ChampionKill':
        if (local.isNotEmpty && killer == local) {
          return '⚔️ You killed $victim';
        }
        if (local.isNotEmpty && victim == local) {
          return '💀 You were killed by $killer';
        }
        return '⚔️ $killer slayed $victim';
      case 'Multikill':
        final kt = e['KillType']?.toString() ?? 'Multikill';
        final streak = e['KillStreak']?.toString() ?? '';
        return '🔥 $kt! ($streak kills)';
      case 'DragonKill':
        final dt = e['DragonType']?.toString() ?? 'Dragon';
        return '🐉 $dt Dragon slain';
      case 'BaronKill':
        return '👁️ Baron Nashor slain';
      case 'HeraldKill':
        return '🏔️ Rift Herald slain';
      case 'TowerKill':
        return '🏰 Tower destroyed';
      case 'FirstBlood':
        return '🩸 First Blood!';
      case 'FirstBrick':
        return '🧱 First turret blood!';
      case 'Ace':
        return '👑 Ace!';
      case 'GameStart':
        return '▶️ Game started';
      case 'GameEnd':
        final win = _parseVictory(e, local);
        if (win == true) return '🏆 Victory!';
        if (win == false) return '💀 Defeat';
        return '🏁 Game ended';
      default:
        return '📌 $name';
    }
  }

  bool? _parseVictory(Map<String, dynamic> e, String localSummoner) {
    final result = e['Result']?.toString().toLowerCase().trim();
    if (result == 'win') return true;
    if (result == 'loss' || result == 'lose' || result == 'defeat') return false;

    final winning = e['WinningTeam']?.toString() ?? '';
    final localTeam = e['LocalPlayerTeam']?.toString();
    if (winning.isNotEmpty && localTeam != null && localTeam.isNotEmpty) {
      return winning == localTeam;
    }
    return null;
  }

  void _pushEvent(Map<String, dynamic> raw) {
    if (!mounted) return;
    HapticFeedback.selectionClick();
    setState(() {
      _events.insert(0, Map<String, dynamic>.from(raw));
      if (_events.length > _maxEvents) {
        _events.removeRange(_maxEvents, _events.length);
      }
      if (raw['EventName']?.toString() == 'GameEnd') {
        final local = _localSummonerFromState() ?? '';
        _lastVictory = _parseVictory(raw, local);
        _gameEnded = true;
      }
    });
  }

  void _connectSocket() {
    _socket?.dispose();
    final url = 'http://$_effectiveHost:${widget.serverPort}/live-game';
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(8)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.on('game-state', (data) {
      if (!mounted || data is! Map) return;
      setState(() => _gameState = Map<String, dynamic>.from(data));
    });

    _socket!.on('game-event', (data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      _pushEvent(m);
    });

    _socket!.on('game-ended', (_) {
      if (!mounted) return;
      setState(() {
        _gameEnded = true;
        if (_lastVictory == null) {
          for (final ev in _events) {
            if (ev['EventName']?.toString() == 'GameEnd') {
              final local = _localSummonerFromState() ?? '';
              _lastVictory = _parseVictory(Map<String, dynamic>.from(ev), local);
              break;
            }
          }
        }
      });
    });

    _socket!.connect();
  }

  void _onRiftEvent(LcuEvent ev) {
    if (!ev.uri.contains('/lol-gameflow/v1/gameflow-phase')) return;
    String phase = '';
    final raw = ev.data;
    if (raw is String && raw != 'null') {
      phase = raw.replaceAll('"', '');
    } else if (raw is Map) {
      phase = (raw['phase'] ?? raw['gameflowPhase'] ?? '').toString();
    }
    if (phase != 'EndOfGame' || !mounted) return;
    _showPostGameFromLcuDialog();
  }

  void _showPostGameFromLcuDialog() {
    final gs = _gameState;
    final k = gs?['kills'] ?? 0;
    final d = gs?['deaths'] ?? 0;
    final a = gs?['assists'] ?? 0;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        title: const Text('Post-game', style: TextStyle(color: _kGold)),
        content: Text(
          'League reports End of Game.\nK / D / A: $k / $d / $a',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectSocket());
    _riftSub = context.read<RiftService>().lcuEvents.listen(_onRiftEvent);
  }

  @override
  void dispose() {
    _riftSub?.cancel();
    _socket?.dispose();
    super.dispose();
  }

  void _disconnectToPairing() {
    context.read<RiftService>().disconnect();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LolControlPairingScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = _gameState;
    final timeStr = gs != null
        ? _formatGameTime((gs['gameTime'] as num?)?.toDouble() ?? 0)
        : '--:--';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatsCard(gs, timeStr),
                  const SizedBox(height: 16),
                  const Text(
                    'Live events',
                    style: TextStyle(
                      color: _kGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildEventList()),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _disconnectToPairing,
                      icon: const Icon(Icons.link_off, color: Colors.redAccent),
                      label: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_gameEnded) _buildGameOverOverlay(gs),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic>? gs, String timeStr) {
    final champ = gs?['championName']?.toString() ?? '—';
    final sum = gs?['summonerName']?.toString() ?? '—';
    final lvl = gs?['level'] ?? '—';
    final k = gs?['kills'] ?? 0;
    final d = gs?['deaths'] ?? 0;
    final a = gs?['assists'] ?? 0;
    final cs = gs?['creepScore'] ?? 0;
    final gold = gs?['gold'] ?? 0;
    final mode = gs?['gameMode']?.toString() ?? '';

    return Card(
      color: _kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _kGold, width: 0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_moon, color: _kGold, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$champ  $sum',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('Lvl $lvl', style: const TextStyle(color: _kGold, fontWeight: FontWeight.w600)),
              ],
            ),
            if (mode.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(mode, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$k / $d / $a',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                Text('$cs CS', style: const TextStyle(color: Colors.white70, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: const [
                SizedBox(width: 4),
                Text('K   D   A', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 2)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatGold(gold)} gold',
                  style: const TextStyle(color: _kGold, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white54, size: 18),
                    const SizedBox(width: 4),
                    Text(timeStr, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatGold(dynamic g) {
    final n = (g is num) ? g.toInt() : int.tryParse('$g') ?? 0;
    return NumberFormat('#,###').format(n);
  }

  Widget _buildEventList() {
    if (_events.isEmpty) {
      return Center(
        child: Text(
          'Waiting for game events…',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }
    return ListView.separated(
      itemCount: _events.length,
      separatorBuilder: (context, _) => const Divider(color: Colors.white12, height: 1),
      itemBuilder: (ctx, i) {
        final e = _events[i];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.bolt, color: _kGold, size: 22),
          title: Text(
            _describeEvent(e),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        );
      },
    );
  }

  Widget _buildGameOverOverlay(Map<String, dynamic>? gs) {
    final k = gs?['kills'] ?? 0;
    final d = gs?['deaths'] ?? 0;
    final a = gs?['assists'] ?? 0;
    final cs = gs?['creepScore'] ?? 0;
    final gold = gs?['gold'] ?? 0;
    final resultLine = _lastVictory == true
        ? 'Victory'
        : _lastVictory == false
            ? 'Defeat'
            : 'Match finished';

    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Card(
          color: _kSurface,
          margin: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _kGold),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Game Over',
                  style: TextStyle(
                    color: _kGold,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(resultLine, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 20),
                Text(
                  'KDA: $k / $d / $a',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '$cs CS · ${_formatGold(gold)} gold',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _disconnectToPairing,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Back to Lobby'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
