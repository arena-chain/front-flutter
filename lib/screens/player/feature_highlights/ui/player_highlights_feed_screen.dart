import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/screens/player/feature_highlights/viewmodel/highlights_feed_view_model.dart';

class PlayerHighlightsFeedScreen extends StatefulWidget {
  const PlayerHighlightsFeedScreen({super.key});

  @override
  State<PlayerHighlightsFeedScreen> createState() =>
      _PlayerHighlightsFeedScreenState();
}

class _PlayerHighlightsFeedScreenState extends State<PlayerHighlightsFeedScreen> {
  static const Color _neon = Color(0xFF39FF14);
  final PageController _pageController = PageController();

  VideoPlayerController? _video;
  int _activeIndex = 0;
  bool _advancing = false;
  bool _videoReady = false;
  String? _videoError;
  String? _loadedHighlightId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<HighlightsFeedViewModel>().load();
      if (!mounted) return;
      final items = context.read<HighlightsFeedViewModel>().items;
      if (items.isNotEmpty) {
        await _setActive(items, _activeIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _video?.dispose();
    super.dispose();
  }

  String? _resolveMediaUrl(String? rawUrl) {
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

  Future<void> _setActive(List<HighlightItem> items, int index) async {
    if (items.isEmpty || index < 0 || index >= items.length) return;
    final h = items[index];
    if (_loadedHighlightId == h.id && _video != null) return;

    _loadedHighlightId = h.id;
    _videoError = null;
    _videoReady = false;
    setState(() {});

    final old = _video;
    _video = null;
    await old?.dispose();

    final playable = _resolveMediaUrl(h.playableUrl);
    if (playable == null) {
      _videoError = 'No playable URL';
      setState(() {});
      return;
    }

    final ctrl = VideoPlayerController.networkUrl(Uri.parse(playable));
    _video = ctrl;
    try {
      await ctrl.initialize();
      if (!mounted || _loadedHighlightId != h.id) return;
      ctrl
        ..setVolume(1)
        ..play();
      ctrl.addListener(() => _onVideoTick(items));
      _videoReady = true;
      _videoError = null;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _videoError = e.toString();
      setState(() {});
    }
  }

  void _onVideoTick(List<HighlightItem> items) {
    final v = _video;
    if (v == null || !v.value.isInitialized || _advancing) return;
    final pos = v.value.position;
    final dur = v.value.duration;
    if (dur.inMilliseconds <= 0) return;
    if (pos >= dur - const Duration(milliseconds: 220)) {
      _advancing = true;
      final next = (_activeIndex + 1) % items.length;
      _pageController
          .animateToPage(
            next,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          )
          .whenComplete(() => _advancing = false);
    }
  }

  String _creator(HighlightItem h) {
    final c = h.raw['creator'];
    if (c is Map) {
      return (c['nickname'] ?? c['username'] ?? c['displayName'] ?? 'creator')
          .toString();
    }
    return 'creator';
  }

  Future<void> _refresh() async {
    await context.read<HighlightsFeedViewModel>().load(refresh: true);
    if (!mounted) return;
    final items = context.read<HighlightsFeedViewModel>().items;
    _activeIndex = 0;
    if (items.isNotEmpty) {
      _pageController.jumpToPage(0);
      await _setActive(items, 0);
    } else {
      await _video?.dispose();
      _video = null;
      _loadedHighlightId = null;
      _videoReady = false;
      _videoError = null;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Consumer<HighlightsFeedViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.items.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: _neon));
          }
          if (vm.error case final String err when vm.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.red.withValues(alpha: 0.85),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      err,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _refresh,
                      style: FilledButton.styleFrom(
                        backgroundColor: _neon,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (vm.items.isEmpty) {
            return Center(
              child: Text(
                'No public highlights yet',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: vm.items.length,
                onPageChanged: (index) async {
                  _activeIndex = index;
                  await _setActive(vm.items, index);
                },
                itemBuilder: (context, index) {
                  final h = vm.items[index];
                  final isActive = index == _activeIndex;
                  return _ReelPage(
                    highlight: h,
                    isActive: isActive,
                    video: isActive ? _video : null,
                    videoReady: isActive && _videoReady,
                    videoError: isActive ? _videoError : null,
                    creator: _creator(h),
                  );
                },
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                        onPressed: _refresh,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReelPage extends StatelessWidget {
  const _ReelPage({
    required this.highlight,
    required this.isActive,
    required this.video,
    required this.videoReady,
    required this.videoError,
    required this.creator,
  });

  final HighlightItem highlight;
  final bool isActive;
  final VideoPlayerController? video;
  final bool videoReady;
  final String? videoError;
  final String creator;

  @override
  Widget build(BuildContext context) {
    final thumb = highlight.thumbnailUrl;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final overlayBottom = bottomInset + 110;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: (isActive && video != null && videoReady)
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: video!.value.size.width,
                    height: video!.value.size.height,
                    child: VideoPlayer(video!),
                  ),
                )
              : thumb != null && thumb.isNotEmpty
                  ? Image.network(
                      thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: Colors.black54),
                    )
                  : const ColoredBox(color: Colors.black54),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.65),
              ],
            ),
          ),
        ),
        if (isActive && !videoReady && videoError == null)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF39FF14)),
          ),
        if (isActive && videoError != null)
          Center(
            child: Text(
              'Unable to play clip',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: overlayBottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                highlight.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '@$creator',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Swipe up/down',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
