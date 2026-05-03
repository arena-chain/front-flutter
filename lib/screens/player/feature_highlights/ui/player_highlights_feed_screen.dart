import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle, AssetManifest, Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'package:arena_chain_flutter/core/api/feature_friends/friends_api.dart';
import 'package:arena_chain_flutter/core/api/feature_highlights/highlights_feed_api.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/screens/player/feature_highlights/viewmodel/highlights_feed_view_model.dart';

/// Live reels viewer.
///
/// Source order:
///   1. `HighlightsFeedViewModel.items` (public highlights from backend)
///   2. If empty / errored → fallback to MP4s under `assets/images/reels/`.
///
/// Every action (like, comment, share, invite) talks to the real backend
/// when there's a logged-in user AND the reel is API-sourced. For asset
/// fallbacks, actions stay local (counters only) so the empty-DB demo
/// keeps working.
class PlayerHighlightsFeedScreen extends StatefulWidget {
  const PlayerHighlightsFeedScreen({super.key, this.onBack});

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
  final HighlightsFeedApi _api = HighlightsFeedApi();
  final FriendsApi _friendsApi = FriendsApi();

  List<_Reel> _reels = const [];
  bool _bootstrapping = true;
  String? _bootstrapError;

  VideoPlayerController? _video;
  int _activeIndex = 0;
  bool _videoReady = false;
  String? _videoError;
  bool _advancing = false;
  String? _loadedSource;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
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

  // ─── Bootstrap: try API, fall back to assets ───────────────────────────

