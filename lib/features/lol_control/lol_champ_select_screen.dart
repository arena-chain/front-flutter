import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/services/rift_service.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_in_game_screen.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_lobby_screen.dart';

const _kBg = Color(0xFF0A0E1A);
const _kGold = Color(0xFFC89B3C);
const _kRed = Color(0xFFC84B4B);
const _kSurface = Color(0xFF111827);

class LolChampSelectScreen extends StatefulWidget {
  const LolChampSelectScreen({super.key});

  @override
  State<LolChampSelectScreen> createState() => _LolChampSelectScreenState();
}

class _LolChampSelectScreenState extends State<LolChampSelectScreen> with SingleTickerProviderStateMixin {
  StreamSubscription<LcuEvent>? _sub;

  Map<String, dynamic> _session = {};
  int? _selectedChampId;
  String _searchQuery = '';

  Map<int, String> _championsById = {};
  // ignore: unused_field — reserved for name→id lookup (LCU / future features)
  Map<String, int> _championsByName = {};
  Map<int, String> _championDdKeyById = {};
  bool _champsLoading = true;
  String _patch = '14.10.1';

  String _localSummonerName = '';
  // ignore: unused_field — reserved for owned-spells / collections APIs.
  int _localSummonerId = 0;

  Set<int> _pickableChampIds = <int>{};

  List<Map<String, dynamic>> _runePages = const [];

  int _spell1Id = 4;
  int _spell2Id = 7;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  String get _currentPhase {
    final actions = _session['actions'] as List<dynamic>? ?? [];
    for (final group in actions) {
      if (group is List) {
        for (final action in group) {
          if (action is Map<String, dynamic> &&
              action['isInProgress'] == true &&
              action['isAllyAction'] == true) {
            return action['type']?.toString() ?? '';
          }
        }
      }
    }
    return '';
  }

