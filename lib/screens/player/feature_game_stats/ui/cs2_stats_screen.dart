import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/api/steam/steam_api.dart';
import 'package:arena_chain_flutter/core/models/steam/steam_link_status_model.dart';

class Cs2StatsScreen extends StatefulWidget {
  const Cs2StatsScreen({super.key});

  @override
  State<Cs2StatsScreen> createState() => _Cs2StatsScreenState();
}

class _Cs2StatsScreenState extends State<Cs2StatsScreen> {
  static const Color _neon = Color(0xFF39FF14);
  final SteamApi _steam = SteamApi();
  final TokenStorage _tokens = TokenStorage();
  bool _loading = true;
  String? _error;
  SteamLinkStatusModel? _status;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await _tokens.getAccessToken();
      if (t == null) throw Exception('Not authenticated');
      final m = await _steam.getStatus(token: t);
      _status = SteamLinkStatusModel.fromJson(m);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _openProfile() async {
    final id = _status?.steamId;
    if (id == null || id.isEmpty) return;
    final uri = Uri.parse('https://steamcommunity.com/profiles/$id');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('Counter-Strike 2', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _neon))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.white70))
                else if (_status != null) ...[
                  _header(_status!),
                  const SizedBox(height: 20),
                  _placeholderCard(),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh, color: _neon),
                      label: const Text('REFRESH STATUS', style: TextStyle(color: _neon)),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _header(SteamLinkStatusModel s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _neon.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          if (s.steamAvatarUrl != null && s.steamAvatarUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                s.steamAvatarUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _steamPlaceholder(),
              ),
            )
          else
            _steamPlaceholder(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (s.steamUsername ?? 'STEAM').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (s.steamId != null)
                  Text(
                    'Steam ID: ${s.steamId}',
                    style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
                  ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _openProfile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _neon,
                    side: BorderSide(color: _neon.withValues(alpha: 0.8)),
                  ),
                  child: const Text('OPEN STEAM PROFILE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _steamPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _neon.withValues(alpha: 0.5)),
      ),
      child: const Center(
        child: Text(
          'CS2',
          style: TextStyle(color: _neon, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _placeholderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DETAILED MATCH HISTORY',
            style: TextStyle(
              color: Color(0xFF39FF14),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'CS2 detailed stats and recent competitive history will appear here once the platform exposes Steam Web API summaries (GetUserStatsForGame / owned games).',
            style: TextStyle(color: Color(0xFF7A86AC), height: 1.45),
          ),
        ],
      ),
    );
  }
}
