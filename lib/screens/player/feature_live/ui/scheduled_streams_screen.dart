import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/stream_api.dart';
import 'package:arena_chain_flutter/core/models/stream_model.dart';
<<<<<<< HEAD
import 'package:arena_chain_flutter/navigation.dart';
import 'package:intl/intl.dart';

class ScheduledStreamsScreen extends StatefulWidget {
  const ScheduledStreamsScreen({super.key});

=======
import 'package:arena_chain_flutter/core/models/channel_model.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:intl/intl.dart';

/// ARENA LIVE — same visual language as [PlayerHomeScreen] (black, neon #39FF14, soft glow).
class ScheduledStreamsScreen extends StatefulWidget {
  const ScheduledStreamsScreen({super.key});

  static const Color neon = Color(0xFF39FF14);

>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
  @override
  State<ScheduledStreamsScreen> createState() => _ScheduledStreamsScreenState();
}

class _ScheduledStreamsScreenState extends State<ScheduledStreamsScreen> {
  final StreamApi _streamApi = StreamApi();
<<<<<<< HEAD
  List<StreamModel> _streams = [];
  bool _isLoading = true;
=======
  List<StreamModel> _liveStreams = [];
  List<StreamModel> _scheduledStreams = [];
  bool _isLoading = true;
  bool _usingDemoData = false;
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
<<<<<<< HEAD
    setState(() => _isLoading = true);
    final results = await _streamApi.getAllStreams();
    setState(() {
      _streams = results;
      _isLoading = false;
    });
=======
    setState(() {
      _isLoading = true;
      _usingDemoData = false;
    });
    try {
      final fromLiveEndpoint = await _streamApi.getLiveStreams();
      final all = await _streamApi.getAllStreams();

      var live = fromLiveEndpoint.isNotEmpty
          ? fromLiveEndpoint
          : all.where((s) => s.isLive).toList();
      final scheduled = all.where((s) => !s.isLive).toList();

      var usingDemo = false;
      if (live.isEmpty && scheduled.isEmpty) {
        live = _demoLiveStreams();
        usingDemo = true;
      }

      setState(() {
        _liveStreams = live;
        _scheduledStreams = scheduled;
        _usingDemoData = usingDemo;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _liveStreams = _demoLiveStreams();
        _scheduledStreams = _demoScheduledStreams();
        _usingDemoData = true;
        _isLoading = false;
      });
    }
  }

  /// Curated demo rows so the Live tab matches the home mock when the API is empty.
  static List<StreamModel> _demoLiveStreams() {
    return [
      StreamModel(
        id: 'arena-demo-live-1',
        title: 'VCT EMEA Masters — Semifinals',
        description: 'Live coverage',
        streamerId: 'demo',
        channelId: 'ch-val',
        isLive: true,
        viewerCount: 18420,
        thumbnailUrl:
            'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=1200&auto=format&fit=crop',
        tags: const ['Valorant', 'Esports'],
        channel: Channel(id: 'ch-val', name: 'VALORANT Esports', ownerId: 'riot'),
      ),
      StreamModel(
        id: 'arena-demo-live-2',
        title: 'Ranked Grind — Radiant push',
        streamerId: 'demo',
        channelId: 'ch-pro',
        isLive: true,
        viewerCount: 3204,
        thumbnailUrl:
            'https://images.unsplash.com/photo-1511512578047-dfb367046420?q=80&w=1200&auto=format&fit=crop',
        tags: const ['League of Legends'],
        channel: Channel(id: 'ch-pro', name: 'ProPlayer_TV', ownerId: 'p1'),
      ),
      StreamModel(
        id: 'arena-demo-live-3',
        title: 'CS2 FACEIT Level 10 — Full stack',
        streamerId: 'demo',
        channelId: 'ch-cs',
        isLive: true,
        viewerCount: 892,
        thumbnailUrl:
            'https://images.unsplash.com/photo-1614013409192-3435163158e0?q=80&w=1200&auto=format&fit=crop',
        tags: const ['CS2'],
        channel: Channel(id: 'ch-cs', name: 'headshotHQ', ownerId: 'cs1'),
      ),
    ];
  }

  static List<StreamModel> _demoScheduledStreams() {
    final start = DateTime.now().add(const Duration(hours: 2));
    return [
      StreamModel(
        id: 'arena-demo-sch-1',
        title: 'Arena Night Show — Patch rundown',
        streamerId: 'demo',
        channelId: 'ch-arena',
        isLive: false,
        scheduledStartTime: start,
        thumbnailUrl:
            'https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?q=80&w=1200&auto=format&fit=crop',
        channel: Channel(id: 'ch-arena', name: 'Arena Chain', ownerId: 'ac'),
      ),
    ];
  }

