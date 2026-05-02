import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/stream_api.dart';
import 'package:arena_chain_flutter/core/models/stream_model.dart';
import 'package:arena_chain_flutter/core/services/live_catalog_service.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/screens/player/feature_live/ui/arena_live_stream_card.dart';
import 'package:flutter/material.dart';

// ── Sort options ─────────────────────────────────────────────────────────────

enum _StreamSort {
  mostViewed,
  recent,
  alphabetical;

  String get label {
    switch (this) {
      case _StreamSort.mostViewed:
        return 'Plus regardés';
      case _StreamSort.recent:
        return 'Récents';
      case _StreamSort.alphabetical:
        return 'A → Z';
    }
  }

  IconData get icon {
    switch (this) {
      case _StreamSort.mostViewed:
        return Icons.trending_up_rounded;
      case _StreamSort.recent:
        return Icons.access_time_rounded;
      case _StreamSort.alphabetical:
        return Icons.sort_by_alpha_rounded;
    }
  }
}

/// ARENA LIVE â€” same visual language as [PlayerHomeScreen] (black, neon #39FF14, soft glow).
class ScheduledStreamsScreen extends StatefulWidget {
  const ScheduledStreamsScreen({super.key});

  static const Color neon = Color(0xFF39FF14);

  @override
  State<ScheduledStreamsScreen> createState() => _ScheduledStreamsScreenState();
}

class _ScheduledStreamsScreenState extends State<ScheduledStreamsScreen> {
  final LiveCatalogService _liveCatalogService = LiveCatalogService();

  List<StreamModel> _liveStreams = [];
  List<StreamModel> _scheduledStreams = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ── Search & Sort ─────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _StreamSort _sortOrder = _StreamSort.mostViewed;

  @override
  void initState() {
    super.initState();
    _load();
    _liveCatalogService.startRealtimeSync(
      onCatalogChanged: _refreshSilently,
    );
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _liveCatalogService.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final snapshot = await _liveCatalogService.fetchSnapshot();
      if (!mounted) {
        return;
      }

      setState(() {
        _liveStreams = snapshot.liveStreams;
        _scheduledStreams = snapshot.scheduledStreams;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _liveStreams = [];
        _scheduledStreams = [];
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSilently() async {
    if (_isLoading) {
      return;
    }

    try {
      final snapshot = await _liveCatalogService.fetchSnapshot();
      if (!mounted) {
        return;
      }

      setState(() {
        _liveStreams = snapshot.liveStreams;
        _scheduledStreams = snapshot.scheduledStreams;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted || _liveStreams.isNotEmpty || _scheduledStreams.isNotEmpty) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to refresh live streams.';
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
  }

  // ── Filtered & sorted lists ───────────────────────────────────────────

  List<StreamModel> get _filteredLive => _applyFilter(_liveStreams);
  List<StreamModel> get _filteredScheduled => _applyFilter(_scheduledStreams);

  List<StreamModel> _applyFilter(List<StreamModel> source) {
    var list = source.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          (s.description?.toLowerCase().contains(q) ?? false) ||
          s.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();

    switch (_sortOrder) {
      case _StreamSort.mostViewed:
        list.sort((a, b) => b.viewerCount.compareTo(a.viewerCount));
      case _StreamSort.recent:
        list.sort((a, b) {
          final aTime = a.startedAt ?? a.scheduledStartTime ?? DateTime(0);
          final bTime = b.startedAt ?? b.scheduledStartTime ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
      case _StreamSort.alphabetical:
        list.sort((a, b) => a.title.compareTo(b.title));
    }
    return list;
  }

  // ── Search + Sort bar ────────────────────────────────────────────────

  Widget _buildSearchAndSort(Color neon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Search bar
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: neon.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search_rounded,
                    size: 18, color: neon.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, height: 1.2),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un live, un tag…',
                      hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => _searchCtrl.clear(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.close_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Sort pills
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _StreamSort.values
                  .map((sort) => _sortPill(sort, neon))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortPill(_StreamSort sort, Color neon) {
    final selected = _sortOrder == sort;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _sortOrder = sort),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? neon.withValues(alpha: 0.12)
                : const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? neon.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: neon.withValues(alpha: 0.12),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                sort.icon,
                size: 13,
                color:
                    selected ? neon : Colors.white.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 5),
              Text(
                sort.label,
                style: TextStyle(
                  color: selected
                      ? neon
                      : Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const neon = ScheduledStreamsScreen.neon;
    final filteredLive = _filteredLive;
    final filteredScheduled = _filteredScheduled;
    final hasContent = filteredLive.isNotEmpty || filteredScheduled.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: neon))
            : RefreshIndicator(
                color: neon,
                backgroundColor: const Color(0xFF0A0A0A),
                onRefresh: () => _load(showLoader: false),
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
                                    Shadow(
                                      color: neon.withValues(alpha: 0.45),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.refresh_rounded,
                                color: neon.withValues(alpha: 0.95),
                              ),
                              onPressed: () => _load(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ── Search & Sort bar ─────────────────────────────
                    SliverToBoxAdapter(
                      child: _buildSearchAndSort(neon),
                    ),
                    if (_errorMessage != null && hasContent)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_errorMessage != null && !hasContent)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Unable to load live streams.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => _load(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: neon,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else ...[
                      if (filteredLive.isNotEmpty) ...[
                        _sectionTitleSliver('LIVE NOW', neon),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ArenaLiveStreamCard(
                                  stream: filteredLive[index],
                                  neon: neon,
                                  onTap: () => _openStream(filteredLive[index]),
                                ),
                              ),
                              childCount: filteredLive.length,
                            ),
                          ),
                        ),
                      ],
                      if (filteredScheduled.isNotEmpty) ...[
                        _sectionTitleSliver('UPCOMING', neon),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ArenaLiveStreamCard(
                                  stream: filteredScheduled[index],
                                  neon: neon,
                                  onTap: () =>
                                      _openStream(filteredScheduled[index]),
                                ),
                              ),
                              childCount: filteredScheduled.length,
                            ),
                          ),
                        ),
                      ],
                      if (!hasContent)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _searchQuery.isNotEmpty
                                      ? Icons.search_off_rounded
                                      : Icons.live_tv_rounded,
                                  size: 48,
                                  color: neon.withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Aucun résultat pour "$_searchQuery"'
                                      : 'Aucun live en ce moment.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
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
