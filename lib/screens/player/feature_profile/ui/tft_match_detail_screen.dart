import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/models/riot/riot_tft_match_detail_model.dart';
import 'package:arena_chain_flutter/core/api/riot/riot_api.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

class TftMatchDetailScreen extends StatefulWidget {
  final String matchId;
  final String region;
  final String puuid;

  const TftMatchDetailScreen({
    super.key,
    required this.matchId,
    required this.region,
    required this.puuid,
  });

  @override
  State<TftMatchDetailScreen> createState() => _TftMatchDetailScreenState();
}

class _TftMatchDetailScreenState extends State<TftMatchDetailScreen> {
  final RiotApi _riotApi = RiotApi();
  final TokenStorage _tokenStorage = TokenStorage();
  bool _isLoading = true;
  RiotTftMatchDetailModel? _matchDetail;
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

      final detail = await _riotApi.fetchTftMatchDetail(
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
        title: const Text('TFT Match Details', style: TextStyle(color: Colors.white, fontSize: 16)),
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
          // 1) Placement Header
          _buildPlacementHeader(detail),
          const SizedBox(height: 24),

          // 2) Stats Grid (Placement, Level, Gold)
          Row(
            children: [
              Expanded(child: _statCard('Level', detail.level.toString(), Icons.trending_up, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Gold Left', detail.goldLeft.toString(), Icons.monetization_on, Colors.amber)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Eliminated', 'Round ${detail.lastRound}', Icons.timer, Colors.red)),
            ],
          ),
          const SizedBox(height: 24),

          // 3) Units Section
          const Text('UNITS', style: TextStyle(color: Color(0xFF7A86AC), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildUnitsList(detail),
          
          const SizedBox(height: 24),

          // 4) Traits Section
          const Text('ACTIVE TRAITS', style: TextStyle(color: Color(0xFF7A86AC), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTraitsGrid(detail),
        ],
      ),
    );
  }

  Widget _buildPlacementHeader(RiotTftMatchDetailModel detail) {
    final placementColor = detail.placement <= 4 ? const Color(0xFF00FF00) : const Color(0xFFFF0055);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: placementColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.queueType.toUpperCase(),
                style: TextStyle(color: placementColor, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                'Placement #${detail.placement}',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A1F36), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildUnitsList(RiotTftMatchDetailModel detail) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: detail.units.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final unit = detail.units[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF1A1F36), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getRarityColor(unit['rarity'])),
                ),
                child: const Icon(Icons.person, color: Colors.white24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cleanName(unit['character_id']),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tier ${unit['tier']}',
                      style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Unit Items
              if (unit['itemNames'] != null)
                Row(
                  children: (unit['itemNames'] as List).map((i) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                      child: const Icon(Icons.inventory_2, size: 14, color: Colors.white38),
                    ),
                  )).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTraitsGrid(RiotTftMatchDetailModel detail) {
    final activeTraits = detail.traits.where((t) => t['tier_current'] > 0).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: activeTraits.map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F36),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getTraitColor(t['style'])),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14, color: _getTraitColor(t['style'])),
            const SizedBox(width: 8),
            Text(
              '${_cleanName(t['name'])} (${t['num_units']})',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Color _getRarityColor(int rarity) {
    switch(rarity) {
      case 0: return Colors.grey;
      case 1: return Colors.green;
      case 2: return Colors.blue;
      case 3: return Colors.purple;
      case 4: return Colors.orange;
      default: return Colors.white10;
    }
  }

  Color _getTraitColor(int style) {
    switch(style) {
      case 1: return Colors.brown; // Bronze
      case 2: return Colors.blueGrey; // Silver
      case 3: return Colors.amber; // Gold
      case 4: return Colors.cyan; // Prismatic
      default: return Colors.grey;
    }
  }

  String _cleanName(String internalName) {
    return internalName.replaceAll('TFT10_', '').replaceAll('TFT11_', '').replaceAll('Trait_', '');
  }
}
