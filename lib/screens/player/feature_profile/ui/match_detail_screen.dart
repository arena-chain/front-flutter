import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/models/riot/riot_match_detail_model.dart';
import 'package:arena_chain_flutter/core/api/riot/riot_api.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;
  final String region;
  final String puuid;

  const MatchDetailScreen({
    super.key,
    required this.matchId,
    required this.region,
    required this.puuid,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final RiotApi _riotApi = RiotApi();
  final TokenStorage _tokenStorage = TokenStorage();
  bool _isLoading = true;
  RiotMatchDetailModel? _matchDetail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) throw Exception('Authentication failed');

      final detail = await _riotApi.fetchMatchDetail(
        matchId: widget.matchId,
        region: widget.region,
        puuid: widget.puuid,
        token: token,
      );

      setState(() {
        _matchDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: Text(widget.matchId, style: const TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final detail = _matchDetail!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1) Game Info Header
          _buildInfoCard(detail),
          const SizedBox(height: 24),

          // 2) Stats Grid (Player & Team)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPlayerStats(detail)),
              const SizedBox(width: 16),
              Expanded(child: _buildTeamStats(detail)),
            ],
          ),
          const SizedBox(height: 24),

          // 3) Bottom Section: Items & Assets
          _buildAssetsSection(detail),
        ],
      ),
    );
  }

  Widget _buildInfoCard(RiotMatchDetailModel detail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7A86AC).withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.queueType.toUpperCase(),
                style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                detail.gameMode,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                detail.durationString,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
              ),
              Text(
                '${detail.gameCreation.day}/${detail.gameCreation.month}/${detail.gameCreation.year}',
                style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStats(RiotMatchDetailModel detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PLAYER PERFORMANCE', style: TextStyle(color: Color(0xFF7A86AC), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _statTile('KDA', detail.kda, icon: Icons.bolt, color: Colors.amber),
        _statTile('CS', detail.cs.toString(), icon: Icons.catching_pokemon, color: Colors.green),
        _statTile('Gold', '${(detail.gold / 1000).toStringAsFixed(1)}k', icon: Icons.monetization_on, color: Colors.yellow),
        _statTile('Damage', '${(detail.damageDealt / 1000).toStringAsFixed(1)}k', icon: Icons.fireplace, color: Colors.red),
        _statTile('Vision', detail.visionScore.toString(), icon: Icons.visibility, color: Colors.blue),
      ],
    );
  }

  Widget _buildTeamStats(RiotMatchDetailModel detail) {
    final blue = detail.blueTeam;
    final red = detail.redTeam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TEAM OBJECTIVES', style: TextStyle(color: Color(0xFF7A86AC), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _teamObjectiveRow('Kills', blue['totalKills'], red['totalKills']),
        _teamObjectiveRow('Gold', '${(blue['totalGold'] / 1000).toStringAsFixed(1)}k', '${(red['totalGold'] / 1000).toStringAsFixed(1)}k'),
        _teamObjectiveRow('Towers', blue['towers'], red['towers']),
        _teamObjectiveRow('Barons', blue['barons'], red['barons']),
        _teamObjectiveRow('Dragons', blue['dragons'], red['dragons']),
      ],
    );
  }

  Widget _statTile(String label, String value, {required IconData icon, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A1F36), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 10)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teamObjectiveRow(String label, dynamic blueVal, dynamic redVal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Text(blueVal.toString(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          Expanded(child: Center(child: Text(label, style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 10)))),
          Text(redVal.toString(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAssetsSection(RiotMatchDetailModel detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LOADOUT & ITEMS', style: TextStyle(color: Color(0xFF7A86AC), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            // Runes & Spells
            _assetCircle('https://ddragon.leagueoflegends.com/cdn/img/perk-images/Styles/${_runePath(detail.primaryRune)}.png'),
            const SizedBox(width: 8),
            _assetCircle('https://ddragon.leagueoflegends.com/cdn/16.4.1/img/spell/${_spellName(detail.spells[0])}.png'),
            const SizedBox(width: 24),
            // Items
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: detail.items.where((id) => id != 0).map((id) => _itemBox(id)).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _assetCircle(String url) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF7A86AC).withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(url, errorBuilder: (_, __, ___) => const Icon(Icons.help_outline, color: Colors.white70)),
      ),
    );
  }

  Widget _itemBox(int id) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        'https://ddragon.leagueoflegends.com/cdn/16.4.1/img/item/$id.png',
        width: 40,
        height: 40,
        errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: const Color(0xFF1A1F36)),
      ),
    );
  }

  String _runePath(int id) {
    switch(id) {
      case 8000: return '7201_Precision';
      case 8100: return '7200_Domination';
      case 8200: return '7202_Sorcery';
      case 8300: return '7203_Whimsy';
      case 8400: return '7204_Resolve';
      default: return 'Empty';
    }
  }

  String _spellName(int id) {
    // Basic mapping
    final spells = {12: 'SummonerTeleport', 4: 'SummonerFlash', 14: 'SummonerDot', 11: 'SummonerSmite', 3: 'SummonerExhaust', 6: 'SummonerHaste'};
    return spells[id] ?? 'SummonerFlash';
  }
}
