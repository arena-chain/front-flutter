import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/team_api.dart';
import 'package:arena_chain_flutter/core/models/team_model.dart';
import 'package:intl/intl.dart';

class TeamFeedScreen extends StatefulWidget {
  final String teamId;
  const TeamFeedScreen({super.key, required this.teamId});

  @override
  State<TeamFeedScreen> createState() => _TeamFeedScreenState();
}

class _TeamFeedScreenState extends State<TeamFeedScreen> {
  final _teamApi = TeamApi();
  final _postController = TextEditingController();
  List<TeamPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    try {
      final posts = await _teamApi.getTeamPosts(widget.teamId);
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading feed: $e')));
      }
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.isEmpty) return;
    try {
      await _teamApi.createPost(widget.teamId, _postController.text);
      _postController.clear();
      _fetchFeed();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _showComments(TeamPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => _CommentSection(postId: post.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121B),
      appBar: AppBar(
        title: const Text('Team Social Wall'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Share something with the team...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _createPost,
                  icon: const Icon(Icons.send, color: Color(0xFFE94560)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchFeed,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      final authorNickname = post.author is Map ? post.author['nickname'] : 'Player';
                      final authorAvatar = post.author is Map ? post.author['avatar'] : null;

                      return Card(
                        color: const Color(0xFF1A1A2E),
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: authorAvatar != null ? NetworkImage(authorAvatar) : null,
                                    child: authorAvatar == null ? const Icon(Icons.person) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(authorNickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        Text(DateFormat.yMMMd().format(post.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Text(post.content, style: const TextStyle(color: Colors.white, fontSize: 15)),
                              const Divider(color: Colors.white12, height: 30),
                              GestureDetector(
                                onTap: () => _showComments(post),
                                child: const Row(
                                  children: [
                                    Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 18),
                                    SizedBox(width: 8),
                                    Text('Comments', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _CommentSection extends StatefulWidget {
  final String postId;
  const _CommentSection({required this.postId});

  @override
  State<_CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<_CommentSection> {
  final _teamApi = TeamApi();
  final _commentController = TextEditingController();
  List<TeamComment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await _teamApi.getComments(widget.postId);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;
    try {
      await _teamApi.addComment(widget.postId, _commentController.text);
      _commentController.clear();
      _fetchComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Discussion', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white12, height: 30),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final c = _comments[index];
                      final nickname = c.user is Map ? c.user['nickname'] : 'User';
                      final avatar = c.user is Map ? c.user['avatar'] : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                              child: avatar == null ? const Icon(Icons.person, size: 12) : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nickname, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text(c.content, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
            const Divider(color: Colors.white12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Reply...', hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
                  ),
                ),
                IconButton(onPressed: _addComment, icon: const Icon(Icons.send, color: Color(0xFFE94560))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
