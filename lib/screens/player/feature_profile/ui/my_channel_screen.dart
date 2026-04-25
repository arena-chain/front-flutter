import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/video_api.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/models/channel_model.dart';
import '../../../../core/models/video_model.dart';
import '../../../../core/models/feature_scouter/scouter_models.dart';
import '../../../../core/repositories/feature_scouter/scouter_repository.dart';
import '../../../feature_auth/viewmodel/auth_viewmodel.dart';
import '../../../scouter/ui/scouter_highlight_detail_screen.dart';
import 'video_player_screen.dart';

class MyChannelScreen extends StatefulWidget {
  const MyChannelScreen({super.key});

  @override
  State<MyChannelScreen> createState() => _MyChannelScreenState();
}

class _MyChannelScreenState extends State<MyChannelScreen> {
  // Mocking state: set to null to see "Create Channel", or an object to see "Channel"
  Channel? _myChannel;
  List<Video> _videos = [];
  List<HighlightItem> _highlightClips = [];
  final VideoApi _videoApi = VideoApi();
  bool _isLoadingVideos = false;
  bool _loadingClips = false;
  bool _isUploadingVideo = false;
  bool _showUploadActions = false;

  /// Matches Home / Live / Training (black canvas + neon).
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _cardColor = const Color(0xFF1A1C23);
  final Color _surface = const Color(0xFF0A0A0A);
  final Color _neon = const Color(0xFF39FF14);

  @override
  void initState() {
    super.initState();
    // Simulate fetching data.
    // _myChannel = null; // Uncomment to test empty state
    _myChannel = Channel(
      id: '1',
      name: 'SoloLineAbuse',
      ownerId: 'u1',
      subscriberCount: 2350,
      avatarUrl: 'https://cdn.midjourney.com/3c70f37e-61d0-4786-b485-6184e6221544/0_3.png', // Placeholder
      bannerUrl: 'https://cdn.midjourney.com/791097fa-e165-4f35-9852-641508dbfe08/0_0.png', // Placeholder
    );
    _videos = [
      Video(
        id: 'v1',
        title: 'Valorant - Ace Clutch!',
        status: VideoStatus.approved,
        uploadDate: DateTime.now().subtract(const Duration(days: 1)),
        views: 3420,
        thumbnailUrl: 'https://cdn.midjourney.com/a4c9b369-02c3-4c9f-b3a5-502844fd7167/0_2.png', // Valorant style
      ),
      Video(
        id: 'v2',
        title: 'League of Legends - Grand Finals',
        status: VideoStatus.approved,
        uploadDate: DateTime.now().subtract(const Duration(days: 3)),
        views: 12500,
        thumbnailUrl: 'https://cdn.midjourney.com/791097fa-e165-4f35-9852-641508dbfe08/0_0.png', // LoL style
      ),
      Video(
        id: 'v3',
        title: 'CS:GO 2 - Sniper Montage',
        status: VideoStatus.approved,
        uploadDate: DateTime.now().subtract(const Duration(days: 7)),
        views: 890,
        thumbnailUrl: 'https://cdn.midjourney.com/f7d39ccf-863a-4a6c-b4db-540292723652/0_1.png', // Shooter style
      ),
      Video(
        id: 's1',
        title: 'Ranked Push to Diamond',
        status: VideoStatus.scheduled,
        uploadDate: DateTime.now(),
        scheduledDate: DateTime.now().add(const Duration(hours: 2)),
        thumbnailUrl: 'https://cdn.midjourney.com/f7d39ccf-863a-4a6c-b4db-540292723652/0_1.png',
      ),
      Video(
        id: 's2',
        title: 'Tournament Finals - Live Commentary',
        status: VideoStatus.scheduled,
        uploadDate: DateTime.now(),
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        thumbnailUrl: 'https://cdn.midjourney.com/791097fa-e165-4f35-9852-641508dbfe08/0_0.png',
      ),
    ];
    _fetchVideos();
  }

