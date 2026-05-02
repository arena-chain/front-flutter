import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/core/models/video_model.dart';
import 'package:arena_chain_flutter/screens/scouter/view_model/scouter_player_detail_view_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_profile/ui/video_player_screen.dart';
import 'package:arena_chain_flutter/screens/scouter/ui/scouter_highlight_detail_screen.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';

// ─────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────

Color _tierColor(String tier) {
  switch (tier.toUpperCase()) {
    case 'RADIANT':
    case 'GRANDMASTER':
      return const Color(0xFFFF4444);
    case 'IMMORTAL':
    case 'CHALLENGER':
      return const Color(0xFFFF6644);
    case 'MASTER':
      return const Color(0xFFAA44FF);
    case 'DIAMOND':
      return const Color(0xFF4488FF);
    case 'PLATINUM':
      return const Color(0xFF44DDAA);
    case 'GOLD':
      return const Color(0xFFFFCC00);
    case 'SILVER':
      return const Color(0xFFCCCCCC);
    default:
      return const Color(0xFF00FF00);
  }
}

// ─────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────

class ScouterPlayerDetailScreen extends StatefulWidget {
  final String playerUserId;
  final String scouterId;
  final VoidCallback? onReportCreated;
  final PlayerDetail? initialPlayer;

  const ScouterPlayerDetailScreen({
    super.key,
    required this.playerUserId,
    required this.scouterId,
    this.initialPlayer,
    this.onReportCreated,
  });

  @override
  State<ScouterPlayerDetailScreen> createState() =>
      _ScouterPlayerDetailScreenState();
}

class _ScouterPlayerDetailScreenState extends State<ScouterPlayerDetailScreen> {
  late final ScouterPlayerDetailViewModel _vm;
  bool _expandBio = false;

