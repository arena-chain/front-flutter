import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/services/rift_service.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_in_game_screen.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_lobby_screen.dart';

const _kBg = Color(0xFF0A0E1A);
const _kGold = Color(0xFFC89B3C);
const _kSurface = Color(0xFF111827);

/// Minimal champion id/name pairs — only a small subset for demonstration.
/// Replace with a full list fetched from Data Dragon or bundled JSON.
const _kChampions = <int, String>{
  1: 'Annie', 2: 'Olaf', 3: 'Galio', 4: 'Twisted Fate', 5: 'Xin Zhao',
  6: 'Urgot', 7: 'LeBlanc', 8: 'Vladimir', 9: 'Fiddlesticks', 10: 'Kayle',
  11: 'Master Yi', 12: 'Alistar', 13: 'Ryze', 14: 'Sion', 15: 'Sivir',
  16: 'Soraka', 17: 'Teemo', 18: 'Tristana', 19: 'Warwick', 20: 'Nunu & Willump',
  21: 'Miss Fortune', 22: 'Ashe', 23: 'Tryndamere', 24: 'Jax', 25: 'Morgana',
  26: 'Zilean', 27: 'Singed', 28: 'Evelynn', 29: 'Twitch', 30: 'Karthus',
  31: 'Cho\'Gath', 32: 'Amumu', 33: 'Rammus', 34: 'Anivia', 35: 'Shaco',
  36: 'Dr. Mundo', 37: 'Sona', 38: 'Kassadin', 39: 'Irelia', 40: 'Janna',
  41: 'Gangplank', 42: 'Corki', 43: 'Karma', 44: 'Taric', 45: 'Veigar',
  48: 'Trundle', 50: 'Swain', 51: 'Caitlyn', 53: 'Blitzcrank', 54: 'Malphite',
  55: 'Katarina', 56: 'Nocturne', 57: 'Maokai', 58: 'Renekton', 59: 'Jarvan IV',
  60: 'Elise', 61: 'Orianna', 62: 'Wukong', 63: 'Brand', 64: 'Lee Sin',
  67: 'Vayne', 68: 'Rumble', 69: 'Cassiopeia', 72: 'Skarner', 74: 'Heimerdinger',
  75: 'Nasus', 76: 'Nidalee', 77: 'Udyr', 78: 'Poppy', 79: 'Gragas',
  80: 'Pantheon', 81: 'Ezreal', 82: 'Mordekaiser', 83: 'Yorick', 84: 'Akali',
  85: 'Kennen', 86: 'Garen', 89: 'Leona', 90: 'Malzahar', 91: 'Talon',
  92: 'Riven', 96: 'Kog\'Maw', 98: 'Shen', 99: 'Lux', 101: 'Xerath',
  102: 'Shyvana', 103: 'Ahri', 104: 'Graves', 105: 'Fizz', 106: 'Volibear',
  110: 'Varus', 111: 'Nautilus', 112: 'Viktor', 113: 'Sejuani', 114: 'Fiora',
  115: 'Ziggs', 117: 'Lulu', 119: 'Draven', 120: 'Hecarim', 121: 'Kha\'Zix',
  122: 'Darius', 126: 'Jayce', 127: 'Lissandra', 131: 'Diana', 133: 'Quinn',
  134: 'Syndra', 136: 'Aurelion Sol', 141: 'Kayn', 142: 'Zoe', 143: 'Zyra',
  145: 'Kai\'Sa', 147: 'Seraphine', 150: 'Gnar', 154: 'Zac', 157: 'Yasuo',
  161: 'Vel\'Koz', 163: 'Taliyah', 164: 'Camille', 166: 'Akshan',
  200: 'Bel\'Veth', 201: 'Braum', 202: 'Jhin', 203: 'Kindred', 221: 'Zeri',
  222: 'Jinx', 223: 'Tahm Kench', 233: 'Briar', 234: 'Viego', 235: 'Senna',
  236: 'Lucian', 238: 'Zed', 240: 'Kled', 245: 'Ekko', 246: 'Qiyana',
  254: 'Vi', 266: 'Aatrox', 267: 'Nami', 268: 'Azir', 350: 'Yuumi',
  360: 'Samira', 412: 'Thresh', 420: 'Illaoi', 421: 'Rek\'Sai',
  427: 'Ivern', 429: 'Kalista', 432: 'Bard', 497: 'Rakan', 498: 'Xayah',
  516: 'Ornn', 517: 'Sylas', 518: 'Neeko', 523: 'Aphelios', 526: 'Rell',
  555: 'Pyke', 711: 'Vex', 777: 'Yone', 875: 'Sett', 876: 'Lillia',
  887: 'Gwen', 888: 'Renata Glasc', 895: 'Nilah', 897: 'K\'Sante',
  901: 'Smolder', 902: 'Milio', 950: 'Naafiri', 910: 'Hwei',
};

