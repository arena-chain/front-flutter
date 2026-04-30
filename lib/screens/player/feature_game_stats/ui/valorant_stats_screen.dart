import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/screens/player/feature_game_stats/view_model/game_stats_viewmodel.dart';

class ValorantStatsScreen extends StatefulWidget {
  const ValorantStatsScreen({super.key});

  @override
  State<ValorantStatsScreen> createState() => _ValorantStatsScreenState();
}

class _ValorantStatsScreenState extends State<ValorantStatsScreen> {
  static const Color _neon = Color(0xFF39FF14);
  late final GameStatsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = GameStatsViewModel(GameStatsTarget.valorant)..refresh();
    _vm.addListener(_onVm);
  }

  void _onVm() => setState(() {});

  @override
  void dispose() {
    _vm.removeListener(_onVm);
    _vm.dispose();
    super.dispose();
  }

  String _displayName() {
    final gn = _vm.linkStatus['riotGameName']?.toString() ?? '';
    if (gn.isEmpty) return 'RIOT ACCOUNT';
    return gn.toUpperCase();
  }

  String _timeAgo(int gameCreationMs) {
    if (gameCreationMs <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(gameCreationMs);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('Valorant', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: _neon,
        onRefresh: _vm.refresh,
        child: _vm.loading && _vm.matches.isEmpty && _vm.error == null
            ? const Center(child: CircularProgressIndicator(color: _neon))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _header(),
                  const SizedBox(height: 8),
                  Text(
                    'Ranked tier is not available with a development Riot API key.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'RECENT MATCHES',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_vm.error != null)
                    _card(
                      child: Text(
                        _vm.error!.replaceAll('Exception: ', ''),
                        style: const TextStyle(color: Color(0xFF7A86AC)),
                      ),
                    )
                  else if (_vm.matches.isEmpty)
                    _card(
                      child: const Text(
                        'Valorant match history requires a production Riot API key — currently unavailable.',
                        style: TextStyle(color: Color(0xFF7A86AC), height: 1.4),
                      ),
                    )
                  else
                    ..._vm.matches.map((raw) {
                      final m = raw as Map<String, dynamic>;
                      final win = m['win'] == true;
                      final winColor = win ? _neon : const Color(0xFFFF0055);
                      final map = m['map']?.toString() ?? 'Unknown';
                      final kda = m['kda']?.toString() ?? '--';
                      final gc = (m['gameCreation'] as num?)?.toInt() ?? 0;
                      final lenMs = (m['gameLengthMs'] as num?)?.toInt() ?? 0;
                      final dur = lenMs > 0
                          ? '${lenMs ~/ 60000}m ${(lenMs % 60000) ~/ 1000}s'
                          : '—';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _card(
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: winColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      map.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'KDA $kda · $dur · ${_timeAgo(gc)}',
                                      style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                win ? Icons.trending_up : Icons.trending_down,
                                color: winColor,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _header() {
    final region = _vm.linkStatus['riotRegion']?.toString() ?? '—';
    return _card(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _neon.withValues(alpha: 0.6)),
              color: const Color(0xFF1A1F36),
            ),
            child: const Center(
              child: Text(
                'VAL',
                style: TextStyle(
                  color: _neon,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  region.toUpperCase(),
                  style: const TextStyle(color: Color(0xFF7A86AC)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _neon.withValues(alpha: 0.25)),
      ),
      child: child,
    );
  }
}