  @override
  void initState() {
    super.initState();
    _vm = ScouterPlayerDetailViewModel(
      scouterId: widget.scouterId,
      initialPlayer: widget.initialPlayer,
    );
    _vm.loadPlayer(widget.playerUserId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<ScouterPlayerDetailViewModel>(
        builder: (ctx, vm, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (vm.actionSuccess != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(vm.actionSuccess!),
                backgroundColor: const Color(0xFF00FF00).withValues(alpha: 0.9),
              ));
              vm.clearAction();
            } else if (vm.error != null) {
              // Don't show raw API errors (e.g. "Cannot GET/POST /api/...") to the user
              final isApiError = vm.error!.contains('Cannot GET') ||
                  vm.error!.contains('Cannot POST') ||
                  vm.error!.contains('404') || vm.error!.contains('500') ||
                  vm.error!.toLowerCase().contains('not found') ||
                  vm.error!.toLowerCase().contains('failed to load');
              if (!isApiError) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(vm.error!),
                  backgroundColor: const Color(0xFFFF0055).withValues(alpha: 0.9),
                ));
              }
              vm.clearAction();
            }
          });

          return Scaffold(
            backgroundColor: const Color(0xFF0A0E1A),
            body: vm.isLoading &&
                    vm.player == null &&
                    vm.playerIdentity == null
                ? _loading()
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroSection(ctx, vm),
                        _playerMeta(vm),
                        _pillTags(vm),
                        _aboutSection(vm),
                        _statsRow(vm),
                        _channelVideosSection(ctx, vm),
                        _streamingClipsSection(ctx, vm),
                        if (vm.ranks.isNotEmpty) _ranksSection(vm),
                        _matchHistorySection(vm),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────

  Widget _loading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: const Color(0xFF00FF00),
              strokeWidth: 2.5,
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading profile…',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Banner ─────────────────────────────────────────────

  Widget _heroSection(BuildContext ctx, ScouterPlayerDetailViewModel vm) {
    final tier = vm.player?.tier ?? vm.player?.rank ?? 'UNRANKED';
    final tColor = _tierColor(tier);

    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Clean dark gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF040609), Color(0xFF0A0E1A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Deep atmospheric glow
          Positioned(
            top: -150, left: -100, right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 0.8,
                  colors: [tColor.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          // Watermark initial
          Positioned(
            right: 20, top: 60,
            child: Text(
              vm.displayNickname.isNotEmpty ? vm.displayNickname[0].toUpperCase() : '?',
              style: TextStyle(
                color: tColor.withValues(alpha: 0.06),
                fontSize: 140,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // Bottom fade
          Positioned(
            left: 0, right: 0, bottom: 0,
            height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFF0A0E1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Nav buttons - glass style
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navCircleBtn(icon: Icons.arrow_back_ios_new, onTap: () => Navigator.pop(ctx)),
                  _navCircleBtn(
                    icon: Icons.refresh_rounded,
                    onTap: vm.isLoading
                        ? null
                        : () => vm.loadPlayer(widget.playerUserId),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navCircleBtn({
    required IconData icon,
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // ── Player Meta (Avatar + Name) ────────────────────────────

  Widget _playerMeta(ScouterPlayerDetailViewModel vm) {
    final nickname = vm.displayNickname;
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : '?';
    final tier = vm.player?.tier ?? vm.player?.rank ?? 'UNRANKED';
    final isPro = vm.player?.isPro ?? false;
    final tColor = _tierColor(tier);
    final teamName = vm.player?.team?.name;
    final avatarUrl = vm.displayAvatar;
    final country = vm.displayCountry;

    return Transform.translate(
      offset: const Offset(0, -44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Hyper-modern avatar
            Container(
              width: 104, height: 104,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [tColor.withValues(alpha: 0.8), tColor.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tColor.withValues(alpha: 0.25),
                    blurRadius: 32,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF040609),
                  shape: BoxShape.circle,
                ),
                child: avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(initial,
                                style: TextStyle(color: tColor, fontSize: 40, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: tColor,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isPro) ...[
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF00).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, color: Color(0xFF00FF00), size: 16),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          nickname,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (country.isNotEmpty) ...[                    
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.public_rounded, color: Color(0xFF8B95A5), size: 12),
                      const SizedBox(width: 4),
                      Text(country,
                          style: const TextStyle(color: Color(0xFF8B95A5), fontSize: 12)),
                    ]),
                  ],
                  if (teamName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      teamName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111625).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, color: Color(0xFF00FF00), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${vm.player?.elo ?? 0} ELO',
                              style: const TextStyle(
                                color: Color(0xFF00FF00),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111625).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Text(
                          tier,
                          style: TextStyle(
                            color: tColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pill Tags ──────────────────────────────────────────────

  Widget _pillTags(ScouterPlayerDetailViewModel vm) {
    final tags = <String>[
      vm.player?.region ?? 'GLOBAL',
      vm.player?.isPro == true ? 'PRO' : 'AMATEUR',
    ];

    return Transform.translate(
      offset: const Offset(0, -28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: tags.map((t) => _pillTag(t)).toList(),
        ),
      ),
    );
  }

  Widget _pillTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── About Section ──────────────────────────────────────────

  Widget _aboutSection(ScouterPlayerDetailViewModel vm) {
    final nickname = vm.displayNickname;
    final country = vm.displayCountry;
    final team = vm.player?.team?.name;
    final riotName = vm.player?.riotGameName;
    final linked = vm.player?.isRiotLinked ?? false;
    final bioParts = [
      'Player profile for $nickname.',
      if (country.isNotEmpty) 'Based in $country.',
      if (team != null) 'Currently playing for $team.',
      if (riotName != null && riotName.isNotEmpty) 'Riot ID: $riotName.',
      if (!linked) 'Riot account not linked.',
      'Browse their channel videos and short clips below — ranked by community reactions.',
    ];
    final bio = bioParts.join(' ');

    final displayText = _expandBio
        ? bio
        : '${bio.substring(0, math.min(bio.length, 100))}...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111625).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4, height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF00),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'About This Player',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: displayText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => setState(() => _expandBio = !_expandBio),
                          child: Text(
                            _expandBio ? '  Show Less' : '  Read More',
                            style: const TextStyle(
                              color: Color(0xFF00FF00),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────

  Widget _statsRow(ScouterPlayerDetailViewModel vm) {
    final matches = vm.matches.length;
    final wins = vm.matches.where((m) => m.team1GamesWon > m.team2GamesWon).length;
    final hours = vm.player?.stats?['hoursPlayed'] ?? vm.player?.stats?['hours'] ?? '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          Expanded(child: _statCard(Icons.sports_esports_rounded, '$matches', 'Matches')),
          const SizedBox(width: 12),
          Expanded(child: _statCard(Icons.emoji_events_rounded, '$wins', 'Victories')),
          const SizedBox(width: 12),
          Expanded(child: _statCard(Icons.schedule_rounded, '$hours', 'Hours Played')),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111625).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF00FF00), size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Channel videos (VODs) ──────────────────────────────────

  Widget _channelVideosSection(BuildContext context, ScouterPlayerDetailViewModel vm) {
    final vods = vm.playerVideos.where((v) => v.status == VideoStatus.approved).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Row(
            children: [
              const Icon(Icons.video_library_rounded, color: Color(0xFF00FF00), size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Videos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Full uploads from this player',
                      style: TextStyle(
                        color: Color(0xFF8B95A5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${vods.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (vods.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Center(
                child: Text(
                  'No published videos yet',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: vods.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, i) {
              final v = vods[i];
              final url = _resolveVideoUrl(v.videoUrl);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: url == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => VideoPlayerScreen(
                                videoUrl: url,
                                title: v.title,
                              ),
                            ),
                          );
                        },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(color: Colors.black.withValues(alpha: 0.5)),
                              if (v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty)
                                Image.network(
                                  v.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(),
                                ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatVideoDuration(v.duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${v.views} views',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.45),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (url == null)
                                Text(
                                  'No URL',
                                  style: TextStyle(
                                    color: Colors.red.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _formatVideoDuration(int? sec) {
    if (sec == null || sec <= 0) return '—';
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ── Short clips (highlights) — pro streaming style ─────────

  Widget _streamingClipsSection(BuildContext context, ScouterPlayerDetailViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF00FF88), size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Highlight clips',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Short moments · ranked by likes & comments',
                      style: TextStyle(
                        color: Color(0xFF8B95A5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${vm.highlights.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        vm.highlights.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Center(
                    child: Text(
                      'No clips yet',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                    ),
                  ),
                ),
              )
            : SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  itemCount: vm.highlights.length,
                  itemBuilder: (ctx, i) => _highlightCard(ctx, vm.highlights[i]),
                ),
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Match history (compact, no scouting tabs) ───────────────

  Widget _matchHistorySection(ScouterPlayerDetailViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Row(
            children: [
              Icon(Icons.sports_esports_rounded, color: Colors.white.withValues(alpha: 0.5), size: 20),
              const SizedBox(width: 10),
              const Text(
                'Match history',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${vm.matches.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (vm.matches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'No recorded matches',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: vm.matches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final m = vm.matches[i];
              final win = m.team1GamesWon > m.team2GamesWon;
              final c = win ? const Color(0xFF00FF00) : const Color(0xFFFF0055);
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            win ? 'Victory' : 'Defeat',
                            style: TextStyle(
                              color: c,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (m.scheduledStart != null)
                            Text(
                              m.scheduledStart!.length >= 10
                                  ? m.scheduledStart!.substring(0, 10)
                                  : m.scheduledStart!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${m.team1GamesWon} – ${m.team2GamesWon}',
                      style: TextStyle(
                        color: c,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  String? _resolveVideoUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final url = rawUrl.trim();
    final backend = Uri.parse(ApiConfig.baseUrl);

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final normalizedPath = url.startsWith('/') ? url : '/$url';
      return '${backend.scheme}://${backend.host}${backend.hasPort ? ':${backend.port}' : ''}$normalizedPath';
    }

    if (url.startsWith('http://localhost') || url.startsWith('https://localhost')) {
      final pathStart = url.indexOf('/', url.indexOf('://') + 3);
      final path = pathStart >= 0 ? url.substring(pathStart) : '';
      return '${backend.scheme}://${backend.host}${backend.hasPort ? ':${backend.port}' : ''}$path';
    }

    final parsed = Uri.tryParse(url);
    if (parsed != null &&
        parsed.host.isNotEmpty &&
        parsed.host != backend.host &&
        parsed.path.startsWith('/uploads/')) {
      return '${backend.scheme}://${backend.host}${backend.hasPort ? ':${backend.port}' : ''}${parsed.path}';
    }

    return url;
  }

  Widget _highlightCard(BuildContext context, HighlightItem h) {
    final isProcessedClip =
        h.clipUrl != null && h.clipUrl!.trim().isNotEmpty;
    final playableUrl = resolveHighlightMediaUrl(h.playableUrl) ??
        _resolveVideoUrl(h.videoUrl);

    void open() {
      if (isProcessedClip) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ScouterHighlightDetailScreen(highlight: h),
          ),
        );
      } else if (playableUrl != null) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => VideoPlayerScreen(
              videoUrl: playableUrl,
              title: h.title,
            ),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: (isProcessedClip || playableUrl != null) ? open : null,
      child: Container(
      width: 148,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FF00).withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 138,
            child: Stack(
              children: [
                if (h.thumbnailUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      h.thumbnailUrl!,
                      fit: BoxFit.cover,
                      width: 148,
                      height: 138,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF00).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00FF00), width: 2),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF00FF00), size: 26),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Text(
              h.title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isProcessedClip)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: FutureBuilder<Map<String, dynamic>>(
                future: ScouterRepository().getHighlightEngagement(h.id),
                builder: (ctx, snap) {
                  final likes = (snap.data?['likeCount'] as num?)?.toInt();
                  final comments = (snap.data?['commentCount'] as num?)?.toInt();
                  if (likes == null && comments == null) {
                    return const SizedBox(height: 14);
                  }
                  return Row(
                    children: [
                      Icon(Icons.favorite, size: 12, color: Colors.pinkAccent.withValues(alpha: 0.9)),
                      const SizedBox(width: 3),
                      Text(
                        '${likes ?? 0}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.chat_bubble_outline, size: 11, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 3),
                      Text(
                        '${comments ?? 0}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    ));
  }

  // ── Ranks Section ──────────────────────────────────────────────────────────

  Widget _ranksSection(ScouterPlayerDetailViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child: Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFAA00),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Game Ranks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 24, right: 8),
            itemCount: vm.ranks.length,
            itemBuilder: (_, i) => _rankCard(vm.ranks[i]),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _rankCard(RankEntry r) {
    final tColor = _tierColor(r.tier);
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.gameTitle.isEmpty ? 'Game' : r.gameTitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            r.tier,
            style: TextStyle(
              color: tColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${r.elo} ELO',
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${r.wins}W  ${r.losses}L  ${r.winRate}%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