class LolChampSelectScreen extends StatefulWidget {
  const LolChampSelectScreen({super.key});

  @override
  State<LolChampSelectScreen> createState() => _LolChampSelectScreenState();
}

class _LolChampSelectScreenState extends State<LolChampSelectScreen> {
  StreamSubscription<LcuEvent>? _sub;

  Map<String, dynamic> _session = {};
  int? _selectedChampId;
  String _searchQuery = '';

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

  @override
  void initState() {
    super.initState();
    _sub = context.read<RiftService>().lcuEvents.listen(_onLcuEvent);
  }

  void _onLcuEvent(LcuEvent event) {
    if (event.uri.contains('/lol-champ-select/v1/session')) {
      if (event.data is Map<String, dynamic>) {
        setState(() => _session = event.data);
      }
    }
    if (event.uri.contains('/lol-gameflow/v1/gameflow-phase') ||
        event.uri.contains('/lol-gameflow/v1/session')) {
      final phase = event.data is String ? event.data : (event.data?['phase'] ?? '');
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
    _sub?.cancel();
    super.dispose();
  }

  void _commitAction() {
    final actionId = _activeActionId;
    if (actionId == null || _selectedChampId == null) return;

    final type = _currentPhase; // "ban" or "pick"
    context.read<RiftService>().sendLcuRequest(
      'PATCH',
      '/lol-champ-select/v1/session/actions/$actionId',
      {'championId': _selectedChampId, 'completed': true, 'type': type},
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase = _currentPhase;
    final phaseLabel = phase == 'ban' ? 'Ban Phase' : (phase == 'pick' ? 'Pick Phase' : 'Waiting…');
    final commitLabel = _selectedChampId != null
        ? '${phase == "ban" ? "Ban" : "Pick"} ${_kChampions[_selectedChampId] ?? "#$_selectedChampId"}'
        : 'Select a Champion';

    final filteredChamps = _kChampions.entries.where((e) {
      return _searchQuery.isEmpty || e.value.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
          phaseLabel,
          style: TextStyle(
            color: phase == 'ban' ? Colors.redAccent : _kGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Team strips
          _buildTeamStrip('Your Team', _allyTeam, _kGold),
          _buildTeamStrip('Enemy Team', _enemyTeam, Colors.redAccent),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search champion…',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                filled: true,
                fillColor: _kSurface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Champion grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 2.2,
              ),
              itemCount: filteredChamps.length,
              itemBuilder: (context, i) {
                final entry = filteredChamps[i];
                final selected = _selectedChampId == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedChampId = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected ? _kGold.withValues(alpha: 0.25) : _kSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? _kGold : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? _kGold : Colors.white70,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_activeActionId != null && _selectedChampId != null) ? _commitAction : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: phase == 'ban' ? Colors.redAccent : _kGold,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  commitLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStrip(String title, List<Map<String, dynamic>> members, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: members.map((m) {
              final champId = m['championId'] as int? ?? 0;
              final name = _kChampions[champId] ?? (champId > 0 ? '#$champId' : '—');
              final sumName = m['summonerName']?.toString() ?? '';
              return Chip(
                backgroundColor: _kSurface,
                label: Text(
                  sumName.isNotEmpty ? '$sumName ($name)' : name,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
