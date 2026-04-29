import 'dart:async';
import 'package:arena_chain_flutter/core/services/live_room_service.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LiveRoomScreen extends StatefulWidget {
  final String channelId;
  final String title;
  const LiveRoomScreen({
    super.key,
    required this.channelId,
    required this.title,
  });

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  static const _neon = Color(0xFF39FF14);
  final _service = LiveRoomService();
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _chat = [];
  final List<Map<String, dynamic>> _events = [];
  final List<Map<String, dynamic>> _friends = [];
  Map<String, int> _reactions = {};
  bool _connected = false;
  bool _loadingHistory = true;

  StreamSubscription? _chatSub;
  StreamSubscription? _reactionSub;
  StreamSubscription? _eventSub;
  StreamSubscription? _presenceSub;
  StreamSubscription? _connectSub;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthViewModel>();
    final token = auth.token;
    final userId = auth.currentUser?.id ?? 'guest';

    try {
      final history = await _service.fetchChatHistory(widget.channelId);
      if (mounted) {
        setState(() => _chat.addAll(history));
      }
    } finally {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
    }

    _service.connect(channelId: widget.channelId, userId: userId, token: token);

    _chatSub = _service.onChatMessage.listen((msg) {
      if (!mounted) return;
      setState(() => _chat.add(msg));
      _autoScroll();
    });
    _reactionSub = _service.onReactionSummary.listen((r) {
      if (!mounted) return;
      setState(() => _reactions = r);
    });
    _eventSub = _service.onGameEvent.listen((event) {
      if (!mounted) return;
      setState(() {
        _events.insert(0, event);
        if (_events.length > 20) _events.removeLast();
      });
    });
    _presenceSub = _service.onPresenceReady.listen((friends) {
      if (!mounted) return;
      setState(() => _friends
        ..clear()
        ..addAll(friends));
    });
    _connectSub = _service.onConnectionChanged.listen((state) {
      if (!mounted) return;
      setState(() => _connected = state);
    });
  }

  void _autoScroll() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _reactionSub?.cancel();
    _eventSub?.cancel();
    _presenceSub?.cancel();
    _connectSub?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          if (!_connected)
            Container(
              width: double.infinity,
              color: Colors.orange.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(8),
              child: const Text(
                'Reconnecting chat...',
                style: TextStyle(color: Colors.orangeAccent),
                textAlign: TextAlign.center,
              ),
            ),
          _friendsBar(),
          _eventsBar(),
          _reactionBar(),
          Expanded(child: _chatList()),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _friendsBar() {
    final online = _friends.where((f) => '${f['status']}'.toLowerCase() != 'offline').toList();
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Text('Friends online: ${online.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 10),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: online.length.clamp(0, 10),
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = online[i];
                final nickname = (f['nickname'] ?? f['name'] ?? 'F').toString();
                return CircleAvatar(
                  radius: 14,
                  backgroundColor: _neon.withValues(alpha: 0.22),
                  child: Text(
                    nickname.isNotEmpty ? nickname[0].toUpperCase() : 'F',
                    style: const TextStyle(color: _neon, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventsBar() {
    if (_events.isEmpty) {
      return const SizedBox.shrink();
    }
    final latest = _events.first;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11141D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _neon.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Live game: ${latest['type'] ?? latest['eventType'] ?? 'update'}',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  Widget _reactionBar() {
    const emojis = ['👏', '🔥', '❤️', '🎉', '😂'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        children: emojis.map((emoji) {
          final count = _reactions[emoji] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: const Color(0xFF11141D),
              side: BorderSide(color: _neon.withValues(alpha: 0.2)),
              label: Text('$emoji $count', style: const TextStyle(color: Colors.white)),
              onPressed: () => _service.sendReaction(emoji),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chatList() {
    if (_loadingHistory && _chat.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _neon));
    }
    if (_chat.isEmpty) {
      return const Center(
        child: Text('No chat messages yet', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      itemCount: _chat.length,
      itemBuilder: (_, i) {
        final msg = _chat[i];
        final sender = (msg['senderNickname'] ?? msg['nickname'] ?? 'User').toString();
        final text = (msg['message'] ?? '').toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$sender: ',
                  style: const TextStyle(color: _neon, fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: text,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _inputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0xFF1F2330))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF121723),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _send,
            icon: const Icon(Icons.send_rounded, color: _neon),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _service.sendMessage(text);
    _chatController.clear();
  }
}

