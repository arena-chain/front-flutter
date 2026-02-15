import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arena_chain_flutter/core/api/riot/riot_api.dart';
import 'package:arena_chain_flutter/core/models/riot/riot_account_model.dart';
import 'package:arena_chain_flutter/core/models/riot/riot_tft_match_detail_model.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/match_detail_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/tft_match_detail_screen.dart';

enum RiotMatchType { lol, tft }

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gameNameController = TextEditingController();
  final _tagLineController = TextEditingController();
  String _selectedRegion = 'na1';
  
  final RiotApi _riotApi = RiotApi();
  final TokenStorage _tokenStorage = TokenStorage();
  bool _isLoading = false;
  RiotAccountModel? _accountData;
  List<RiotTftMatchModel> _tftMatches = [];
  RiotMatchType _selectedMatchType = RiotMatchType.lol;
  String? _errorMessage;
  bool _isFetchingTft = false;

  final List<Map<String, String>> _regions = [
    {'value': 'na1', 'label': 'North America'},
    {'value': 'euw1', 'label': 'Europe West'},
    {'value': 'eun1', 'label': 'Europe Nordic & East'},
    {'value': 'kr', 'label': 'Korea'},
    {'value': 'br1', 'label': 'Brazil'},
    {'value': 'jp1', 'label': 'Japan'},
    {'value': 'la1', 'label': 'Latin America North'},
    {'value': 'la2', 'label': 'Latin America South'},
    {'value': 'oc1', 'label': 'Oceania'},
    {'value': 'tr1', 'label': 'Turkey'},
    {'value': 'ru', 'label': 'Russia'},
  ];

  @override
  void dispose() {
    _gameNameController.dispose();
    _tagLineController.dispose();
    super.dispose();
  }

  Future<void> _fetchAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _accountData = null;
      _tftMatches = [];
    });

    try {
      final token = await _tokenStorage.getAccessToken();

      if (token == null) {
        throw Exception('Not authenticated. Please log in again.');
      }

      if (_selectedMatchType == RiotMatchType.lol) {
        final account = await _riotApi.fetchPlayerAccount(
          gameName: _gameNameController.text.trim(),
          tagLine: _tagLineController.text.trim(),
          region: _selectedRegion,
          token: token,
        );
        setState(() {
          _accountData = account;
          _isLoading = false;
        });
      } else {
        await _fetchTft();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTft() async {
    if (_accountData == null && !_formKey.currentState!.validate()) return;
    
    setState(() {
      _isFetchingTft = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) throw Exception('Not authenticated');

      final account = await _riotApi.fetchTftAccount(
        gameName: _gameNameController.text.trim(),
        tagLine: _tagLineController.text.trim(),
        region: _selectedRegion,
        token: token,
      );

      // Extract TFT matches - we might need to adjust RiotAccountModel.fromJson 
      // or the backend response to ensure TFT matches are in a recognizable list.
      // For now, let's assume the backend returned TFT matches in the matchHistory field 
      // but they are structured as RiotTftMatchModel.
      
      // We manually parse them here if RiotAccountModel.fromJson assumed they were LoL matches.
      // Re-fetching or specialized parsing:
      final tftMatches = (account.toJson()['matchHistory'] as List? ?? [])
          .map((m) => RiotTftMatchModel.fromJson(m as Map<String, dynamic>))
          .toList();

      setState(() {
        _accountData = account;
        _tftMatches = tftMatches;
        _isFetchingTft = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isFetchingTft = false;
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('My Account', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Link Your League of Legends Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your Riot ID to fetch your account information',
                style: TextStyle(color: Color(0xFF7A86AC), fontSize: 14),
              ),
              const SizedBox(height: 24),

              // IGN Input
              TextFormField(
                controller: _gameNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'In-Game Name (IGN)',
                  labelStyle: const TextStyle(color: Color(0xFF7A86AC)),
                  hintText: 'e.g., Faker',
                  hintStyle: const TextStyle(color: Color(0xFF4A5568)),
                  filled: true,
                  fillColor: const Color(0xFF1A1F36),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF7A86AC)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your IGN';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tag Input
              TextFormField(
                controller: _tagLineController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tag',
                  labelStyle: const TextStyle(color: Color(0xFF7A86AC)),
                  hintText: 'e.g., KR1',
                  hintStyle: const TextStyle(color: Color(0xFF4A5568)),
                  filled: true,
                  fillColor: const Color(0xFF1A1F36),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.tag, color: Color(0xFF7A86AC)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your tag';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Region Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF1A1F36),
                decoration: InputDecoration(
                  labelText: 'Server/Region',
                  labelStyle: const TextStyle(color: Color(0xFF7A86AC)),
                  filled: true,
                  fillColor: const Color(0xFF1A1F36),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.public, color: Color(0xFF7A86AC)),
                ),
                items: _regions.map((region) {
                  return DropdownMenuItem(
                    value: region['value'],
                    child: Text(region['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Fetch Button
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text(
                        'Fetch Account Info',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Account Info Display
              if (_accountData != null) ...[
                const SizedBox(height: 16),
                
                // 1) Player Basic Info (Top Section)
                _buildBasicInfoSection(),
                
                const SizedBox(height: 16),
                
                // 2) Rank Display (Under Name Section)
                if (_accountData!.ranks.isNotEmpty)
                  _buildRankSection(_accountData!.ranks.first)
                else
                  _buildUnrankedSection(),
                  
                const SizedBox(height: 24),
                
                // 3) Match Type Selector
                Row(
                  children: [
                    _buildTypeButton(RiotMatchType.lol, 'League of Legends'),
                    const SizedBox(width: 8),
                    _buildTypeButton(RiotMatchType.tft, 'TFT'),
                  ],
                ),

                const SizedBox(height: 16),
                
                // 4) Match History Section
                const Text(
                  'MATCH HISTORY',
                  style: TextStyle(
                    color: Color(0xFF7A86AC),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (_selectedMatchType == RiotMatchType.lol)
                  if (_accountData!.matchHistory.isEmpty)
                    _buildEmptyHistorySection()
                  else
                    ..._accountData!.matchHistory.map((match) => _buildMatchCard(match))
                else
                  if (_tftMatches.isEmpty)
                     _isFetchingTft 
                        ? const Center(child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: Color(0xFF00FF00)),
                          ))
                        : _buildEmptyHistorySection()
                  else
                    ..._tftMatches.map((match) => _buildTftMatchCard(match)),
                  
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Profile Icon
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  _accountData!.profileIconUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF00),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_accountData!.level}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Summoner Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _accountData!.summonerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _accountData!.region.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF7A86AC),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankSection(RiotRank rank) {
    final winrate = (rank.wins / (rank.wins + rank.losses) * 100).toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRankColor(rank.tier).withOpacity(0.2),
            const Color(0xFF1A1F36),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getRankColor(rank.tier).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.military_tech,
            color: _getRankColor(rank.tier),
            size: 60,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ranked Solo',
                  style: TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
                ),
                Text(
                  '${rank.tier} ${rank.rank}',
                  style: TextStyle(
                    color: _getRankColor(rank.tier),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${rank.leaguePoints} LP',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$winrate% Winrate',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${rank.wins}W ${rank.losses}L',
                style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnrankedSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'Unranked',
          style: TextStyle(color: Color(0xFF7A86AC), fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildEmptyHistorySection() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: Text(
          'No matches found',
          style: TextStyle(color: Color(0xFF7A86AC)),
        ),
      ),
    );
  }

  Widget _buildTypeButton(RiotMatchType type, String label) {
    bool isSelected = _selectedMatchType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMatchType = type;
          });
          if (type == RiotMatchType.tft && _tftMatches.isEmpty && _accountData != null) {
            _fetchTft();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF1A1F36),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF7A86AC).withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTftMatchCard(RiotTftMatchModel match) {
    final placementColor = match.placement <= 4 ? const Color(0xFF00FF00) : const Color(0xFFFF0055);
    
    return InkWell(
      onTap: () {
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TftMatchDetailScreen(
              matchId: match.matchId,
              region: _selectedRegion,
              puuid: _accountData!.puuid,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F36),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: placementColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Placement Badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: placementColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: placementColor.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '#${match.placement}',
                        style: TextStyle(
                          color: placementColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Game Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.queueType.toUpperCase(),
                          style: TextStyle(
                            color: placementColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Level ${match.level}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          match.durationString,
                          style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Gold
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${match.goldLeft}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Round ${match.lastRound}',
                        style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Units (Simplified preview)
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: match.units.length > 7 ? 7 : match.units.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (context, index) {
                    final unit = match.units[index];
                    // Mapping TFT internal names to icons would require a mapping or Data Dragon.
                    // For now, we'll use a placeholder or generic icon.
                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0E1A),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.person, color: Colors.white24, size: 16),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(RiotMatchModel match) {
    final winColor = match.win ? const Color(0xFF00FF00) : const Color(0xFFFF0055);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailScreen(
              matchId: match.matchId,
              region: _selectedRegion,
              puuid: _accountData!.puuid,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F36),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: winColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Champ Icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      match.championIconUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Game Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.win ? 'WIN' : 'LOSS',
                          style: TextStyle(
                            color: winColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          match.championName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          match.durationString,
                          style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // KDA
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${match.kills} / ${match.deaths} / ${match.assists}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        match.kda,
                        style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Items
              Row(
                children: match.items.where((id) => id != 0).map((id) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      'https://ddragon.leagueoflegends.com/cdn/14.1.1/img/item/$id.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (_, __, ___) => Container(
                        width: 24,
                        height: 24,
                        color: const Color(0xFF0A0E1A),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'IRON': return Colors.grey;
      case 'BRONZE': return Colors.brown;
      case 'SILVER': return Colors.blueGrey;
      case 'GOLD': return Colors.amber;
      case 'PLATINUM': return Colors.cyan;
      case 'EMERALD': return Colors.green;
      case 'DIAMOND': return Colors.blue;
      case 'MASTER': return Colors.purple;
      case 'GRANDMASTER': return Colors.red;
      case 'CHALLENGER': return Colors.orange;
      default: return Colors.white;
    }
  }


}
