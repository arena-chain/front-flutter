import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/services/rift_service.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_queue_screen.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_champ_select_screen.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_in_game_screen.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_control_pairing_screen.dart';
import 'package:arena_chain_flutter/features/lol_control/widgets/role_picker.dart';
import 'package:arena_chain_flutter/features/lol_control/widgets/invite_overlay.dart';

const _kBg = Color(0xFF0A0E1A);
const _kGold = Color(0xFFC89B3C);
const _kSurface = Color(0xFF111827);

class _GameModeOption {
  final int queueId;
  final String title;
  final IconData icon;
  const _GameModeOption({required this.queueId, required this.title, required this.icon});
}

class LolLobbyScreen extends StatefulWidget {
  const LolLobbyScreen({super.key});

  @override
  State<LolLobbyScreen> createState() => _LolLobbyScreenState();
}

class _LolLobbyScreenState extends State<LolLobbyScreen> {
  StreamSubscription<LcuEvent>? _sub;
  RiftService? _rift;
  bool _hadRiftConnection = false;
  bool _disconnectNavigationScheduled = false;
  Map<String, dynamic>? _lobbyState;
  String _gameflowPhase = '';
  int? _creatingQueueId;
  bool _initialFetchDone = false;

  static const _modes = <_GameModeOption>[
    _GameModeOption(queueId: 430, title: "Normal (SR 5v5)", icon: Icons.public),
    _GameModeOption(queueId: 420, title: 'Ranked Solo/Duo', icon: Icons.military_tech),
    _GameModeOption(queueId: 450, title: 'ARAM', icon: Icons.bolt),
    _GameModeOption(queueId: 1090, title: 'Teamfight Tactics', icon: Icons.grid_view),
    _GameModeOption(queueId: 400, title: 'Normal (Draft)', icon: Icons.sports_esports),
  ];

