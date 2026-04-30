import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/models/riot/riot_account_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/match_detail_screen.dart';
import 'package:arena_chain_flutter/screens/player/feature_game_stats/view_model/game_stats_viewmodel.dart';

class LolStatsScreen extends StatefulWidget {
  const LolStatsScreen({super.key});

  @override
  State<LolStatsScreen> createState() => _LolStatsScreenState();
}

class _LolStatsScreenState extends State<LolStatsScreen> {
  static const Color _neon = Color(0xFF39FF14);
  late final GameStatsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = GameStatsViewModel(GameStatsTarget.lol)..refresh();
    _vm.addListener(_onVm);
  }

  void _onVm() => setState(() {});

  @override
  void dispose() {
    _vm.removeListener(_onVm);
    _vm.dispose();
    super.dispose();
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
        title: const Text('League of Legends', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: _neon,
        onRefresh: _vm.refresh,
        child: _vm.loading && _vm.lolAccount == null
            ? const Center(child: CircularProgressIndicator(color: _neon))
            : _vm.error != null && _vm.lolAccount == null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _vm.error!.replaceAll('Exception: ', ''),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  )
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final acc = _vm.lolAccount!;
    final region = _vm.linkStatus['riotRegion']?.toString() ?? acc.region;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _header(acc, region),
        const SizedBox(height: 20),
        Text(
          'RANKED QUEUES',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        if (acc.ranks.isEmpty)
          _card(
            child: const Text(
              'No ranked data returned for this account.',
              style: TextStyle(color: Color(0xFF7A86AC)),
            ),
          )
        else
          ...acc.ranks.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.queueLabel.toUpperCase(),
                        style: const TextStyle(
                          color: _neon,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${r.tier} ${r.rank} · ${r.leaguePoints} LP',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        '${r.wins}W / ${r.losses}L',
                        style: const TextStyle(color: Color(0xFF7A86AC)),
                      ),
                    ],
                  ),
                ),
              )),
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
        if (_vm.matches.isEmpty)
          _card(
            child: const Text(
              'No recent matches from the API.',
              style: TextStyle(color: Color(0xFF7A86AC)),
            ),
          )
        else
          ..._vm.matches.map((raw) {
            final m = RiotMatchModel.fromJson(raw as Map<String, dynamic>);
            final winColor = m.win ? _neon : const Color(0xFFFF0055);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MatchDetailScreen(
                          matchId: m.matchId,
                          region: region,
                          puuid: acc.puuid,
                        ),
                      ),
                    );
                  },
                  child: _card(
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: winColor, width: 3)),
                          ),
                          padding: const EdgeInsets.only(left: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              m.championIconUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48,
                                height: 48,
                                color: const Color(0xFF1A1F36),
                                child: const Icon(Icons.shield, color: Colors.white24),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.championName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'KDA ${m.kda} · ${m.durationString} · ${_timeAgo(m.gameCreation)}',
                                style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          m.win ? Icons.trending_up : Icons.trending_down,
                          color: winColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _header(RiotAccountModel acc, String region) {
    return _card(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              acc.profileIconUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: const Color(0xFF1A1F36),
                child: const Icon(Icons.person, color: Colors.white54, size: 36),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acc.summonerName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Level ${acc.level} · ${region.toUpperCase()}',
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
