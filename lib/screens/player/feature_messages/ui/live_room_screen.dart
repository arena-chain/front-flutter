import 'dart:async';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/services/live_room_service.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

class LiveRoomScreen extends StatefulWidget {
  final String channelId;
  final String title;
  const LiveRoomScreen({
    super.key,
    required this.channelId,
    required this.title,
  });

  /// Stable id for a two-user DM so both participants join the same room.
  static String directMessageChannelId(String userIdA, String userIdB) {
    final a = userIdA.trim();
    final b = userIdB.trim();
    if (a.isEmpty || b.isEmpty) return 'dm:invalid';
    final first = a.compareTo(b) <= 0 ? a : b;
    final second = a.compareTo(b) <= 0 ? b : a;
    return 'dm:$first:$second';
  }

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  static const _neon = Color(0xFF39FF14);
  final _service = LiveRoomService();

  bool get _isDirectMessage => widget.channelId.startsWith('dm:');
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
  StreamSubscription? _deletedSub;
  StreamSubscription? _updatedSub;

  late final AuthViewModel _auth;
  VoidCallback? _authListener;
  Timer? _authDebounce;
  String? _authBindSig;
  int _authBindVersion = 0;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _authListener = () => _scheduleAuthRebind();
    _auth.addListener(_authListener!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleAuthRebind();
    });
  }

  void _scheduleAuthRebind() {
    _authDebounce?.cancel();
    _authDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _applyAuthForChat(_auth);
    });
  }

  /// New login / token must tear down the old socket (still authed as previous user).
  Future<void> _applyAuthForChat(AuthViewModel auth) async {
    final uid = (auth.currentUser?.id ?? '').trim();
    final stored = (await TokenStorage().getAccessToken())?.trim() ?? '';
    final memory = auth.token?.trim() ?? '';
    // Persisted token is source of truth right after login; memory can lag briefly.
    final tok = stored.isNotEmpty ? stored : memory;
    final sig = '$uid|${tok.hashCode}';

    if (uid.isEmpty) {
      if (_authBindSig != null) {
        _authBindSig = null;
        _unsubscribeStreams();
        _service.disconnect();
        if (mounted) {
          setState(() {
            _connected = false;
            _chat.clear();
            _loadingHistory = false;
          });
        }
      }
      return;
    }

    if (sig == _authBindSig) return;
    final bindPass = ++_authBindVersion;
    _authBindSig = sig;

    _unsubscribeStreams();
    _service.disconnect();

    if (mounted) {
      setState(() {
        _connected = false;
        _loadingHistory = true;
        _chat.clear();
        _events.clear();
        _friends.clear();
        _reactions = {};
      });
    }

    try {
      final history = await _service.fetchChatHistory(
        widget.channelId,
        bearerToken: tok.isNotEmpty ? tok : null,
      );
      if (!mounted || bindPass != _authBindVersion) return;
      setState(() => _chat.addAll(history));
    } finally {
      if (mounted && bindPass == _authBindVersion) {
        setState(() => _loadingHistory = false);
      }
    }

    if (!mounted || bindPass != _authBindVersion) return;
    _service.connect(
      channelId: widget.channelId,
      userId: uid,
      token: tok.isNotEmpty ? tok : null,
    );
    if (!mounted || bindPass != _authBindVersion) return;
    _subscribeStreams();
  }

  void _unsubscribeStreams() {
    _chatSub?.cancel();
    _reactionSub?.cancel();
    _eventSub?.cancel();
    _presenceSub?.cancel();
    _connectSub?.cancel();
    _deletedSub?.cancel();
    _updatedSub?.cancel();
    _chatSub = null;
    _reactionSub = null;
    _eventSub = null;
    _presenceSub = null;
    _connectSub = null;
    _deletedSub = null;
    _updatedSub = null;
  }

  void _subscribeStreams() {
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
    _deletedSub = _service.onMessageDeletedId.listen((id) {
      if (!mounted) return;
      setState(() {
        final i = _chat.indexWhere((m) => _messageId(m) == id);
        if (i < 0) return;
        _chat[i] = {
          ..._chat[i],
          'message': 'This message was deleted.',
          '_localDeleted': true,
        };
      });
    });
    _updatedSub = _service.onMessageUpdated.listen((patch) {
      if (!mounted) return;
      final id = _messageId(patch);
      if (id.isEmpty) return;
      final i = _chat.indexWhere((m) => _messageId(m) == id);
      if (i < 0) return;
      final next = Map<String, dynamic>.from(_chat[i]);
      next.addAll(patch);
      final body = patch['message'] ?? patch['text'] ?? patch['content'];
      if (body != null) next['message'] = body.toString();
      setState(() => _chat[i] = next);
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
    _authDebounce?.cancel();
    if (_authListener != null) {
      _auth.removeListener(_authListener!);
    }
    _unsubscribeStreams();
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
              child: Text(
                _isDirectMessage
                    ? 'Connecting to chat…'
                    : 'Reconnecting chat…',
                style: const TextStyle(color: Colors.orangeAccent),
                textAlign: TextAlign.center,
              ),
            ),
          if (!_isDirectMessage) _friendsBar(),
          if (!_isDirectMessage) _eventsBar(),
          if (!_isDirectMessage) _reactionBar(),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: emojis.map((emoji) {
            final count = _reactions[emoji] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                backgroundColor: const Color(0xFF11141D),
                side: BorderSide(color: _neon.withValues(alpha: 0.2)),
                label: Text(
                  '$emoji $count',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                onPressed: () => _service.sendReaction(emoji),
              ),
            );
          }).toList(),
        ),
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
    final maxW = MediaQuery.sizeOf(context).width * 0.82;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      itemCount: _chat.length,
      itemBuilder: (_, i) {
        final msg = _chat[i];
        final mine = _isMyMessage(msg);
        final sender = _senderLabel(msg);
        final tombstone = _isMessageTombstone(msg);
        final text = tombstone
            ? 'This message was deleted.'
            : (msg['message'] ?? '').toString();
        final peer = _dmConversationPeerId();
        final mid = _messageId(msg);

        final bubble = DecoratedBox(
          decoration: BoxDecoration(
            color: tombstone
                ? const Color(0xFF1A1A1A)
                : mine
                    ? const Color(0xFF142818)
                    : const Color(0xFF161A22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tombstone
                  ? const Color(0xFF333333)
                  : mine
                      ? _neon.withValues(alpha: 0.35)
                      : const Color(0xFF2A3040),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!mine && !tombstone)
                  Text(
                    sender,
                    style: const TextStyle(
                      color: _neon,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                if (!mine && !tombstone) const SizedBox(height: 4),
                Text(
                  text,
                  textAlign: mine ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: tombstone
                        ? const Color(0xFF888888)
                        : const Color(0xFFE8E8E8),
                    fontSize: tombstone ? 13 : 15,
                    height: 1.25,
                    fontStyle:
                        tombstone ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        );

        Widget wrapped = bubble;
        if (mine &&
            _isDirectMessage &&
            mid.isNotEmpty &&
            peer != null &&
            !tombstone) {
          final peerId = peer;
          wrapped = GestureDetector(
            onLongPress: () => _onDmMessageLongPress(msg, peerId),
            child: bubble,
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Align(
            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: wrapped,
            ),
          ),
        );
      },
    );
  }

  String _messageId(Map<String, dynamic> m) =>
      m['_id']?.toString() ??
      m['id']?.toString() ??
      m['messageId']?.toString() ??
      '';

  bool _isMessageTombstone(Map<String, dynamic> m) =>
      m['_localDeleted'] == true ||
      m['deleted'] == true ||
      m['isDeleted'] == true;

  /// Other user id in `dm:<a>:<b>` for `deleteMessage` / `updateMessage` payloads.
  String? _dmConversationPeerId() {
    if (!_isDirectMessage) return null;
    final raw = widget.channelId;
    if (!raw.startsWith('dm:')) return null;
    final rest = raw.length > 3 ? raw.substring(3) : '';
    final parts = rest.split(':');
    if (parts.length < 2) return null;
    final a = parts[0].trim();
    final b = parts[1].trim();
    final my = (_auth.currentUser?.id ?? '').trim();
    if (a == my) return b.isEmpty ? null : b;
    if (b == my) return a.isEmpty ? null : a;
    return null;
  }

  Future<void> _onDmMessageLongPress(
    Map<String, dynamic> msg,
    String peerId,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF121723),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: _neon),
              title: const Text(
                'Edit message',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text(
                'Delete message',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') await _promptEditDm(msg, peerId);
    if (action == 'delete') await _confirmDeleteDm(msg, peerId);
  }

  Future<void> _confirmDeleteDm(
    Map<String, dynamic> msg,
    String peerId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161A22),
        title: const Text('Delete message?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This removes the message from the conversation.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final mid = _messageId(msg);
      if (mid.isEmpty) return;
      setState(() {
        final i = _chat.indexWhere((m) => _messageId(m) == mid);
        if (i >= 0) {
          _chat[i] = {
            ..._chat[i],
            'message': 'This message was deleted.',
            '_localDeleted': true,
          };
        }
      });
      _service.deleteMessage(
        messageId: mid,
        receiverId: peerId,
      );
    }
  }

  Future<void> _promptEditDm(
    Map<String, dynamic> msg,
    String peerId,
  ) async {
    final ctrl = TextEditingController(text: (msg['message'] ?? '').toString());
    String? newText;
    try {
      newText = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161A22),
          title:
              const Text('Edit message', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Message',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save', style: TextStyle(color: _neon)),
            ),
          ],
        ),
      );
    } finally {
      // Dispose after route teardown — sync dispose causes framework assert.
      final c = ctrl;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        c.dispose();
      });
    }
    if (!mounted || newText == null || newText.isEmpty) return;
    final mid = _messageId(msg);
    if (mid.isEmpty) return;
    setState(() {
      final i = _chat.indexWhere((m) => _messageId(m) == mid);
      if (i >= 0) {
        _chat[i] = {..._chat[i], 'message': newText, '_localDeleted': false};
      }
    });
    _service.updateMessage(
      messageId: mid,
      newText: newText,
      receiverId: peerId,
    );
  }

  bool _isMyMessage(Map<String, dynamic> msg) {
    final auth = context.read<AuthViewModel>();
    final myId = (auth.currentUser?.id ?? '').trim();
    if (myId.isEmpty) return false;
    String? senderId = msg['senderId']?.toString() ?? msg['userId']?.toString();
    final senderObj = msg['sender'];
    if ((senderId == null || senderId.isEmpty) && senderObj is Map) {
      final m = Map<String, dynamic>.from(senderObj);
      senderId = m['_id']?.toString() ?? m['id']?.toString();
    }
    return senderId != null && senderId.isNotEmpty && senderId == myId;
  }

  /// Prefer server fields, but if [senderId] matches the logged-in user, show
  /// this account's nickname (fixes wrong duplicate names from the backend).
  String _senderLabel(Map<String, dynamic> msg) {
    final auth = context.read<AuthViewModel>();
    final myId = auth.currentUser?.id.trim() ?? '';
    final myNick = (auth.currentUser?.nickname ?? '').trim();

    String? senderId = msg['senderId']?.toString() ?? msg['userId']?.toString();
    final senderObj = msg['sender'];
    if ((senderId == null || senderId.isEmpty) && senderObj is Map) {
      final m = Map<String, dynamic>.from(senderObj);
      senderId = m['_id']?.toString() ?? m['id']?.toString();
    }

    if (myId.isNotEmpty &&
        senderId != null &&
        senderId.isNotEmpty &&
        senderId == myId) {
      return myNick.isNotEmpty ? myNick : 'You';
    }

    String? nick = msg['senderNickname']?.toString() ?? msg['nickname']?.toString();
    if ((nick == null || nick.isEmpty) && senderObj is Map) {
      final m = Map<String, dynamic>.from(senderObj);
      nick = m['nickname']?.toString() ?? m['username']?.toString();
    }
    if (nick != null && nick.trim().isNotEmpty) return nick.trim();

    if (senderId != null && senderId.isNotEmpty) return 'User';
    return 'User';
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
    if (!_connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDirectMessage
                ? 'Still connecting — wait a moment, then try again.'
                : 'Chat is reconnecting. Try again in a moment.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final auth = context.read<AuthViewModel>();
    final uid = auth.currentUser?.id;
    final nick = auth.currentUser?.nickname;
    _service.sendMessage(
      text,
      senderId: uid,
      senderNickname: nick,
    );
    _chatController.clear();
  }
}