  int? get _activeActionId {
    final actions = _session['actions'] as List<dynamic>? ?? [];
    for (final group in actions) {
      if (group is List) {
        for (final action in group) {
          if (action is Map<String, dynamic> &&
              action['isInProgress'] == true &&
              action['isAllyAction'] == true) {
            return action['id'] as int?;
          }
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get _allyTeam {
    final team = _session['myTeam'] as List<dynamic>? ?? [];
    return team.whereType<Map<String, dynamic>>().toList();
  }

  List<Map<String, dynamic>> get _enemyTeam {
    final team = _session['theirTeam'] as List<dynamic>? ?? [];
    return team.whereType<Map<String, dynamic>>().toList();
  }

  bool get _isAram {
    final gameMode = _session['gameConfig']?['gameMode']?.toString() ?? '';
    final q = _session['gameConfig']?['queueId'];
    final queueId = q is int ? q : (q as num?)?.toInt();
    return gameMode.toUpperCase().contains('ARAM') || queueId == 450;
  }

  int get _localPlayerCellId {
    final localId = _session['localPlayerCellId'];
    return localId is int ? localId : (localId as num?)?.toInt() ?? -1;
  }

  bool get _isMyTurn {
    final actions = _session['actions'] as List<dynamic>? ?? [];
    final localCell = _localPlayerCellId;
    for (final group in actions) {
      if (group is List) {
        for (final action in group) {
          if (action is Map<String, dynamic> &&
              action['isInProgress'] == true &&
              action['actorCellId'] == localCell) {
            return true;
          }
        }
      }
    }
    return false;
  }

  int? get _myActionId {
    final actions = _session['actions'] as List<dynamic>? ?? [];
    final localCell = _localPlayerCellId;
    for (final group in actions) {
      if (group is List) {
        for (final action in group) {
          if (action is Map<String, dynamic> &&
              action['isInProgress'] == true &&
              action['actorCellId'] == localCell) {
            return action['id'] as int?;
          }
        }
      }
    }
    return null;
  }

  int? get _allyActorCellInProgress {
    final actions = _session['actions'] as List<dynamic>? ?? [];
    for (final group in actions) {
      if (group is List) {
        for (final action in group) {
          if (action is Map<String, dynamic> &&
              action['isInProgress'] == true &&
              action['isAllyAction'] == true) {
            final c = action['actorCellId'];
            return c is int ? c : (c as num?)?.toInt();
          }
        }
      }
    }
    return null;
  }

  int? get _enemyActorCellInProgress {
    final actions = _session['actions'] as List<dynamic>? ?? [];
    for (final group in actions) {
      if (group is List) {
        for (final action in group) {
          if (action is Map<String, dynamic> &&
              action['isInProgress'] == true &&
              action['isAllyAction'] == false) {
            final c = action['actorCellId'];
            return c is int ? c : (c as num?)?.toInt();
          }
        }
      }
    }
    return null;
  }

  List<int> get _benchChampions {
    final bench = _session['benchChampions'] as List<dynamic>? ?? [];
    final ids = <int>[];
    for (final c in bench) {
      if (c is int && c > 0) {
        ids.add(c);
      } else if (c is Map) {
        final id = c['championId'];
        final i = id is int ? id : (id as num?)?.toInt() ?? 0;
        if (i > 0) ids.add(i);
      }
    }
    return ids;
  }

  // ignore: unused_element — spec hook for ARAM / team champ tracking
  List<int> get _myTeamChampions {
    return _allyTeam
        .map((m) {
          final id = m['championId'];
          return id is int ? id : (id as num?)?.toInt() ?? 0;
        })
        .where((id) => id > 0)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    _sub = context.read<RiftService>().lcuEvents.listen(_onLcuEvent);
    _loadChampions();

    final rift = context.read<RiftService>();
    rift.sendLcuRequest('GET', '/lol-champ-select/v1/session');
    rift.sendLcuRequest('GET', '/lol-summoner/v1/current-summoner');
    rift.sendLcuRequest('GET', '/lol-champ-select/v1/all-grid-champions');
    rift.sendLcuRequest('GET', '/lol-perks/v1/pages');
  }

  void _onLcuEvent(LcuEvent event) {
    if (event.uri == '/lol-champ-select/v1/session' ||
        event.uri.contains('/lol-champ-select/v1/session')) {
      if (event.data is Map) {
        setState(() => _session = Map<String, dynamic>.from(event.data as Map));
      }
    }

    if (event.uri == '/lol-summoner/v1/current-summoner') {
      if (event.data is Map) {
        final m = Map<String, dynamic>.from(event.data as Map);
        setState(() {
          _localSummonerName = (m['gameName']?.toString().isNotEmpty == true
                  ? m['gameName']
                  : (m['displayName'] ?? m['internalName'] ?? ''))
              .toString();
          _localSummonerId = (m['summonerId'] as num?)?.toInt() ?? 0;
        });
      }
    }

    if (event.uri == '/lol-champ-select/v1/all-grid-champions') {
      if (event.data is List) {
        final pickable = <int>{};
        for (final c in (event.data as List)) {
          if (c is! Map) continue;
          final cm = Map<String, dynamic>.from(c);
          final rawId = cm['id'] ?? cm['championId'];
          final id = rawId is int ? rawId : (rawId as num?)?.toInt() ?? 0;
          if (id <= 0) continue;
          final disabled = cm['disabled'] == true ||
              (cm['selectionStatus'] is Map &&
                  (cm['selectionStatus'] as Map)['disabled'] == true);
          if (disabled) continue;
          pickable.add(id);
        }
        setState(() => _pickableChampIds = pickable);
      }
    }

    if (event.uri == '/lol-perks/v1/pages') {
      if (event.data is List) {
        final pages = <Map<String, dynamic>>[];
        for (final p in (event.data as List)) {
          if (p is Map) {
            pages.add(Map<String, dynamic>.from(p));
          }
        }
        setState(() => _runePages = pages);
      }
    }

    if (event.uri.contains('/lol-gameflow/v1/gameflow-phase') ||
        event.uri.contains('/lol-gameflow/v1/session')) {
      final raw = event.data;
      final phase = raw is String
          ? raw
          : (raw is Map ? (raw['phase'] ?? raw['gameflowPhase'] ?? '').toString() : '');
      if (phase == 'InProgress' || phase == 'GameStart') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LolInGameScreen()),
        );
      } else if (phase == 'Lobby' || phase == 'None') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LolLobbyScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadChampions() async {
    try {
      final versionsRes = await http.get(
        Uri.parse('https://ddragon.leagueoflegends.com/api/versions.json'),
      );
      final versions = jsonDecode(versionsRes.body) as List<dynamic>;
      final patch = versions.first.toString();

      final champsRes = await http.get(
        Uri.parse('https://ddragon.leagueoflegends.com/cdn/$patch/data/en_US/champion.json'),
      );
      final data = jsonDecode(champsRes.body) as Map<String, dynamic>;
      final champData = data['data'] as Map<String, dynamic>;

      final byId = <int, String>{};
      final byName = <String, int>{};
      final ddById = <int, String>{};

      champData.forEach((ddKey, value) {
        if (value is! Map<String, dynamic>) return;
        final id = int.tryParse(value['key']?.toString() ?? '') ?? 0;
        final name = value['name']?.toString() ?? '';
        if (id <= 0 || name.isEmpty) return;
        byId[id] = name;
        byName[name] = id;
        ddById[id] = ddKey;
      });

      if (mounted) {
        setState(() {
          _championsById = byId;
          _championsByName = byName;
          _championDdKeyById = ddById;
          _champsLoading = false;
          _patch = patch;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _champsLoading = false);
    }
  }

  String _champImageUrl(String ddKey) =>
      'https://ddragon.leagueoflegends.com/cdn/$_patch/img/champion/$ddKey.png';

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
      'Aurelion Sol': 'AurelionSol',
      'Dr. Mundo': 'DrMundo',
      'Jarvan IV': 'JarvanIV',
      'Lee Sin': 'LeeSin',
      'Master Yi': 'MasterYi',
      'Miss Fortune': 'MissFortune',
      'Tahm Kench': 'TahmKench',
      'Twisted Fate': 'TwistedFate',
      'Xin Zhao': 'XinZhao',
    };
    return overrides[name] ?? name.replaceAll(' ', '').replaceAll("'", '').replaceAll('.', '');
  }

  String _ddKeyForChampId(int id) {
    final fromApi = _championDdKeyById[id];
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    final n = _championsById[id];
    if (n == null || n.isEmpty) return id.toString();
    return _normalizeDDragonName(n);
  }

  String _displayNameForChampId(int id) => _championsById[id] ?? (id > 0 ? '#$id' : '—');

  int _cellIdOf(Map<String, dynamic> m) {
    final c = m['cellId'];
    return c is int ? c : (c as num?)?.toInt() ?? -999;
  }

  Widget _championPortrait({
    required int champId,
    required double size,
    Color borderColor = Colors.transparent,
    double borderWidth = 0,
  }) {
    final url = champId > 0 ? _champImageUrl(_ddKeyForChampId(champId)) : '';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: borderWidth > 0 ? Border.all(color: borderColor, width: borderWidth) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: champId <= 0
            ? Container(
                color: const Color(0xFF1A1F2E),
                child: const Icon(Icons.person, size: 20, color: Colors.white38),
              )
            : Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF1A1F2E),
                  child: Icon(Icons.person, size: size * 0.45, color: Colors.white38),
                ),
              ),
      ),
    );
  }

  void _commitAction() {
    final actionId = _myActionId ?? _activeActionId;
    if (actionId == null || _selectedChampId == null) return;

    context.read<RiftService>().sendLcuRequest(
      'PATCH',
      '/lol-champ-select/v1/session/actions/$actionId',
      {'championId': _selectedChampId, 'completed': true},
    );
  }

  void _pickAramChamp(int champId) {
    context.read<RiftService>().sendLcuRequest(
      'POST',
      '/lol-champ-select/v1/session/bench/swap/$champId',
      {},
    );
  }

  Map<String, dynamic>? _localAllyMember() {
    final cell = _localPlayerCellId;
    for (final m in _allyTeam) {
      if (_cellIdOf(m) == cell) return m;
    }
    return _allyTeam.isNotEmpty ? _allyTeam.first : null;
  }

  int _localAssignedChampId() {
    final m = _localAllyMember();
    if (m == null) return 0;
    final id = m['championId'];
    return id is int ? id : (id as num?)?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isAram) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          elevation: 0,
          title: const Text(
            'ARAM — Champ Select',
            style: TextStyle(color: _kGold, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAramMyChamp(),
            const SizedBox(height: 12),
            _buildAramTeamRow(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'BENCH — Tap to swap',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: _buildAramBench()),
          ],
        ),
      );
    }

    final phase = _currentPhase;
    final phaseTitle = phase == 'ban' ? 'Ban Phase' : (phase == 'pick' ? 'Pick Phase' : 'Waiting…');

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                phaseTitle,
                style: TextStyle(
                  color: phase == 'ban' ? _kRed : _kGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_isMyTurn)
              FadeTransition(
                opacity: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kGold, width: 1),
                  ),
                  child: const Text(
                    'YOUR TURN',
                    style: TextStyle(
                      color: _kGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildLocalPlayerHeader(),
          _buildAllyStrip(),
          _buildEnemyStrip(),
          _buildPhaseBar(),
          _buildSearchBar(),
          Expanded(child: _buildChampGrid()),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildLocalPlayerHeader() {
    final id = _localAssignedChampId();
    final champName = id > 0 ? _displayNameForChampId(id) : '—';
    final localCell = _localPlayerCellId;
    final positionRaw = _localAllyMember()?['assignedPosition']?.toString() ?? '';
    final position = positionRaw.isEmpty
        ? ''
        : positionRaw[0].toUpperCase() + positionRaw.substring(1).toLowerCase();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGold.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          _championPortrait(champId: id, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'YOU',
                        style: TextStyle(
                          color: _kGold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _localSummonerName.isEmpty ? '…' : _localSummonerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$champName${position.isNotEmpty ? '  ·  $position' : ''}'
                  '${localCell >= 0 ? '  ·  Cell $localCell' : ''}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllyStrip() {
    final activeCell = _allyActorCellInProgress;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _allyTeam.map((m) {
            final champId = m['championId'];
            final id = champId is int ? champId : (champId as num?)?.toInt() ?? 0;
            final sum = m['summonerName']?.toString() ?? '';
            final cell = _cellIdOf(m);
            final highlight = activeCell != null && cell == activeCell;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _championPortrait(
                    champId: id,
                    size: 44,
                    borderColor: highlight ? _kGold : Colors.transparent,
                    borderWidth: highlight ? 2 : 0,
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      sum.isNotEmpty ? sum : _displayNameForChampId(id),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.1),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEnemyStrip() {
    final activeCell = _enemyActorCellInProgress;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _enemyTeam.map((m) {
            final champId = m['championId'];
            final id = champId is int ? champId : (champId as num?)?.toInt() ?? 0;
            final sum = m['summonerName']?.toString() ?? '';
            final cell = _cellIdOf(m);
            final highlight = activeCell != null && cell == activeCell;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _championPortrait(
                    champId: id,
                    size: 36,
                    borderColor: highlight ? _kRed : Colors.transparent,
                    borderWidth: highlight ? 2 : 0,
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      sum.isNotEmpty ? sum : _displayNameForChampId(id),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 9, height: 1.1),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPhaseBar() {
    final phase = _currentPhase;
    Color bg;
    String text;
    if (phase == 'ban') {
      bg = _kRed.withValues(alpha: 0.35);
      text = '🚫 BAN PHASE';
    } else if (phase == 'pick') {
      bg = _kGold.withValues(alpha: 0.25);
      text = '⚔️ PICK PHASE';
    } else {
      bg = Colors.white12;
      text = '⏳ Waiting for others...';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          if (_isMyTurn)
            FadeTransition(
              opacity: _pulseAnimation,
              child: const Text(
                'YOUR TURN',
                style: TextStyle(
                  color: _kGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search champion…',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: const Icon(Icons.search, color: _kGold, size: 20),
          filled: true,
          fillColor: _kSurface,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kGold, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kGold, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildChampGrid() {
    if (_champsLoading) {
      return const Center(child: CircularProgressIndicator(color: _kGold));
    }

    final filtered = _championsById.entries.where((e) {
      if (_pickableChampIds.isNotEmpty && !_pickableChampIds.contains(e.key)) {
        return false;
      }
      return _searchQuery.isEmpty || e.value.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final phase = _currentPhase;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final entry = filtered[i];
        final id = entry.key;
        final name = entry.value;
        final selected = _selectedChampId == id;
        final ddKey = _ddKeyForChampId(id);

        return GestureDetector(
          onTap: () => setState(() => _selectedChampId = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? _kGold : Colors.transparent,
                width: selected ? 2 : 0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _champImageUrl(ddKey),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFF1A1F2E),
                      child: const Icon(Icons.person, color: Colors.white38),
                    ),
                  ),
                  if (!selected)
                    Container(color: Colors.black.withValues(alpha: 0.35)),
                  if (phase == 'ban')
                    Center(
                      child: Icon(Icons.close, color: Colors.redAccent.withValues(alpha: 0.85), size: 28),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                        ),
                      ),
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? _kGold : Colors.white,
                          fontSize: 9,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static const Map<int, (String, String)> _kSpellsById = {
    4: ('Flash', 'SummonerFlash'),
    7: ('Heal', 'SummonerHeal'),
    14: ('Ignite', 'SummonerDot'),
    12: ('Teleport', 'SummonerTeleport'),
    11: ('Smite', 'SummonerSmite'),
    3: ('Exhaust', 'SummonerExhaust'),
    21: ('Barrier', 'SummonerBarrier'),
    1: ('Cleanse', 'SummonerBoost'),
    6: ('Ghost', 'SummonerHaste'),
    32: ('Mark', 'SummonerSnowball'),
  };

  String _spellIconUrl(String ddKey) =>
      'https://ddragon.leagueoflegends.com/cdn/$_patch/img/spell/$ddKey.png';

  String _spellDdKey(int id) => _kSpellsById[id]?.$2 ?? '';

  void _commitSpells() {
    context.read<RiftService>().sendLcuRequest(
      'PATCH',
      '/lol-champ-select/v1/session/my-selection',
      {'spell1Id': _spell1Id, 'spell2Id': _spell2Id},
    );
  }

  Future<void> _openSpellPicker(int slot) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final entries = _kSpellsById.entries.toList();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pick Summoner ${slot == 1 ? 'D' : 'F'}',
                  style: const TextStyle(
                    color: _kGold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: entries.map((e) {
                    final id = e.key;
                    final disabled = (slot == 1 && id == _spell2Id) || (slot == 2 && id == _spell1Id);
                    return Opacity(
                      opacity: disabled ? 0.35 : 1,
                      child: GestureDetector(
                        onTap: disabled ? null : () => Navigator.pop(ctx, id),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                _spellIconUrl(e.value.$2),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFF1A1F2E),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 60,
                              child: Text(
                                e.value.$1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;
    setState(() {
      if (slot == 1) {
        _spell1Id = picked;
      } else {
        _spell2Id = picked;
      }
    });
    _commitSpells();
  }

  Widget _buildSpellSlot(int slot) {
    final id = slot == 1 ? _spell1Id : _spell2Id;
    final dd = _spellDdKey(id);
    return GestureDetector(
      onTap: () => _openSpellPicker(slot),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kGold.withValues(alpha: 0.5)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: dd.isEmpty
              ? const Center(
                  child: Icon(Icons.add, color: Colors.white38, size: 18),
                )
              : Image.network(
                  _spellIconUrl(dd),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.add, color: Colors.white38),
                ),
        ),
      ),
    );
  }

  Future<void> _openRunesPicker() async {
    final rift = context.read<RiftService>();
    if (_runePages.isEmpty) {
      rift.sendLcuRequest('GET', '/lol-perks/v1/pages');
    }

    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * 0.55;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose Rune Page',
                  style: TextStyle(
                    color: _kGold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (_runePages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No saved rune pages found.\nCreate one in the LoL client.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                else
                  SizedBox(
                    height: maxH,
                    child: ListView.separated(
                      itemCount: _runePages.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: Colors.white10,
                        height: 1,
                      ),
                      itemBuilder: (context, i) {
                        final p = _runePages[i];
                        final pid = (p['id'] as num?)?.toInt() ?? 0;
                        final name = p['name']?.toString() ?? 'Page #$pid';
                        final current = p['current'] == true;
                        return ListTile(
                          dense: true,
                          title: Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: current ? const Icon(Icons.check, color: _kGold) : null,
                          onTap: pid > 0 ? () => Navigator.pop(ctx, pid) : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || picked <= 0) return;
    rift.sendLcuRequest(
      'PUT',
      '/lol-perks/v1/currentpage',
      {'id': picked},
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      rift.sendLcuRequest('GET', '/lol-perks/v1/pages');
    });
  }

  Widget _buildRunesButton() {
    return GestureDetector(
      onTap: _openRunesPicker,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kGold.withValues(alpha: 0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.bubble_chart, color: _kGold, size: 16),
            SizedBox(width: 4),
            Text(
              'Runes',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    final phase = _currentPhase;
    final selectedId = _selectedChampId;
    final canCommit = _isMyTurn && (_myActionId ?? _activeActionId) != null && selectedId != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0D121F),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: selectedId == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Select a champion',
                  style: TextStyle(color: Colors.white38, fontSize: 15),
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        _champImageUrl(_ddKeyForChampId(selectedId)),
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 52,
                          height: 52,
                          color: const Color(0xFF1A1F2E),
                          child: const Icon(Icons.person, color: Colors.white38),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _displayNameForChampId(selectedId),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phase == 'ban'
                                ? 'Ready to ban'
                                : (phase == 'pick' ? 'Ready to pick' : 'Waiting...'),
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: canCommit ? _commitAction : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: phase == 'ban' ? _kRed : _kGold,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey[800],
                          disabledForegroundColor: Colors.white38,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Text(
                          phase == 'ban' ? 'BAN' : 'LOCK IN',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSpellSlot(1),
                    _buildSpellSlot(2),
                    const SizedBox(width: 8),
                    _buildRunesButton(),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildAramMyChamp() {
    final id = _localAssignedChampId();
    final name = _displayNameForChampId(id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          const Text(
            'Your Champion',
            style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kGold, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: id <= 0
                  ? Container(
                      width: 120,
                      height: 120,
                      color: const Color(0xFF1A1F2E),
                      child: const Icon(Icons.person, size: 48, color: Colors.white38),
                    )
                  : Image.network(
                      _champImageUrl(_ddKeyForChampId(id)),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 120,
                        height: 120,
                        color: const Color(0xFF1A1F2E),
                        child: const Icon(Icons.person, size: 48, color: Colors.white38),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAramTeamRow() {
    final localCell = _localPlayerCellId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(5, (index) {
            Map<String, dynamic>? m;
            if (index < _allyTeam.length) {
              m = _allyTeam[index];
            }
            final champId = m == null
                ? 0
                : (m['championId'] is int
                    ? m['championId'] as int
                    : (m['championId'] as num?)?.toInt() ?? 0);
            final isLocal = m != null && _cellIdOf(m) == localCell;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _championPortrait(
                champId: champId,
                size: 50,
                borderColor: isLocal ? _kGold : Colors.transparent,
                borderWidth: isLocal ? 2 : 0,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAramBench() {
    final bench = _benchChampions;
    if (bench.isEmpty) {
      return const Center(
        child: Text('No bench champions', style: TextStyle(color: Colors.white38)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      scrollDirection: Axis.horizontal,
      itemCount: bench.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, i) {
        final champId = bench[i];
        return GestureDetector(
          onTap: () => _pickAramChamp(champId),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kGold, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    _champImageUrl(_ddKeyForChampId(champId)),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 60,
                      height: 60,
                      color: const Color(0xFF1A1F2E),
                      child: const Icon(Icons.person, color: Colors.white38),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.65),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: const Text(
                        'SWAP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _kGold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
