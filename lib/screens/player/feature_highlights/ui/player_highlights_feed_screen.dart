import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, AssetManifest;
import 'package:video_player/video_player.dart';

/// Static reels viewer for the Reels tab.
///
/// Loads every MP4 found under `assets/images/reels/` (declared in
/// `pubspec.yaml`). To add a reel: drop the MP4 into `assets/images/reels/`,
/// run `flutter pub get`, then `flutter clean && flutter run`. No code change.
///
/// Action rail (likes / comments / share) and the bottom Invite button are
/// **static** in this phase — counters and toggles live in local state. The
/// next prompt wires them to the highlights API.
class PlayerHighlightsFeedScreen extends StatefulWidget {
  const PlayerHighlightsFeedScreen({super.key, this.onBack});

  /// Called when the player taps the back arrow at top-left. The parent
  /// (`player_home.dart`) routes this to `_onNavTap(0)` so the Home tab
  /// becomes active again. If `null`, the back button isn't rendered.
  final VoidCallback? onBack;

  @override
  State<PlayerHighlightsFeedScreen> createState() =>
      _PlayerHighlightsFeedScreenState();
}

class _PlayerHighlightsFeedScreenState
    extends State<PlayerHighlightsFeedScreen> {
  static const Color _neon = Color(0xFF39FF14);
  static const String _assetPrefix = 'assets/images/reels/';
  static const Duration _videoEndThreshold = Duration(milliseconds: 220);

  final PageController _pageController = PageController();

  List<_StaticReel> _reels = const [];
  bool _loadingManifest = true;
  String? _manifestError;

  VideoPlayerController? _video;
  int _activeIndex = 0;
  bool _videoReady = false;
  String? _videoError;
  bool _advancing = false;
  String? _loadedAssetPath;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _loadAssetManifest();
  }

  @override
  void dispose() {
    _pageController.dispose();
    final v = _video;
    if (v != null) {
      v.removeListener(_onVideoTick);
      v.dispose();
    }
    super.dispose();
  }

  // ─── Asset discovery (Flutter 3.16+ API) ─────────────────────────────────

  Future<void> _loadAssetManifest() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final keys = manifest
          .listAssets()
          .where((k) => k.startsWith(_assetPrefix))
          .where((k) => k.toLowerCase().endsWith('.mp4'))
          .toList()
        ..sort();
      if (!mounted) return;
      setState(() {
        _reels = keys
            .map(
              (path) => _StaticReel(
                assetPath: path,
                title: _titleFromAsset(path),
                creator: _creatorFromAsset(path),
                caption: _captionFromAsset(path),
              ),
            )
            .toList();
        _loadingManifest = false;
      });
      if (_reels.isNotEmpty) {
        await _setActive(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _manifestError = 'Could not load reels: $e';
        _loadingManifest = false;
      });
    }
  }

  String _titleFromAsset(String assetPath) {
    final name = assetPath.split('/').last;
    final base = name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final lower = base.toLowerCase();
    if (lower == 'cs') return 'CS2 highlight';
    if (lower == 'lolc') return 'League of Legends highlight';
    if (lower == 'val') return 'Valorant highlight';
    if (lower == 'dota') return 'Dota 2 highlight';
    return base
        .replaceAll(RegExp(r'[-_]'), ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _creatorFromAsset(String assetPath) {
    final name = assetPath.split('/').last.toLowerCase();
    if (name.startsWith('cs')) return 'CS2Pro';
    if (name.startsWith('lolc')) return 'LoLChamp';
    if (name.startsWith('val')) return 'ValAce';
    if (name.startsWith('dota')) return 'DotaKing';
    return 'ArenaPlayer';
  }

  String _captionFromAsset(String assetPath) {
    final name = assetPath.split('/').last.toLowerCase();
    if (name.startsWith('cs')) return 'Clutch round, full team wipe.';
    if (name.startsWith('lolc')) return 'Pentakill highlight from ranked.';
    if (name.startsWith('val')) return 'Ace play on defense.';
    if (name.startsWith('dota')) return 'Rampage mid-game from offlane.';
    return 'New highlight.';
  }

  // ─── Video activation / paging ───────────────────────────────────────────

  Future<void> _setActive(int index) async {
    if (_reels.isEmpty || index < 0 || index >= _reels.length) return;
    final reel = _reels[index];
    if (_loadedAssetPath == reel.assetPath && _video != null) return;

    _loadedAssetPath = reel.assetPath;
    _videoError = null;
    _videoReady = false;
    setState(() {});

    final old = _video;
    _video = null;
    if (old != null) {
      old.removeListener(_onVideoTick);
      await old.dispose();
    }

    final ctrl = VideoPlayerController.asset(reel.assetPath);
    _video = ctrl;
    try {
      await ctrl.initialize();
      if (!mounted || _loadedAssetPath != reel.assetPath) return;
      ctrl
        ..setLooping(false)
        ..setVolume(_muted ? 0 : 1)
        ..play();
      ctrl.addListener(_onVideoTick);
      _videoReady = true;
      _videoError = null;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _videoError = e.toString();
      });
    }
  }

  void _onVideoTick() {
    final v = _video;
    if (v == null || !v.value.isInitialized || _advancing) return;
    final pos = v.value.position;
    final dur = v.value.duration;
    if (dur.inMilliseconds <= 0) return;
    if (pos >= dur - _videoEndThreshold) {
      _advancing = true;
      final next = (_activeIndex + 1) % _reels.length;
      _pageController
          .animateToPage(
            next,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          )
          .whenComplete(() => _advancing = false);
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _video?.setVolume(_muted ? 0 : 1);
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: _loadingManifest
          ? const Center(child: CircularProgressIndicator(color: _neon))
          : _manifestError != null
          ? _buildEmpty(_manifestError!)
          : _reels.isEmpty
          ? _buildEmpty(
              'No reels yet.\n\nDrop MP4s into assets/images/reels/ and run\n`flutter pub get`.',
            )
          : _buildFeed(),
    );
  }

  Widget _buildEmpty(String text) {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
          if (widget.onBack != null) _backButton(),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _reels.length,
          onPageChanged: (index) async {
            _activeIndex = index;
            await _setActive(index);
          },
          itemBuilder: (context, index) {
            final reel = _reels[index];
            final isActive = index == _activeIndex;
            return _ReelPage(
              reel: reel,
              isActive: isActive,
              video: isActive ? _video : null,
              videoReady: isActive && _videoReady,
              videoError: isActive ? _videoError : null,
            );
          },
        ),
        SafeArea(
          child: Stack(
            children: [
              if (widget.onBack != null) _backButton(),
              _muteButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _backButton() {
    return Positioned(
      top: 8,
      left: 12,
      child: _GlassIconButton(
        icon: Icons.arrow_back_rounded,
        onTap: widget.onBack!,
      ),
    );
  }

  Widget _muteButton() {
    return Positioned(
      top: 8,
      right: 12,
      child: _GlassIconButton(
        icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        onTap: _toggleMute,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Reel data + page

class _StaticReel {
  const _StaticReel({
    required this.assetPath,
    required this.title,
    required this.creator,
    required this.caption,
  });

  final String assetPath;
  final String title;
  final String creator;
  final String caption;
}

class _ReelPage extends StatefulWidget {
  const _ReelPage({
    required this.reel,
    required this.isActive,
    required this.video,
    required this.videoReady,
    required this.videoError,
  });

  final _StaticReel reel;
  final bool isActive;
  final VideoPlayerController? video;
  final bool videoReady;
  final String? videoError;

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  bool _liked = false;
  int _likes = 5000;
  final int _comments = 6000;
  int _shares = 7000;
  bool _invited = false;

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  void _bumpShares() => setState(() => _shares += 1);
  void _toggleInvite() => setState(() => _invited = !_invited);

  void _openComments() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B0D12),
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: const Center(
          child: Text(
            'Comments coming soon',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }

  void _openMore() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B0D12),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ListTile(
              leading: Icon(Icons.report_outlined, color: Colors.white70),
              title: Text('Report', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: Icon(Icons.bookmark_border, color: Colors.white70),
              title: Text('Save', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: Icon(Icons.copy_rounded, color: Colors.white70),
              title: Text('Copy link', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: (widget.isActive && v != null && widget.videoReady)
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: v.value.size.width,
                    height: v.value.size.height,
                    child: VideoPlayer(v),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.20),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.70),
              ],
            ),
          ),
        ),
        if (widget.isActive && !widget.videoReady && widget.videoError == null)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF39FF14)),
          ),
        if (widget.isActive && widget.videoError != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not play: ${widget.videoError}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          ),

        // ─── Bottom-left: avatar + poster + Invite button + caption + ⋯ ───
        Positioned(
          left: 14,
          right: 90,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AvatarCircle(creator: widget.reel.creator),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.reel.creator,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _InviteButton(invited: _invited, onTap: _toggleInvite),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.reel.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        // ─── Bottom-right: heart / comment / share counts + ⋯ overflow ───
        Positioned(
          right: 12,
          bottom: 18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                color: _liked ? Colors.redAccent : Colors.white,
                label: _formatCount(_likes),
                onTap: _toggleLike,
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.mode_comment_outlined,
                color: Colors.white,
                label: _formatCount(_comments),
                onTap: _openComments,
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.send_outlined,
                color: Colors.white,
                label: _formatCount(_shares),
                onTap: _bumpShares,
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.more_horiz_rounded,
                color: Colors.white,
                label: '',
                onTap: _openMore,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatCount(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final k = n / 1000;
    return k < 10 ? '${k.toStringAsFixed(1)}K' : '${k.toStringAsFixed(0)}K';
  }
  return '${(n / 1000000).toStringAsFixed(1)}M';
}

// ─────────────────────────────────────────────────────────────────────────
// Reusable bits

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.creator});

  final String creator;

  @override
  Widget build(BuildContext context) {
    final initial = creator.isEmpty ? '?' : creator[0].toUpperCase();
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _InviteButton extends StatelessWidget {
  const _InviteButton({required this.invited, required this.onTap});

  final bool invited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const neon = Color(0xFF39FF14);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: invited ? Colors.transparent : Colors.white,
          border: Border.all(
            color: invited ? neon : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          invited ? 'Invited' : 'Invite',
          style: TextStyle(
            color: invited ? neon : Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