  void _createChannel() {
    setState(() {
      _myChannel = Channel(
        id: '2',
        name: 'New Player',
        ownerId: 'u1',
        subscriberCount: 0,
      );
    });
  }

  Future<void> _fetchVideos() async {
    if (!mounted) return;
    setState(() => _isLoadingVideos = true);
    try {
      final auth = Provider.of<AuthViewModel>(context, listen: false);
      final uploaderId = auth.currentUser?.id ?? _myChannel?.ownerId;
      final videos = await _videoApi.getVideos(uploaderId: uploaderId);
      if (!mounted) return;
      setState(() => _videos = videos);
      await _loadHighlightClips(uploaderId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load videos from backend.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingVideos = false);
      }
    }
  }

  /// Short clips from the player’s uploads + public pool, ranked by reactions (mobile parity with web).
  Future<void> _loadHighlightClips(String? userId) async {
    if (userId == null || userId.isEmpty) {
      if (mounted) setState(() => _highlightClips = []);
      return;
    }
    if (!mounted) return;
    setState(() => _loadingClips = true);
    try {
      final repo = ScouterRepository();
      final approved = _videos.where((v) => v.status == VideoStatus.approved).toList();
      final fromVideo = <HighlightItem>[];
      for (final v in approved) {
        if (v.id.isEmpty) continue;
        try {
          final list =
              await repo.getHighlightsForVideo(v.id, publicOnly: false);
          for (final h in list) {
            if (h.creatorId == userId) fromVideo.add(h);
          }
        } catch (_) {}
      }
      final byId = {for (final h in fromVideo) h.id: h};
      if (byId.isEmpty) {
        try {
          final pub = await repo.getPublicHighlights();
          for (final h in pub) {
            if (h.creatorId == userId) byId[h.id] = h;
          }
        } catch (_) {}
      }
      var merged = byId.values.toList();
      if (merged.isNotEmpty) {
        merged = await repo.rankHighlights(merged);
      }
      if (mounted) setState(() => _highlightClips = merged);
    } catch (_) {
      if (mounted) setState(() => _highlightClips = []);
    } finally {
      if (mounted) setState(() => _loadingClips = false);
    }
  }

  Future<void> _pickAndUploadVideo() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0x3329FF14)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _neon.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.video_library_outlined, color: _neon.withValues(alpha: 0.9)),
              title: const Text('Pick from gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(bottomSheetContext, 'gallery'),
            ),
            ListTile(
              leading: Icon(Icons.videocam_outlined, color: _neon.withValues(alpha: 0.9)),
              title: const Text('Record with camera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(bottomSheetContext, 'camera'),
            ),
            ListTile(
              leading: Icon(Icons.folder_open_rounded, color: _neon.withValues(alpha: 0.9)),
              title: const Text('Browse files', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(bottomSheetContext, 'files'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    String? filePath;
    try {
      if (source == 'files') {
        final fileResult = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['mp4', 'mov', 'webm', 'm4v'],
        );
        filePath = fileResult?.files.single.path;
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickVideo(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );
        filePath = picked?.path;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open picker: $e')),
      );
      return;
    }

    if (filePath == null || filePath.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video selected. Try "Browse files" if gallery is empty on simulator.'),
        ),
      );
      return;
    }
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    if (!mounted) return;

    final shouldUpload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _neon.withValues(alpha: 0.35)),
        ),
        title: Text(
          'Upload Video',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            shadows: [Shadow(color: _neon.withValues(alpha: 0.25), blurRadius: 8)],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _neon.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _neon.withValues(alpha: 0.55)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _neon.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _neon.withValues(alpha: 0.55)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.65))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: _neon,
              foregroundColor: Colors.black,
            ),
            child: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (shouldUpload != true) return;
    if (!mounted) return;

    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video title is required.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isUploadingVideo = true);
    try {
      final auth = Provider.of<AuthViewModel>(context, listen: false);
      final uploaderId = auth.currentUser?.id ?? _myChannel?.ownerId ?? '';
      if (uploaderId.isEmpty) {
        throw Exception('Unable to determine uploader id.');
      }
      await _videoApi.uploadVideo(
        filePath: filePath,
        title: title,
        description: descriptionController.text.trim(),
        uploaderId: uploaderId,
        token: auth.token,
      );
      await _fetchVideos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingVideo = false);
      }
    }
  }

  int get _approvedVideoCount =>
      _videos.where((v) => v.status == VideoStatus.approved).length;

  int get _totalVideoViews => _videos.fold<int>(0, (sum, v) => sum + v.views);

  String _formatCompactCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    if (_myChannel == null) {
      return _buildNoChannelView();
    }
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        clipBehavior: Clip.none,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _buildUserInfo()),
                        const SizedBox(height: 20),
                        _buildChannelStrip(),
                        const SizedBox(height: 20),
                        _buildChannelActions(),
                        const SizedBox(height: 28),
                        _buildStatsSection(),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recent Videos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(color: _neon.withValues(alpha: 0.28), blurRadius: 8),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => _showUploadActions = !_showUploadActions);
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: _surface,
                                side: BorderSide(color: _neon.withValues(alpha: 0.35)),
                              ),
                              icon: Icon(
                                _showUploadActions ? Icons.close_rounded : Icons.add_rounded,
                                color: _neon.withValues(alpha: 0.95),
                              ),
                              tooltip: 'Toggle upload actions',
                            ),
                          ],
                        ),
                        if (_showUploadActions)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _neon.withValues(alpha: 0.28)),
                              boxShadow: [
                                BoxShadow(
                                  color: _neon.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _isUploadingVideo ? null : _pickAndUploadVideo,
                                    icon: _isUploadingVideo
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black,
                                            ),
                                          )
                                        : const Icon(Icons.upload_rounded, color: Colors.black),
                                    label: Text(
                                      _isUploadingVideo ? 'Uploading...' : 'Upload video',
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _neon,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  onPressed: _isLoadingVideos ? null : _fetchVideos,
                                  style: IconButton.styleFrom(
                                    backgroundColor: _surface,
                                    side: BorderSide(color: _neon.withValues(alpha: 0.35)),
                                  ),
                                  icon: Icon(Icons.refresh_rounded, color: _neon.withValues(alpha: 0.9)),
                                  tooltip: 'Refresh videos',
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -100,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildChannelAvatar()),
                  ),
                ],
              ),
            ),
          ),
          _buildHighlightClipsSliver(),
          _buildSliverVideoList(),
          const SliverToBoxAdapter(
             child: SizedBox(height: 80), // Bottom padding
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightClipsSliver() {
    if (!_loadingClips && _highlightClips.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: _neon, size: 20),
                const SizedBox(width: 8),
                Text(
                  'My highlight clips',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: _neon.withValues(alpha: 0.22), blurRadius: 6),
                    ],
                  ),
                ),
                const Spacer(),
                if (_loadingClips)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _neon.withValues(alpha: 0.85)),
                  )
                else
                  Text(
                    '${_highlightClips.length}',
                    style: TextStyle(
                      color: _neon.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loadingClips && _highlightClips.isEmpty)
              SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(color: _neon.withValues(alpha: 0.85))),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _highlightClips.length,
                  itemBuilder: (context, i) {
                    final h = _highlightClips[i];
                    final thumb = h.thumbnailUrl;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ScouterHighlightDetailScreen(highlight: h),
                            ),
                          );
                        },
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _neon.withValues(alpha: 0.12),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _neon.withValues(alpha: 0.35)),
                              color: _cardColor,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (thumb != null && thumb.isNotEmpty)
                                  Image.network(
                                    thumb,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _highlightClipPlaceholder(),
                                  )
                                else
                                  _highlightClipPlaceholder(),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.75),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Icon(
                                    Icons.play_circle_rounded,
                                    color: _neon.withValues(alpha: 0.85),
                                    size: 40,
                                  ),
                                ),
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  bottom: 8,
                                  child: Text(
                                    h.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverVideoList() {
    final approvedVideos = _videos.where((v) => v.status == VideoStatus.approved).toList();
    if (_isLoadingVideos) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: CircularProgressIndicator(color: _neon.withValues(alpha: 0.85)),
          ),
        ),
      );
    }
    if (approvedVideos.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'No videos uploaded yet.',
              style: TextStyle(
                color: _neon.withValues(alpha: 0.45),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final video = approvedVideos[index];
          final playableUrl = _resolveVideoUrl(video.videoUrl);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: playableUrl == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(
                            videoUrl: playableUrl,
                            title: video.title,
                          ),
                        ),
                      );
                    },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _neon.withValues(alpha: 0.08),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _neon.withValues(alpha: 0.28)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail placeholder
                      Stack(
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.black26,
                            child: video.thumbnailUrl != null
                                ? Image.network(
                                    video.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _videoThumbPlaceholder(),
                                  )
                                : _videoThumbPlaceholder(),
                          ),
                          Positioned(
                            left: 12,
                            top: 12,
                            child: Icon(
                              Icons.play_circle_rounded,
                              color: _neon.withValues(alpha: 0.9),
                              size: 36,
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _neon.withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                _formatDuration(video.duration),
                                style: TextStyle(
                                  color: _neon.withValues(alpha: 0.95),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${video.views} views',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 12,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Icon(Icons.circle, size: 4, color: _neon.withValues(alpha: 0.35)),
                                ),
                                Text(
                                  _timeAgo(video.uploadDate),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (playableUrl == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Video URL missing',
                                  style: TextStyle(color: Colors.red[300], fontSize: 12),
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
        },
        childCount: approvedVideos.length,
      ),
    );
  }

  String _formatDuration(int? totalSeconds) {
    if (totalSeconds == null || totalSeconds <= 0) return '00:00';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min ago';
    }
    return 'Just now';
  }

  String? _resolveVideoUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final url = rawUrl.trim();
    final backend = Uri.parse(ApiConfig.baseUrl);

    // Backend may return relative/static paths like "/uploads/videos/x.mp4" or "uploads/videos/x.mp4".
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final normalizedPath = url.startsWith('/') ? url : '/$url';
      return '${backend.scheme}://${backend.host}${backend.hasPort ? ':${backend.port}' : ''}$normalizedPath';
    }

    if (url.startsWith('http://localhost') || url.startsWith('https://localhost')) {
      final pathStart = url.indexOf('/', url.indexOf('://') + 3);
      final path = pathStart >= 0 ? url.substring(pathStart) : '';
      return '${backend.scheme}://${backend.host}${backend.hasPort ? ':${backend.port}' : ''}$path';
    }

    // Some backends return host IP not reachable from emulator; force base host while preserving path.
    final parsed = Uri.tryParse(url);
    if (parsed != null &&
        parsed.host.isNotEmpty &&
        parsed.host != backend.host &&
        parsed.path.startsWith('/uploads/')) {
      return '${backend.scheme}://${backend.host}${backend.hasPort ? ':${backend.port}' : ''}${parsed.path}';
    }

    return url;
  }

  /// Banner when URL missing or fails to load — pro channel look, matches app neon.
  Widget _bannerBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A2830),
            const Color(0xFF0F1A14),
            _backgroundColor,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _ChannelBannerGridPainter(color: _neon.withValues(alpha: 0.1)),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: _backgroundColor,
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: _neon.withValues(alpha: 0.22)),
        ),
        child: BackButton(color: _neon.withValues(alpha: 0.95)),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: _neon.withValues(alpha: 0.22)),
          ),
          child: IconButton(
            icon: Icon(Icons.settings_outlined, color: _neon.withValues(alpha: 0.95)),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: _myChannel!.bannerUrl != null && _myChannel!.bannerUrl!.isNotEmpty
                  ? Image.network(
                      _myChannel!.bannerUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _bannerBackground(),
                    )
                  : _bannerBackground(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                      _backgroundColor.withValues(alpha: 0.75),
                      _backgroundColor,
                    ],
                    stops: const [0.0, 0.28, 0.78, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _neon.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelAvatar() {
    const double inner = 100;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _neon.withValues(alpha: 0.55), width: 2.5),
        boxShadow: [
          BoxShadow(color: _neon.withValues(alpha: 0.25), blurRadius: 22, spreadRadius: 0),
          BoxShadow(color: Colors.black.withValues(alpha: 0.65), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(
        child: SizedBox(
          width: inner,
          height: inner,
          child: _myChannel!.avatarUrl != null && _myChannel!.avatarUrl!.isNotEmpty
              ? Image.network(
                  _myChannel!.avatarUrl!,
                  fit: BoxFit.cover,
                  width: inner,
                  height: inner,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return ColoredBox(
                      color: _cardColor,
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _neon.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => _avatarFallback(inner),
                )
              : _avatarFallback(inner),
        ),
      ),
    );
  }

  Widget _avatarFallback(double size) {
    final name = _myChannel!.name;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _cardColor,
            _neon.withValues(alpha: 0.12),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: _neon.withValues(alpha: 0.95),
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _videoThumbPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _cardColor,
                _neon.withValues(alpha: 0.08),
              ],
            ),
          ),
        ),
        Center(
          child: Icon(
            Icons.play_circle_outline_rounded,
            color: _neon.withValues(alpha: 0.42),
            size: 56,
          ),
        ),
      ],
    );
  }

  Widget _highlightClipPlaceholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _cardColor,
            _neon.withValues(alpha: 0.12),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    final handle = _myChannel!.name.replaceAll(' ', '').toLowerCase();
    return Column(
      children: [
        Text(
          '@$handle',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _myChannel!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.verified_rounded, color: _neon.withValues(alpha: 0.95), size: 22),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Tunisia • Pro Gamer',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildChannelStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _neon.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6E7681),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Offline',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Esports • VODs & highlights',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelActions() {
    final border = _neon.withValues(alpha: 0.45);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.share_outlined, color: _neon.withValues(alpha: 0.9), size: 20),
            label: Text(
              'Share',
              style: TextStyle(
                color: _neon.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _neon,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: border, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded, color: Colors.black, size: 20),
            label: const Text(
              'Customize',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _neon,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _neon.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _neon.withValues(alpha: 0.04),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            'Followers',
            _formatCompactCount(_myChannel!.subscriberCount),
            Icons.people_outline_rounded,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            'Total views',
            _formatCompactCount(_totalVideoViews),
            Icons.visibility_outlined,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            'Videos',
            '$_approvedVideoCount',
            Icons.video_library_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: _neon.withValues(alpha: 0.65), size: 18),
          const SizedBox(height: 8),
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
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: _neon.withValues(alpha: 0.22),
    );
  }



  Widget _buildNoChannelView() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: _neon.withValues(alpha: 0.22)),
          ),
          child: BackButton(color: _neon.withValues(alpha: 0.95)),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: _neon.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(color: _neon.withValues(alpha: 0.12), blurRadius: 20),
                ],
              ),
              child: Icon(Icons.videocam_outlined, size: 64, color: _neon.withValues(alpha: 0.95)),
            ),
            const SizedBox(height: 24),
            Text(
              'Start Your Journey',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: _neon.withValues(alpha: 0.25), blurRadius: 10),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a channel to stream your games,\nupload videos, and build your community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: _createChannel,
              style: FilledButton.styleFrom(
                backgroundColor: _neon,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Create channel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelBannerGridPainter extends CustomPainter {
  final Color color;

  _ChannelBannerGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 22.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChannelBannerGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