  void _onRiftConnectionChanged() {
    final r = _rift;
    if (r == null || !mounted || _disconnectNavigationScheduled) return;
    if (r.status == RiftConnectionStatus.connected) {
      _hadRiftConnection = true;
      return;
    }
    if (_hadRiftConnection &&
        (r.status == RiftConnectionStatus.disconnected ||
            r.status == RiftConnectionStatus.error)) {
      _disconnectNavigationScheduled = true;
      r.removeListener(_onRiftConnectionChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection lost. Please reconnect from the pairing screen.'),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LolControlPairingScreen()),
          );
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _rift = context.read<RiftService>();
    _hadRiftConnection = _rift!.status == RiftConnectionStatus.connected;
    _rift!.addListener(_onRiftConnectionChanged);

    final rift = _rift!;
    _sub = rift.lcuEvents.listen(_onLcuEvent);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final r = context.read<RiftService>();
      if (r.status == RiftConnectionStatus.connected) {
        r.sendLcuRequest('GET', '/lol-lobby/v2/lobby');
        r.sendLcuRequest('GET', '/lol-gameflow/v1/gameflow-phase');
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_initialFetchDone) {
        setState(() => _initialFetchDone = true);
      }
    });
  }

  // ── URI matchers ────────────────────────────────────────────

  bool _isLobbyUri(String? uri) {
    if (uri == null || uri.isEmpty) return false;
    return uri.contains('/lol-lobby/v2/lobby');
  }

  bool _isGameflowPhaseUri(String? uri) {
    if (uri == null || uri.isEmpty) return false;
    return uri.contains('/lol-gameflow/v1/gameflow-phase') ||
        uri.contains('/lol-gameflow/v1/session');
  }

  Map<String, dynamic>? _localMemberFromLobby(Map<String, dynamic> lobby) {
    final lm = lobby['localMember'];
    if (lm is Map<String, dynamic>) return Map<String, dynamic>.from(lm);
    if (lm is Map) return Map<String, dynamic>.from(lm);
    final members = lobby['members'] as List<dynamic>? ?? [];
    for (final raw in members) {
      if (raw is Map<String, dynamic> && raw['isLocalMember'] == true) {
        return Map<String, dynamic>.from(raw);
      }
      if (raw is Map && raw['isLocalMember'] == true) {
        return Map<String, dynamic>.from(raw);
      }
    }
    return null;
  }

  int? _queueIdFromLobby(Map<String, dynamic> lobby) {
    final gc = lobby['gameConfig'] as Map<String, dynamic>?;
    final q = gc?['queueId'];
    if (q is int) return q;
    if (q is num) return q.toInt();
    return null;
  }

  List<dynamic> _invitationsFromLobby(Map<String, dynamic> lobby) {
    final inv = lobby['invitations'];
    if (inv is List) return List<dynamic>.from(inv);
    return [];
  }

  // ── event routing ───────────────────────────────────────────

  void _onLcuEvent(LcuEvent event) {
    if (_isLobbyUri(event.uri)) _onLobbyLcuEvent(event);
    if (_isGameflowPhaseUri(event.uri)) _onGameflowLcuEvent(event);
  }

  void _onLobbyLcuEvent(LcuEvent event) {
    _initialFetchDone = true;
    final status = event.httpStatus;
    final data = event.data;

    if (status == 404 || data == null || (data is String && data == 'null')) {
      setState(() {
        _lobbyState = null;
        _creatingQueueId = null;
      });
      return;
    }

    Map<String, dynamic>? next;
    if (data is Map<String, dynamic>) {
      next = data.isEmpty ? null : Map<String, dynamic>.from(data);
    } else if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      next = m.isEmpty ? null : m;
    }

    setState(() {
      _lobbyState = next;
      if (next != null) _creatingQueueId = null;
    });
  }

  void _onGameflowLcuEvent(LcuEvent event) {
    if (event.httpStatus == 404) {
      setState(() => _gameflowPhase = '');
      return;
    }
    String phase = '';
    final raw = event.data;
    if (raw is String && raw != 'null') {
      phase = raw.replaceAll('"', '');
    } else if (raw is Map) {
      phase = (raw['phase'] ?? raw['gameflowPhase'] ?? '').toString();
    }
    setState(() => _gameflowPhase = phase);
    _maybeNavigateForGameflow();
  }

  void _maybeNavigateForGameflow() {
    if (!mounted) return;
    switch (_gameflowPhase) {
      case 'Matchmaking':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LolQueueScreen()));
        break;
      case 'ChampSelect':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LolChampSelectScreen()));
        break;
      case 'InProgress':
      case 'GameStart':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LolInGameScreen()));
        break;
      default:
        break;
    }
  }

  // ── actions ─────────────────────────────────────────────────

  void _createLobby(int queueId) {
    setState(() => _creatingQueueId = queueId);
    context.read<RiftService>().sendLcuRequest('POST', '/lol-lobby/v2/lobby', {'queueId': queueId});
  }

  void _startQueue() {
    context.read<RiftService>().sendLcuRequest('POST', '/lol-lobby/v2/lobby/matchmaking/search');
  }

  void _leaveLobby() {
    context.read<RiftService>().sendLcuRequest('DELETE', '/lol-lobby/v2/lobby');
  }

  @override
  void dispose() {
    _rift?.removeListener(_onRiftConnectionChanged);
    _sub?.cancel();
    super.dispose();
  }

  // ── build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_initialFetchDone && _lobbyState == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _kGold, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text('Fetching lobby state…', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
    return _lobbyState != null ? _buildLobbyView() : _buildCreateLobbyView();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kBg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          context.read<RiftService>().disconnect();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LolControlPairingScreen()),
          );
        },
      ),
      title: const Text('Lobby', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      actions: [
        Consumer<RiftService>(
          builder: (ctx, rift, child) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10,
                    color: rift.conduitConnected ? Colors.greenAccent : Colors.redAccent),
                const SizedBox(width: 6),
                Text(
                  rift.conduitConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: rift.conduitConnected ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // STATE 1: No lobby → show game mode grid
  // ────────────────────────────────────────────────────────────

  Widget _buildCreateLobbyView() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'No Active Lobby',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a game mode to create a lobby.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 400 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 90,
                    ),
                    itemCount: _modes.length,
                    itemBuilder: (context, i) => _buildGameModeCard(_modes[i]),
                  );
                },
              ),
            ],
          ),
        ),
        if (_creatingQueueId != null)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _kGold, strokeWidth: 2.5),
                  SizedBox(height: 16),
                  Text('Creating lobby…',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGameModeCard(_GameModeOption mode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _creatingQueueId != null ? null : () => _createLobby(mode.queueId),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kGold.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(mode.icon, color: _kGold, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  mode.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // STATE 2: Lobby exists → info + players + bottom buttons
  // ────────────────────────────────────────────────────────────

  Widget _buildLobbyView() {
    final lobby = _lobbyState!;
    final gameConfig = lobby['gameConfig'] as Map<String, dynamic>? ?? {};
    final gameMode = gameConfig['gameMode']?.toString() ?? 'Unknown';
    final mapId = gameConfig['mapId']?.toString() ?? '—';
    final members = lobby['members'] as List<dynamic>? ?? [];
    final queueId = _queueIdFromLobby(lobby);
    final showRolePicker = queueId == 420 || queueId == 400;
    final localMember = _localMemberFromLobby(lobby);
    final initialPrimary =
        localMember?['firstPositionPreference']?.toString() ?? 'UNSELECTED';
    final initialSecondary =
        localMember?['secondPositionPreference']?.toString() ?? 'UNSELECTED';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Game Mode',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(gameMode,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          if (localMember?['isLeader'] == true)
                            TextButton.icon(
                              onPressed: () {
                                showInviteFriendsBottomSheet(
                                  context,
                                  riftService: context.read<RiftService>(),
                                  invitations: _invitationsFromLobby(lobby),
                                );
                              },
                              icon: const Icon(Icons.person_add, color: _kGold, size: 20),
                              label: const Text('Invite', style: TextStyle(color: _kGold)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Map ID', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(mapId, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                      if (_gameflowPhase.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Phase', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(_gameflowPhase, style: const TextStyle(color: _kGold, fontSize: 15)),
                      ],
                    ],
                  ),
                ),
                if (showRolePicker) ...[
                  const Divider(height: 28, thickness: 1, color: Colors.white12),
                  RolePicker(
                    initialPrimary: initialPrimary,
                    initialSecondary: initialSecondary,
                  ),
                  const Divider(height: 28, thickness: 1, color: Colors.white12),
                ],
                const SizedBox(height: 20),
                const Text('Players',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (members.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No other players in lobby yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  )
                else
                  ...members.map((raw) {
                    final m = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
                    final name = m['summonerName']?.toString() ?? 'Player';
                    final isLeader = m['isLeader'] == true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _kSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: _kGold, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(name,
                                    style: const TextStyle(color: Colors.white, fontSize: 15))),
                            if (isLeader)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _kGold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Leader',
                                    style: TextStyle(color: _kGold, fontSize: 11)),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _leaveLobby,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Leave Lobby', style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _startQueue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Start Queue', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
