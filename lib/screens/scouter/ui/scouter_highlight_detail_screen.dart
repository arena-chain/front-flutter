import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/models/feature_scouter/scouter_models.dart';
import 'package:arena_chain_flutter/core/repositories/feature_scouter/scouter_repository.dart';

String _commentAuthorLabel(Map<String, dynamic> c) {
  final a = c['author'];
  if (a is Map) {
    return (a['nickname'] ?? a['email'] ?? 'User').toString();
  }
  return 'User';
}

String _commentBody(Map<String, dynamic> c) => (c['body'] ?? '').toString();

String? resolveHighlightMediaUrl(String? rawUrl) {
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

/// Full-screen highlight: clip playback, likes / saves / comments (same API as web).
class ScouterHighlightDetailScreen extends StatefulWidget {
  final HighlightItem highlight;

  const ScouterHighlightDetailScreen({
    super.key,
    required this.highlight,
  });

  @override
  State<ScouterHighlightDetailScreen> createState() =>
      _ScouterHighlightDetailScreenState();
}

class _ScouterHighlightDetailScreenState extends State<ScouterHighlightDetailScreen> {
  final ScouterRepository _repo = ScouterRepository();
  final TextEditingController _commentCtrl = TextEditingController();

  VideoPlayerController? _video;
  bool _videoReady = false;
  String? _videoError;

  Map<String, dynamic>? _engagement;
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;
  bool _likeBusy = false;
  bool _saveBusy = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _refresh();
  }

  Future<void> _initVideo() async {
    final raw = widget.highlight.playableUrl;
    final url = resolveHighlightMediaUrl(raw);
    if (url == null) {
      setState(() => _videoError = 'No video URL');
      return;
    }
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = c;
    try {
      await c.initialize();
      if (!mounted) return;
      setState(() {
        _videoReady = true;
        _videoError = null;
      });
      await c.play();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _videoError = e.toString();
        _videoReady = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getHighlightEngagement(widget.highlight.id),
        _repo.getHighlightComments(widget.highlight.id),
      ]);
      if (!mounted) return;
      setState(() {
        _engagement = results[0] as Map<String, dynamic>;
        _comments = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _engagement ??= {};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load engagement: $e')),
      );
    }
  }

  Future<void> _toggleLike() async {
    if (_likeBusy || _engagement == null) return;
    final liked = _engagement!['likedByMe'] == true;
    setState(() => _likeBusy = true);
    try {
      if (liked) {
        await _repo.unlikeHighlight(widget.highlight.id);
      } else {
        await _repo.likeHighlight(widget.highlight.id);
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  Future<void> _toggleSave() async {
    if (_saveBusy || _engagement == null) return;
    final saved = _engagement!['savedByMe'] == true;
    setState(() => _saveBusy = true);
    try {
      if (saved) {
        await _repo.unsaveHighlight(widget.highlight.id);
      } else {
        await _repo.saveHighlight(widget.highlight.id);
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saveBusy = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.postHighlightComment(widget.highlight.id, text);
      _commentCtrl.clear();
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = _engagement;
    final likeCount = (e?['likeCount'] as num?)?.toInt() ?? 0;
    final commentCount = (e?['commentCount'] as num?)?.toInt() ?? 0;
    final saveCount = (e?['saveCount'] as num?)?.toInt() ?? 0;
    final liked = e?['likedByMe'] == true;
    final saved = e?['savedByMe'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        foregroundColor: Colors.white,
        title: Text(
          widget.highlight.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              color: Colors.black,
              child: _videoError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _videoError!,
                          style: const TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _videoReady && _video != null
                      ? VideoPlayer(_video!)
                      : const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00FF00),
                          ),
                        ),
            ),
          ),
          if (_videoReady && _video != null)
            VideoProgressIndicator(
              _video!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF00FF00),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: _likeBusy ? null : _toggleLike,
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.pinkAccent : Colors.white70,
                  ),
                ),
                Text(
                  '$likeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 22),
                const SizedBox(width: 4),
                Text(
                  '$commentCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _saveBusy ? null : _toggleSave,
                  icon: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border,
                    color: saved ? const Color(0xFF00FF00) : Colors.white70,
                  ),
                ),
                Text(
                  '$saveCount',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a comment…',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF00).withValues(alpha: 0.2),
                  ),
                  onPressed: _sending ? null : _sendComment,
                  icon: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Color(0xFF00FF00)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: _loading && _comments.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FF00)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _comments.length,
                    itemBuilder: (ctx, i) => _CommentTile(node: _comments[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> node;

  const _CommentTile({required this.node});

  @override
  Widget build(BuildContext context) {
    final replies = node['replies'];
    final List<Map<String, dynamic>> replyList = replies is List
        ? replies.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _commentAuthorLabel(node),
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _commentBody(node),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          if (replyList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: replyList.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _commentAuthorLabel(r),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _commentBody(r),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