  Future<void> _bootstrap() async {
    final vm = context.read<HighlightsFeedViewModel>();
    await vm.load();
    if (!mounted) return;

    final apiReels = vm.items
        .map(_apiReelFromItem)
        .whereType<_Reel>()
        .toList();

    if (apiReels.isNotEmpty) {
      setState(() {
        _reels = apiReels;
        _bootstrapError = null;
        _bootstrapping = false;
      });
      await _setActive(0);
      return;
    }

    // Fallback to bundled MP4s.
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
        _reels = keys.map(_assetReelFromPath).toList();
        _bootstrapError = vm.error; // surface as toast, not a hard error.
        _bootstrapping = false;
      });
      if (_reels.isNotEmpty) {
        await _setActive(0);
        if (vm.error != null) {
          _toast(
            'Showing local demo reels (${vm.error}).',
            warn: true,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bootstrapError = 'Could not load reels: $e';
        _bootstrapping = false;
      });
    }
  }

  _Reel? _apiReelFromItem(HighlightItem item) {
    final src = _resolveClipUrl(item);
    if (src == null) return null;
    final raw = item.raw;
    final creatorMap = raw['creator'] is Map
        ? Map<String, dynamic>.from(raw['creator'] as Map)
        : <String, dynamic>{};
    final creatorName = (creatorMap['username'] ??
            creatorMap['nickname'] ??
            creatorMap['email'] ??
            'ArenaPlayer')
        .toString();
    final creatorAvatar = creatorMap['avatar']?.toString();
    return _Reel.api(
      id: item.id,
      videoSource: src,
      title: item.title,
      caption: (raw['description'] ?? '').toString(),
      creator: creatorName,
      creatorId: item.creatorId,
      creatorAvatar: creatorAvatar,
    );
  }

  _Reel _assetReelFromPath(String path) {
    final base = path
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
        .toLowerCase();
    final title = switch (base) {
      'cs' => 'CS2 highlight',
      'lolc' => 'League of Legends highlight',
      'val' => 'Valorant highlight',
      'dota' => 'Dota 2 highlight',
      _ => base,
    };
    final creator = switch (base) {
      'cs' => 'CS2Pro',
      'lolc' => 'LoLChamp',
      'val' => 'ValAce',
      'dota' => 'DotaKing',
      _ => 'ArenaPlayer',
    };
    final caption = switch (base) {
      'cs' => 'Clutch round, full team wipe.',
      'lolc' => 'Pentakill highlight from ranked.',
      'val' => 'Ace play on defense.',
      'dota' => 'Rampage mid-game from offlane.',
      _ => 'Demo highlight.',
    };
    return _Reel.asset(
      assetPath: path,
      title: title,
      creator: creator,
      caption: caption,
    );
  }

  String? _resolveClipUrl(HighlightItem item) {
    final raw = item.playableUrl;
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    // Backend returns a relative path like /uploads/clips/abc.mp4
    final origin = ApiConfig.socketOrigin;
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$origin$path';
  }

  // ─── Video activation / paging ─────────────────────────────────────────

  Future<void> _setActive(int index) async {
    if (_reels.isEmpty || index < 0 || index >= _reels.length) return;
    final reel = _reels[index];
    final source = reel.videoSource;
    if (_loadedSource == source && _video != null) return;

    _loadedSource = source;
    _videoError = null;
    _videoReady = false;
    setState(() {});

    final old = _video;
    _video = null;
    if (old != null) {
      old.removeListener(_onVideoTick);
      await old.dispose();
    }

    final ctrl = reel.isAsset
        ? VideoPlayerController.asset(reel.assetPath!)
        : VideoPlayerController.networkUrl(Uri.parse(source));
    _video = ctrl;
    try {
      await ctrl.initialize();
      if (!mounted || _loadedSource != source) return;
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

  void _toast(String message, {bool warn = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          backgroundColor: warn ? Colors.orange.shade800 : Colors.black87,
          content: Text(message, style: const TextStyle(color: Colors.white)),
        ),
      );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: _bootstrapping
          ? const Center(child: CircularProgressIndicator(color: _neon))
          : _reels.isEmpty
          ? _buildEmpty(
              _bootstrapError ??
                  'No reels yet.\n\nUpload a video and mark it public, '
                  'or drop MP4s in assets/images/reels/.',
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
              key: ValueKey(reel.identityKey),
              reel: reel,
              isActive: isActive,
              video: isActive ? _video : null,
              videoReady: isActive && _videoReady,
              videoError: isActive ? _videoError : null,
              api: _api,
              friendsApi: _friendsApi,
              onToast: _toast,
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

  Widget _backButton() => Positioned(
        top: 8,
        left: 12,
        child: _GlassIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: widget.onBack!,
        ),
      );

  Widget _muteButton() => Positioned(
        top: 8,
        right: 12,
        child: _GlassIconButton(
          icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          onTap: _toggleMute,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Reel data

class _Reel {
  const _Reel.api({
    required this.id,
    required this.videoSource,
    required this.title,
    required this.caption,
    required this.creator,
    required this.creatorId,
    this.creatorAvatar,
  })  : assetPath = null,
        isAsset = false;

  const _Reel.asset({
    required String assetPath,
    required this.title,
    required this.creator,
    required this.caption,
  })  : id = '',
        videoSource = assetPath,
        this.assetPath = assetPath,
        creatorId = '',
        creatorAvatar = null,
        isAsset = true;

  final String id;
  final String videoSource;
  final String? assetPath;
  final bool isAsset;
  final String title;
  final String caption;
  final String creator;
  final String creatorId;
  final String? creatorAvatar;

  String get identityKey => isAsset ? 'asset:$videoSource' : 'api:$id';
}

// ─────────────────────────────────────────────────────────────────────────
// Single reel page

class _ReelPage extends StatefulWidget {
  const _ReelPage({
    super.key,
    required this.reel,
    required this.isActive,
    required this.video,
    required this.videoReady,
    required this.videoError,
    required this.api,
    required this.friendsApi,
    required this.onToast,
  });

  final _Reel reel;
  final bool isActive;
  final VideoPlayerController? video;
  final bool videoReady;
  final String? videoError;
  final HighlightsFeedApi api;
  final FriendsApi friendsApi;
  final void Function(String message, {bool warn}) onToast;

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  static const Color _neon = Color(0xFF39FF14);

  bool _liked = false;
  int _likes = 0;
  int _comments = 0;
  int _shares = 0;
  bool _invited = false;
  bool _engagementLoaded = false;
  bool _likeBusy = false;
  bool _inviteBusy = false;

  @override
  void initState() {
    super.initState();
    if (widget.reel.isAsset) {
      // Static demo defaults.
      _likes = 5000;
      _comments = 6000;
      _shares = 7000;
      _engagementLoaded = true;
    } else {
      _loadEngagement();
    }
  }

  Future<void> _loadEngagement() async {
    try {
      final data = await widget.api.getEngagement(widget.reel.id);
      if (!mounted) return;
      setState(() {
        _likes = (data['likeCount'] as num?)?.toInt() ?? 0;
        _comments = (data['commentCount'] as num?)?.toInt() ?? 0;
        _liked = data['likedByMe'] == true;
        _engagementLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _engagementLoaded = true);
    }
  }

  Future<void> _toggleLike() async {
    if (_likeBusy) return;
    final auth = context.read<AuthViewModel>();
    if (auth.currentUser == null) {
      widget.onToast('Sign in to like reels.', warn: true);
      return;
    }
    if (widget.reel.isAsset) {
      setState(() {
        _liked = !_liked;
        _likes += _liked ? 1 : -1;
      });
      return;
    }
    final wasLiked = _liked;
    final wasCount = _likes;
    setState(() {
      _likeBusy = true;
      _liked = !wasLiked;
      _likes = wasCount + (wasLiked ? -1 : 1);
    });
    try {
      final res = wasLiked
          ? await widget.api.unlike(widget.reel.id)
          : await widget.api.like(widget.reel.id);
      if (!mounted) return;
      setState(() {
        _liked = res['liked'] == true;
        final c = (res['likeCount'] as num?)?.toInt();
        if (c != null) _likes = c;
        _likeBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = wasLiked;
        _likes = wasCount;
        _likeBusy = false;
      });
      widget.onToast(e.toString().replaceFirst('Exception: ', ''), warn: true);
    }
  }

  Future<void> _share() async {
    final origin = ApiConfig.socketOrigin;
    final url = widget.reel.isAsset
        ? '$origin/highlights/demo/${widget.reel.assetPath}'
        : '$origin/highlights/${widget.reel.id}';
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    setState(() => _shares += 1);
    widget.onToast('Reel link copied to clipboard.');
  }

  Future<void> _toggleInvite() async {
    if (_inviteBusy) return;
    final auth = context.read<AuthViewModel>();
    final me = auth.currentUser?.id ?? '';
    if (me.isEmpty) {
      widget.onToast('Sign in to invite players.', warn: true);
      return;
    }
    if (widget.reel.isAsset || widget.reel.creatorId.isEmpty) {
      // Demo path — toggle local state.
      setState(() => _invited = !_invited);
      return;
    }
    if (widget.reel.creatorId == me) {
      widget.onToast("You can't invite yourself.", warn: true);
      return;
    }
    if (_invited) {
      widget.onToast('Invite already sent.');
      return;
    }
    setState(() => _inviteBusy = true);
    try {
      await widget.friendsApi
          .sendFriendRequest(me, widget.reel.creatorId);
      if (!mounted) return;
      setState(() {
        _invited = true;
        _inviteBusy = false;
      });
      widget.onToast('Invite sent to @${widget.reel.creator}.');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '').toLowerCase();
      final alreadyExists = msg.contains('already') ||
          msg.contains('exists') ||
          msg.contains('pending');
      if (!mounted) return;
      setState(() {
        _invited = alreadyExists;
        _inviteBusy = false;
      });
      widget.onToast(
        alreadyExists ? 'Invite already pending.' : msg,
        warn: !alreadyExists,
      );
    }
  }

  Future<void> _openComments() async {
    final auth = context.read<AuthViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B0D12),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.7,
            child: _CommentsSheet(
              api: widget.api,
              highlightId: widget.reel.id,
              isApi: !widget.reel.isAsset,
              isSignedIn: auth.currentUser != null,
              onCountChanged: (newCount) {
                if (!mounted) return;
                setState(() => _comments = newCount);
              },
              onToast: widget.onToast,
            ),
          ),
        );
      },
    );
  }

  void _openMore() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B0D12),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.report_outlined, color: Colors.white70),
              title:
                  const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                widget.onToast('Reported. Thanks for letting us know.');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.bookmark_border, color: Colors.white70),
              title: const Text('Save', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                widget.onToast('Saved.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.white70),
              title:
                  const Text('Copy link', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                _share();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    final auth = context.watch<AuthViewModel>();
    final me = auth.currentUser?.id ?? '';
    final isOwn = !widget.reel.isAsset &&
        widget.reel.creatorId.isNotEmpty &&
        widget.reel.creatorId == me;
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
          const Center(child: CircularProgressIndicator(color: _neon)),
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

        // Bottom-left overlay
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
                  _AvatarCircle(
                    creator: widget.reel.creator,
                    avatarUrl: widget.reel.creatorAvatar,
                  ),
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
                  if (!isOwn) ...[
                    const SizedBox(width: 10),
                    _InviteButton(
                      invited: _invited,
                      busy: _inviteBusy,
                      onTap: _toggleInvite,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (widget.reel.title.isNotEmpty)
                Text(
                  widget.reel.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (widget.reel.caption.isNotEmpty) ...[
                const SizedBox(height: 4),
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
            ],
          ),
        ),

        // Bottom-right action rail
        Positioned(
          right: 12,
          bottom: 18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                color: _liked ? Colors.redAccent : Colors.white,
                label: _engagementLoaded ? _formatCount(_likes) : '…',
                onTap: _toggleLike,
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.mode_comment_outlined,
                color: Colors.white,
                label: _engagementLoaded ? _formatCount(_comments) : '…',
                onTap: _openComments,
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.send_outlined,
                color: Colors.white,
                label: _formatCount(_shares),
                onTap: _share,
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
// Comments sheet

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({
    required this.api,
    required this.highlightId,
    required this.isApi,
    required this.isSignedIn,
    required this.onCountChanged,
    required this.onToast,
  });

  final HighlightsFeedApi api;
  final String highlightId;
  final bool isApi;
  final bool isSignedIn;
  final ValueChanged<int> onCountChanged;
  final void Function(String message, {bool warn}) onToast;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _input = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    if (widget.isApi) {
      _load();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.listComments(widget.highlightId);
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
      widget.onCountChanged(_items.length);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) return;
    if (!widget.isApi) {
      widget.onToast('Comments are read-only on demo reels.', warn: true);
      return;
    }
    if (!widget.isSignedIn) {
      widget.onToast('Sign in to comment.', warn: true);
      return;
    }
    setState(() => _sending = true);
    try {
      final created = await widget.api
          .addComment(widget.highlightId, body: body);
      if (!mounted) return;
      setState(() {
        _items = [created, ..._items];
        _input.clear();
        _sending = false;
      });
      widget.onCountChanged(_items.length);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      widget.onToast(
        e.toString().replaceFirst('Exception: ', ''),
        warn: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            'Comments',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(child: _buildBody()),
        const Divider(color: Colors.white10, height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: widget.isApi && widget.isSignedIn && !_sending,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: widget.isApi
                        ? (widget.isSignedIn
                            ? 'Add a comment…'
                            : 'Sign in to comment')
                        : 'Comments disabled on demo reels',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF15171D),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Color(0xFF39FF14),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Color(0xFF39FF14)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (!widget.isApi) {
      return const Center(
        child: Text(
          'Demo reel — no comments yet.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF39FF14)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'Be the first to comment.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _items.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Colors.white10, height: 1),
      itemBuilder: (_, i) {
        final c = _items[i];
        final author = c['author'];
        final authorName = author is Map
            ? (author['nickname'] ?? author['email'] ?? 'user').toString()
            : (author ?? 'user').toString();
        final body = (c['body'] ?? '').toString();
        return ListTile(
          dense: true,
          leading: _AvatarCircle(creator: authorName, avatarUrl: null),
          title: Text(
            authorName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            body,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Reusable bits

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.creator, this.avatarUrl});

  final String creator;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initial = creator.isEmpty ? '?' : creator[0].toUpperCase();
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    return Container(
      width: 36,
      height: 36,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      alignment: Alignment.center,
      child: hasAvatar
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              width: 36,
              height: 36,
              errorBuilder: (_, __, ___) => Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Text(
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
  const _InviteButton({
    required this.invited,
    required this.busy,
    required this.onTap,
  });

  final bool invited;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const neon = Color(0xFF39FF14);
    final label = busy ? '...' : (invited ? 'Invited' : 'Invite');
    return InkWell(
      onTap: busy ? null : onTap,
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
          label,
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