  void _openStream(StreamModel stream) {
    if (stream.id.startsWith('arena-demo')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demo stream — connect your /stream API to go live.',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.87)),
          ),
          backgroundColor: ScheduledStreamsScreen.neon.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pushNamed(context, AppRoutes.liveStream, arguments: stream.id);
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C08),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ARENA LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF00FF00),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSection('EN DIRECT', _streams.where((s) => s.isLive).toList()),
                  const SizedBox(height: 32),
                  _buildSection('PROGRAMMÉ', _streams.where((s) => !s.isLive).toList()),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<StreamModel> streams) {
    if (streams.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 4),
        ),
        const SizedBox(height: 16),
        ...streams.map((stream) => _buildStreamCard(stream)),
      ],
    );
  }

  Widget _buildStreamCard(StreamModel stream) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.liveStream, arguments: stream.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF16181D).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Container(
                      color: Colors.black,
                      width: double.infinity,
                      child: stream.thumbnailUrl != null 
                        ? Image.network(stream.thumbnailUrl!, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.5))
                        : const Icon(Icons.videocam_outlined, color: Colors.white10, size: 48),
                    ),
                    if (stream.isLive)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0000),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
=======
    const neon = ScheduledStreamsScreen.neon;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: neon))
            : RefreshIndicator(
                color: neon,
                backgroundColor: const Color(0xFF0A0A0A),
                onRefresh: _load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ARENA LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(color: neon.withValues(alpha: 0.45), blurRadius: 12),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh_rounded, color: neon.withValues(alpha: 0.95)),
                              onPressed: _load,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_usingDemoData)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Sample streams — your API returned no rows.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_liveStreams.isNotEmpty) ...[
                      _sectionTitleSliver('LIVE NOW', neon),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _StreamCardNeo(
                                stream: _liveStreams[i],
                                neon: neon,
                                onTap: () => _openStream(_liveStreams[i]),
                              ),
                            ),
                            childCount: _liveStreams.length,
                          ),
                        ),
                      ),
                    ],
                    if (_scheduledStreams.isNotEmpty) ...[
                      _sectionTitleSliver('UPCOMING', neon),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _StreamCardNeo(
                                stream: _scheduledStreams[i],
                                neon: neon,
                                onTap: () => _openStream(_scheduledStreams[i]),
                              ),
                            ),
                            childCount: _scheduledStreams.length,
                          ),
                        ),
                      ),
                    ],
                    if (_liveStreams.isEmpty && _scheduledStreams.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No streams scheduled.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                          ),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
                        ),
                      ),
                  ],
                ),
              ),
<<<<<<< HEAD
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stream.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stream.channel?.name ?? 'Studio',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (!stream.isLive && stream.scheduledStartTime != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('START', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
                          Text(
                            DateFormat('HH:mm').format(stream.scheduledStartTime!),
                            style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
=======
      ),
    );
  }

  static Widget _sectionTitleSliver(String title, Color neon) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: TextStyle(
            color: neon.withValues(alpha: 0.85),
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _StreamCardNeo extends StatelessWidget {
  final StreamModel stream;
  final Color neon;
  final VoidCallback onTap;

  const _StreamCardNeo({
    required this.stream,
    required this.neon,
    required this.onTap,
  });

  static String _viewers(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: neon.withValues(alpha: 0.12), blurRadius: 18, offset: Offset.zero),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: neon.withValues(alpha: 0.28)),
              color: const Color(0xFF0A0A0A),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (stream.thumbnailUrl != null && stream.thumbnailUrl!.isNotEmpty)
                        Image.network(
                          stream.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFF121212),
                            child: Icon(Icons.videocam_outlined, color: neon.withValues(alpha: 0.35), size: 40),
                          ),
                        )
                      else
                        Container(
                          color: const Color(0xFF121212),
                          child: Icon(Icons.videocam_outlined, color: neon.withValues(alpha: 0.35), size: 40),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                      if (stream.isLive) ...[
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: neon.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: neon.withValues(alpha: 0.55)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fiber_manual_record, size: 10, color: neon.withValues(alpha: 0.95)),
                                const SizedBox(width: 6),
                                Text(
                                  '((o)) LIVE',
                                  style: TextStyle(
                                    color: neon.withValues(alpha: 0.95),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (stream.viewerCount > 0)
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: neon.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_outlined, size: 12, color: neon.withValues(alpha: 0.9)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _viewers(stream.viewerCount),
                                    style: TextStyle(
                                      color: neon.withValues(alpha: 0.95),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ] else if (stream.scheduledStartTime != null)
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: neon.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              'UPCOMING',
                              style: TextStyle(
                                color: neon.withValues(alpha: 0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stream.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              stream.channel?.name ?? 'Arena Channel',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!stream.isLive && stream.scheduledStartTime != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'START',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm').format(stream.scheduledStartTime!),
                              style: TextStyle(
                                color: neon.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
          ),
        ),
      ),
    );
  }
}
