import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:arena_chain_flutter/services/rift_service.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_control_pairing_screen.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_lobby_screen.dart';

const _kBg = Color(0xFF0A0E1A);
const _kGold = Color(0xFF14452F);
const _kSurface = Color(0xFF111827);
const _kEnemyRed = Color(0xFFC84B4B);

enum _EventRowSide { myTeam, enemyTeam, neutral }

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

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool _gameStartSoundPlayed = false;

  String? _lastKillerName;
  DateTime? _lastKillTime;
  int _killStreak = 0;

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

  List<Map<String, dynamic>> _teamPlayersList(Map<String, dynamic>? gs, String key) {
    final v = gs?[key];
    if (v is! List) return [];
    return v.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
  }

  /// ORDER or CHAOS — which side the local summoner is on.
  String _localSideTeam(Map<String, dynamic>? gs) {
    if (gs == null) return 'ORDER';
    final order = _teamPlayersList(gs, 'orderTeam');
    for (final p in order) {
      if (p['isLocalPlayer'] == true) return 'ORDER';
    }
    final chaos = _teamPlayersList(gs, 'chaosTeam');
    for (final p in chaos) {
      if (p['isLocalPlayer'] == true) return 'CHAOS';
    }
    return 'ORDER';
  }

  Set<String> _summonerNamesOnSide(Map<String, dynamic>? gs, String orderOrChaos) {
    final key = orderOrChaos == 'ORDER' ? 'orderTeam' : 'chaosTeam';
    return _teamPlayersList(gs, key)
        .map((p) => p['summonerName']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  _EventRowSide _sideForKiller(String killer, Set<String> myNames, Set<String> enemyNames) {
    if (killer.isEmpty) return _EventRowSide.neutral;
    if (myNames.contains(killer)) return _EventRowSide.myTeam;
    if (enemyNames.contains(killer)) return _EventRowSide.enemyTeam;
    return _EventRowSide.neutral;
  }

  _EventRowSide _eventRowSide(Map<String, dynamic> e) {
    final name = e['EventName']?.toString() ?? '';
    final gs = _gameState;
    final localTeam = _localSideTeam(gs);
    final orderNames = _summonerNamesOnSide(gs, 'ORDER');
    final chaosNames = _summonerNamesOnSide(gs, 'CHAOS');
    final myNames = localTeam == 'ORDER' ? orderNames : chaosNames;
    final enemyNames = localTeam == 'ORDER' ? chaosNames : orderNames;
    final killer = e['KillerName']?.toString() ?? '';

    switch (name) {
      case 'ChampionKill':
      case 'Multikill':
      case 'DragonKill':
      case 'BaronKill':
      case 'HeraldKill':
        return _sideForKiller(killer, myNames, enemyNames);
      case 'TowerKill':
        if (killer.isNotEmpty) return _sideForKiller(killer, myNames, enemyNames);
        final tid = e['TeamID']?.toString().toUpperCase() ?? '';
        if (tid.contains('ORDER') || tid == '100') {
          return localTeam == 'ORDER' ? _EventRowSide.myTeam : _EventRowSide.enemyTeam;
        }
        if (tid.contains('CHAOS') || tid == '200') {
          return localTeam == 'CHAOS' ? _EventRowSide.myTeam : _EventRowSide.enemyTeam;
        }
        return _EventRowSide.neutral;
      case 'FirstBlood':
      case 'FirstBrick':
        return _sideForKiller(killer, myNames, enemyNames);
      case 'Ace':
      case 'GameEnd':
      case 'GameStart':
      default:
        return _EventRowSide.neutral;
    }
  }

  String _formatEventTime(Map<String, dynamic> e) {
    final t = e['EventTime'];
    final sec = t is num ? t.toDouble() : double.tryParse('$t') ?? 0;
    return _formatGameTime(sec);
  }

  String _assistersSuffix(Map<String, dynamic> e) {
    final a = e['Assisters'];
    if (a is! List || a.isEmpty) return '';
    final names = <String>[];
    for (final x in a) {
      if (x is String) {
        names.add(x);
      } else if (x is Map) {
        names.add((x['summonerName'] ?? x['name'] ?? '').toString());
      }
    }
    names.removeWhere((s) => s.isEmpty);
    if (names.isEmpty) return '';
    return ' (+ ${names.join(', ')})';
  }

  String _multikillDisplayName(String? raw) {
    switch (raw) {
      case 'DoubleKill':
        return 'Double Kill';
      case 'TripleKill':
        return 'Triple Kill';
      case 'QuadraKill':
        return 'Quadra Kill';
      case 'PentaKill':
        return 'PENTA KILL 🎉';
      default:
        return raw ?? 'Multikill';
    }
  }

  String _eventLineText(Map<String, dynamic> e) {
    final name = e['EventName']?.toString() ?? '';
    final killer = e['KillerName']?.toString() ?? '';
    final victim = e['VictimName']?.toString() ?? '';

    switch (name) {
      case 'ChampionKill':
        return '⚔️ $killer slew $victim${_assistersSuffix(e)}';
      case 'Multikill':
        final kt = _multikillDisplayName(e['KillType']?.toString());
        return '🔥 $killer — $kt!';
      case 'FirstBlood':
        return '🩸 First Blood — $killer';
      case 'DragonKill':
        final dt = e['DragonType']?.toString() ?? 'Dragon';
        return '🐉 $dt Dragon';
      case 'BaronKill':
        return '👁️ Baron Nashor';
      case 'HeraldKill':
        return '🏔️ Rift Herald';
      case 'TowerKill':
        return '🏰 Tower destroyed';
      case 'FirstBrick':
        return '🧱 First turret blood';
      case 'Ace':
        return '👑 Ace!';
      case 'GameStart':
        return '▶️ Game started';
      case 'GameEnd':
        final local = _localSummonerFromState() ?? '';
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

  Future<void> _playSound(String filename) async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$filename'));
    } catch (e) {
      // ignore: avoid_print
      print('[Audio] Error playing $filename: $e');
    }
  }

  void _handleEventSound(Map<String, dynamic> e) {
    final eventName = e['EventName']?.toString() ?? '';
    final killer = e['KillerName']?.toString() ?? '';
    final localName = _localSummonerFromState() ?? '';

    switch (eventName) {
      case 'GameStart':
        if (!_gameStartSoundPlayed) {
          _gameStartSoundPlayed = true;
          _playSound('Start.wav');
        }
        break;

      case 'FirstBlood':
        _playSound('first_blood.wav');
        break;

      case 'ChampionKill':
        if (killer == localName) {
          final now = DateTime.now();
          if (_lastKillerName == localName &&
              _lastKillTime != null &&
              now.difference(_lastKillTime!).inSeconds <= 10) {
            _killStreak++;
          } else {
            _killStreak = 1;
          }
          _lastKillerName = localName;
          _lastKillTime = now;

          if (_killStreak == 2) {
            _playSound('Double Kill.wav');
          } else if (_killStreak >= 3) {
            _playSound('Triple Kill.wav');
          }
        } else {
          if (e['VictimName']?.toString() == localName) {
            _killStreak = 0;
            _lastKillTime = null;
          }
        }
        break;

      case 'Multikill':
        if (killer == localName) {
          final killType = e['KillType']?.toString() ?? '';
          if (killType == 'DoubleKill') {
            _playSound('Double Kill.wav');
          } else if (killType == 'TripleKill' ||
              killType == 'QuadraKill' ||
              killType == 'PentaKill') {
            _playSound('Triple Kill.wav');
          }
        }
        break;
    }
  }

  void _pushEvent(Map<String, dynamic> raw) {
    if (!mounted) return;
    HapticFeedback.selectionClick();
    _handleEventSound(raw);
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
      if (!_gameStartSoundPlayed && _gameState != null) {
        _gameStartSoundPlayed = true;
        _playSound('Start.wav');
      }
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
      _killStreak = 0;
      _lastKillTime = null;
      _lastKillerName = null;
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
    try {
      _audioPlayer.dispose();
    } catch (e) {
      debugPrint('[InGame] _audioPlayer.dispose: $e');
    }
    try {
      _riftSub?.cancel();
    } catch (e) {
      debugPrint('[InGame] _riftSub.cancel: $e');
    }
    try {
      final s = _socket;
      if (s != null) {
        s.clearListeners();
        if (s.connected) s.disconnect();
        s.dispose();
      }
    } catch (e) {
      debugPrint('[InGame] _socket dispose: $e');
    }
    _socket = null;
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

  /// "Back to Lobby" — navigates to the lobby without tearing down the Rift
  /// WS tunnel. The mobile session stays alive so the player can immediately
  /// queue / receive invites again.
  void _navigateToLobby() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LolLobbyScreen()),
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
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(
                            Icons.music_note,
                            color: Colors.white38,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Sounds',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: _soundEnabled,
                              onChanged: (val) {
                                setState(() => _soundEnabled = val);
                                if (!val) _audioPlayer.stop();
                              },
                              activeThumbColor: const Color(0xFF00E676),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildStatsCard(gs, timeStr)),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(child: _buildTeamScoreBar(gs)),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(child: _buildTeamScoresCard(gs)),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  const SliverToBoxAdapter(
                    child: Text(
                      'Live events',
                      style: TextStyle(
                        color: _kGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  if (_events.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Waiting for game events…',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildEventItem(index),
                        childCount: _events.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _disconnectToPairing,
                        icon: const Icon(Icons.link_off, size: 16),
                        label: const Text('Disconnect'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kEnemyRed,
                          side: const BorderSide(color: _kEnemyRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
            if (_gameEnded) _buildGameOverOverlay(gs),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                tooltip: 'Back to home',
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.playerHome,
                    (route) => false,
                  );
                },
              ),
            ),
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

  String _normalizeDDragonName(String name) {
    const overrides = <String, String>{
      'Nunu & Willump': 'Nunu',
      'Wukong': 'MonkeyKing',
      'Renata Glasc': 'Renata',
      "K'Sante": 'KSante',
      "Bel'Veth": 'Belveth',
      "Kog'Maw": 'KogMaw',
      "Kha'Zix": 'Khazix',
      "Vel'Koz": 'Velkoz',
      "Cho'Gath": 'Chogath',
      'LeBlanc': 'Leblanc',
      "Kai'Sa": 'Kaisa',
      "Rek'Sai": 'RekSai',
      'Fiddlesticks': 'FiddleSticks',
    };
    return overrides[name] ?? name.replaceAll(' ', '').replaceAll("'", '');
  }

  int _sumTeamKills(List<dynamic> team) {
    return team.fold<int>(0, (sum, p) {
      if (p is! Map) return sum;
      return sum + ((p['kills'] as num?)?.toInt() ?? 0);
    });
  }

  Widget _buildTeamScoreBar(Map<String, dynamic>? gs) {
    if (gs == null) return const SizedBox.shrink();
    final orderTeam = (gs['orderTeam'] as List?) ?? [];
    final chaosTeam = (gs['chaosTeam'] as List?) ?? [];
    final localTeam = _localSideTeam(gs);
    final myScore =
        localTeam == 'ORDER' ? _sumTeamKills(orderTeam) : _sumTeamKills(chaosTeam);
    final enemyScore =
        localTeam == 'ORDER' ? _sumTeamKills(chaosTeam) : _sumTeamKills(orderTeam);
    if (myScore == 0 && enemyScore == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$myScore',
            style: const TextStyle(
              color: _kGold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '—',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 18,
              ),
            ),
          ),
          Text(
            '$enemyScore',
            style: TextStyle(
              color: Colors.red.shade400,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyItemSlot() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
    );
  }

  /// Up to 6 inventory slots; maps items by `slot` (0–5) when present.
  Widget _buildItemSlots(List<dynamic> items) {
    final bySlot = <int, Map<String, dynamic>>{};
    final overflow = <Map<String, dynamic>>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final s = (m['slot'] as num?)?.toInt();
      if (s != null && s >= 0 && s < 6) {
        bySlot[s] = m;
      } else {
        overflow.add(m);
      }
    }
    var oi = 0;
    for (var i = 0; i < 6; i++) {
      if (!bySlot.containsKey(i) && oi < overflow.length) {
        bySlot[i] = overflow[oi++];
      }
    }

    final slotWidgets = <Widget>[];
    for (int i = 0; i < 6; i++) {
      if (i > 0) slotWidgets.add(const SizedBox(width: 1));
      final m = bySlot[i];
      final id = m != null ? ((m['itemID'] as num?)?.toInt() ?? 0) : 0;
      if (id > 0) {
        slotWidgets.add(
          Image.network(
            'https://ddragon.leagueoflegends.com/cdn/14.10.1/img/item/$id.png',
            width: 12,
            height: 12,
            errorBuilder: (context, error, stackTrace) => _emptyItemSlot(),
          ),
        );
      } else {
        slotWidgets.add(_emptyItemSlot());
      }
    }

    return SizedBox(
      width: 77,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: slotWidgets,
      ),
    );
  }

  Widget _buildPlayerRow(
    Map<String, dynamic> p, {
    required bool highlightLocal,
    required bool showPosition,
    required bool isMyTeam,
  }) {
    final name = p['summonerName']?.toString() ?? '';
    final isLocal = p['isLocalPlayer'] == true;
    final isDead = p['isDead'] == true;
    final respawnTimer = (p['respawnTimer'] as num?)?.toDouble() ?? 0.0;
    final rawItems = p['items'];
    final items = rawItems is List ? rawItems : <dynamic>[];
    final k = p['kills'] ?? 0;
    final d = p['deaths'] ?? 0;
    final a = p['assists'] ?? 0;
    final champName = p['championName']?.toString() ?? '';
    final ddKey = _normalizeDDragonName(champName);
    final pos = p['position']?.toString() ?? '';
    final posBit = (showPosition && pos.isNotEmpty) ? ' · $pos' : '';

    final nameColor = isDead
        ? Colors.white24
        : (highlightLocal && isLocal)
            ? _kGold
            : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: champName.isEmpty
                    ? Container(
                        width: 22,
                        height: 22,
                        color: const Color(0xFF1A1F2E),
                        child: const Icon(Icons.person, size: 14, color: Colors.white38),
                      )
                    : Image.network(
                        'https://ddragon.leagueoflegends.com/cdn/14.10.1/img/champion/$ddKey.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 22,
                          height: 22,
                          color: const Color(0xFF1A1F2E),
                          child: const Icon(Icons.person, size: 14, color: Colors.white38),
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              if (highlightLocal && isLocal)
                const Text('★ ', style: TextStyle(color: _kGold, fontSize: 11)),
              Expanded(
                child: Text(
                  '$name$posBit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: nameColor,
                    fontSize: 12,
                    fontWeight: isLocal ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              Text(
                '$k / $d / $a',
                style: TextStyle(
                  color: isMyTeam ? _kGold : _kEnemyRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 2),
            child: Row(
              children: [
                _buildItemSlots(items),
                const Spacer(),
                if (isDead) ...[
                  const Icon(Icons.close, color: Colors.red, size: 10),
                  if (respawnTimer > 0)
                    Text(
                      ' ${respawnTimer.toStringAsFixed(0)}s',
                      style: const TextStyle(color: Colors.red, fontSize: 9),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 6, thickness: 0.3, color: Colors.white12),
        ],
      ),
    );
  }

  Widget _buildTeamScoresCard(Map<String, dynamic>? gs) {
    if (gs == null) return const SizedBox.shrink();
    final localTeam = _localSideTeam(gs);
    final myList =
        localTeam == 'ORDER' ? _teamPlayersList(gs, 'orderTeam') : _teamPlayersList(gs, 'chaosTeam');
    final enemyList =
        localTeam == 'ORDER' ? _teamPlayersList(gs, 'chaosTeam') : _teamPlayersList(gs, 'orderTeam');
    if (myList.isEmpty && enemyList.isEmpty) return const SizedBox.shrink();

    final mode = gs['gameMode']?.toString() ?? '';
    final showPosition = !mode.toUpperCase().contains('ARAM');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: _kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _kGold.withValues(alpha: 0.3), width: 0.6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MY TEAM',
                  style: TextStyle(
                    color: _kGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                ...myList.map(
                  (p) => _buildPlayerRow(
                    p,
                    highlightLocal: true,
                    showPosition: showPosition,
                    isMyTeam: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: _kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _kEnemyRed.withValues(alpha: 0.3), width: 0.6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENEMY TEAM',
                  style: TextStyle(
                    color: _kEnemyRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                ...enemyList.map(
                  (p) => _buildPlayerRow(
                    p,
                    highlightLocal: false,
                    showPosition: showPosition,
                    isMyTeam: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventItem(int index) {
    final e = _events[index];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEventRow(e),
        if (index < _events.length - 1) const Divider(color: Colors.white12, height: 1),
      ],
    );
  }

  Widget _buildEventRow(Map<String, dynamic> e) {
    final isGameEnd = e['EventName']?.toString() == 'GameEnd';
    if (isGameEnd) {
      final local = _localSummonerFromState() ?? '';
      final win = _parseVictory(e, local);
      final text =
          win == true ? '🏆 Victory!' : (win == false ? '💀 Defeat' : '🏁 Game ended');
      final color = win == true ? _kGold : (win == false ? _kEnemyRed : Colors.white70);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    final side = _eventRowSide(e);
    final time = _formatEventTime(e);
    final line = _eventLineText(e);
    final timeStyle = TextStyle(color: Colors.grey[600], fontSize: 10);

    if (side == _EventRowSide.neutral) {
      return SizedBox(
        height: 28,
        child: Row(
          children: [
            SizedBox(width: 40, child: Text(time, style: timeStyle)),
            Expanded(
              child: Text(
                line,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      );
    }

    if (side == _EventRowSide.myTeam) {
      return SizedBox(
        height: 28,
        child: Row(
          children: [
            SizedBox(width: 40, child: Text(time, style: timeStyle)),
            Expanded(
              child: Text(
                line,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _kGold, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      );
    }

    return SizedBox(
      height: 28,
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          Expanded(
            child: Text(
              line,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _kEnemyRed, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(width: 40, child: Text(time, textAlign: TextAlign.right, style: timeStyle)),
        ],
      ),
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
                    onPressed: _navigateToLobby,
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
