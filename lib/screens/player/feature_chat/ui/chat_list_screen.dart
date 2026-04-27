import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/core/services/chat_webrtc_service.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart' as arena_auth;
import 'package:provider/provider.dart';
import 'dart:async';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _players = [];
  bool _isLoading = true;
  String? _error;
  arena_auth.AuthViewModel? _authVm;

  String _sanitize(dynamic msg) {
    if (msg == null) return '';
    final str = msg.toString();
    if (str.contains('§')) return 'Sent an encrypted message';
    if (str.startsWith(':')) {
       final parts = str.split(':');
       if (parts.length > 2) return parts.sublist(2).join(':').trim();
       if (parts.length == 3 && parts[2].isEmpty) return parts[1];
       return str;
    }
    return str;
  }

  /// Decode JWT payload to extract user ID without needing context after await
  static String _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return '';
      // Pad base64url to correct length
      String payload = parts[1];
      while (payload.length % 4 != 0) { payload += '='; }
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = json.decode(decoded) as Map<String, dynamic>;
      final sub = map['sub']?.toString() ?? '';
      if (sub.isNotEmpty) return sub;
      final uid = map['userId']?.toString() ?? '';
      if (uid.isNotEmpty) return uid;
      return map['id']?.toString() ?? '';
    } catch (_) { return ''; }
  }

  VoidCallback? _serviceListener;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authVm = Provider.of<arena_auth.AuthViewModel>(context, listen: false);
      _authVm!.addListener(_onAuthChanged);
      
      try {
        final s = Provider.of<ChatWebRTCService>(context, listen: false);
        s.connectChatSocket();
        
        _serviceListener = () {
          if (mounted) {
            debugPrint('🔔 Service notified listener - refreshing list');
            _load(silent: true);
          }
        };
        s.addListener(_serviceListener!);
      } catch (e) {
        debugPrint('Socket init error: $e');
      }
    });
  }

  void _onAuthChanged() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    _authVm?.removeListener(_onAuthChanged);
    if (_serviceListener != null) {
      try {
        final s = Provider.of<ChatWebRTCService>(context, listen: false);
        s.removeListener(_serviceListener!);
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
       setState(() { _isLoading = true; _error = null; });
    }

    try {
      final t = await TokenStorage().getAccessToken();
      if (t == null) {
        if (mounted) setState(() { _isLoading = false; _error = 'Auth Required'; });
        return;
      }

      // Extract userId from JWT token directly — no context needed after await
      String userId = _extractUserIdFromToken(t);
      // Fallback: try ViewModel if token extraction fails
      if (userId.isEmpty) {
        userId = _authVm?.currentUser?.id ?? '';
      }
      debugPrint('Chat load: userId=$userId');
      // ── Inbox ──────────────────────────────────────────────
      List<Map<String, dynamic>> newConversations = [];
      try {
        final r1 = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/chat/inbox'),
          headers: {'Authorization': 'Bearer $t'},
        );
        if (r1.statusCode == 200) {
          final decoded = json.decode(r1.body);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map) newConversations.add(Map<String, dynamic>.from(item));
            }
          }
        }
      } catch (e) {
        debugPrint('Inbox error: $e');
      }

      // ── Presence ───────────────────────────────────────────
      List<Map<String, dynamic>> newPlayers = [];
      if (userId.isNotEmpty) {
        for (final base in [
          '${ApiConfig.baseUrl}/api/presence/friends/$userId',
          '${ApiConfig.baseUrl}/presence/friends/$userId',
        ]) {
          try {
            final resp = await http.get(
              Uri.parse(base),
              headers: {'Authorization': 'Bearer $t'},
            );
            if (resp.statusCode == 200) {
              final decoded = json.decode(resp.body);
              List<dynamic> raw = [];
              if (decoded is Map && decoded['friends'] is List) {
                raw = decoded['friends'] as List<dynamic>;
              } else if (decoded is List) {
                raw = decoded;
              }
              for (final item in raw) {
                if (item is Map) {
                  final mapped = Map<String, dynamic>.from(item);
                  // Only show real connected friends (status != offline)
                  if (mapped['status'] != 'offline') {
                    newPlayers.add(mapped);
                  }
                }
              }
              debugPrint('Presence: ${newPlayers.length} online friends loaded');
              break;
            }
          } catch (e) {
            debugPrint('Presence error: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _conversations = newConversations;
          _players = newPlayers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('_load error: $e');
      if (mounted) setState(() { _isLoading = false; _error = 'Connect Error'; });
    }
  }

  Future<void> _createGroupDialog() async {
    final TextEditingController nameCtrl = TextEditingController();
    List<String> selectedIds = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0A0E1A),
          title: const Text('CREATE NEW GROUP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('SELECT FRIENDS', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _players.length,
                    itemBuilder: (context, i) {
                      final p = _players[i];
                      final uid = p['userId'] ?? p['_id'];
                      final isSelected = selectedIds.contains(uid);
                      return CheckboxListTile(
                        title: Text(p['nickname'] ?? 'Player', style: const TextStyle(color: Colors.white)),
                        value: isSelected,
                        activeColor: const Color(0xFF00FF87),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) selectedIds.add(uid);
                            else selectedIds.remove(uid);
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87)),
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                try {
                  final t = await TokenStorage().getAccessToken();
                  final res = await http.post(
                    Uri.parse('${ApiConfig.baseUrl}/api/group-chat'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $t'
                    },
                    body: json.encode({
                      'name': nameCtrl.text,
                      'memberIds': selectedIds,
                    }),
                  );
                  if (res.statusCode == 201) {
                    Navigator.pop(context);
                    _load();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group created!'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  debugPrint('Create group error: $e');
                }
              },
              child: const Text('CREATE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────── Helpers ───────────────────────────────

  String _safeStr(Map<String, dynamic> m, String key, {String fallback = ''}) {
    try { return m[key]?.toString() ?? fallback; } catch (_) { return fallback; }
  }

  Widget _safeAvatar(String? rawUrl, String name, {double size = 45}) {
    String url = rawUrl?.toString() ?? '';
    if (url.isNotEmpty && !url.startsWith('http') && !url.startsWith('data:')) {
      url = url.startsWith('/') ? '${ApiConfig.baseUrl}$url' : '${ApiConfig.baseUrl}/$url';
    }
    if (url.contains('dicebear.com')) {
      url = url.replaceAll('/svg', '/png').replaceAll('.svg', '.png');
    }
    final valid = url.isNotEmpty && !url.endsWith('.svg');
    final h = name.isNotEmpty ? (name.codeUnitAt(0) * 20.0) % 360.0 : 200.0;

    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF13172E),
      ),
      child: ClipOval(
        child: valid
            ? Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _colorAvatar(name, h))
            : _colorAvatar(name, h),
      ),
    );
  }

  Widget _colorAvatar(String name, double h) => Container(
    color: HSVColor.fromAHSV(1.0, h, 0.7, 0.5).toColor(),
    child: Center(
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    ),
  );

  // ─────────────────────────────── Tiles ─────────────────────────────────

  Widget _buildOnlinePlayer(Map<String, dynamic> u) {
    final n = _safeStr(u, 'nickname', fallback: 'Player');
    final uid = _safeStr(u, 'userId') .isNotEmpty
        ? _safeStr(u, 'userId')
        : _safeStr(u, '_id');
    final avatar = u['avatar']?.toString();
    final status = _safeStr(u, 'status', fallback: 'offline');
    final isOnline = status == 'online' || status == 'in_game' || status == 'in_queue';
    final dotColor = isOnline ? const Color(0xFF00FF87) : Colors.grey;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.chatDetail,
          arguments: {'userId': uid, 'nickname': n, 'avatar': avatar}),
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 18),
        child: Column(
          children: [
            Stack(children: [
              _safeAvatar(avatar, n, size: 64),
              Positioned(
                right: 2, bottom: 2,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0A0E1A), width: 2),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(n,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentChat(Map<String, dynamic> c) {
    final isGroup = c['isGroup'] == true;
    final uRaw = c['interlocutor'];
    final u = (uRaw is Map) ? Map<String, dynamic>.from(uRaw) : <String, dynamic>{};
    final n = _safeStr(u, 'nickname', fallback: isGroup ? 'Group' : 'Player');
    final uid = _safeStr(u, '_id').isNotEmpty ? _safeStr(u, '_id') : _safeStr(u, 'userId');
    final avatar = u['avatar']?.toString();
    final lastMsg = _safeStr(c, 'lastMessage', fallback: 'Tap to start chatting...');
    final unread = (c['unreadCount'] is num) ? (c['unreadCount'] as num).toInt() : 0;
    final isUnread = unread > 0;
    final timeRaw = c['lastMessageAt']?.toString() ?? c['updatedAt']?.toString() ?? '';
    String timeLabel = '';
    if (timeRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(timeRaw).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inDays >= 2) timeLabel = '${diff.inDays}d';
        else if (diff.inDays == 1) timeLabel = 'YESTERDAY';
        else timeLabel = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        if (isGroup) {
          Navigator.pushNamed(context, AppRoutes.groupChat);
        } else {
          Navigator.pushNamed(context, AppRoutes.chatDetail,
              arguments: {'userId': uid, 'nickname': n, 'avatar': avatar});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              if (isGroup)
                Container(
                  width: 52, height: 52,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF13172E)),
                  child: const Center(child: Icon(Icons.group_rounded, color: Color(0xFF00FF87), size: 28)),
                )
              else
                _safeAvatar(avatar, n, size: 52),
              if (!isGroup && u['isActive'] == true)
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 13, height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF87),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0A0E1A), width: 2),
                    ),
                  ),
                ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(n.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                  if (timeLabel.isNotEmpty)
                    Text(timeLabel, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ]),
                const SizedBox(height: 2),
                Text(lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnread ? const Color(0xFF65FF87) : Colors.white54,
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                    )),
              ]),
            ),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF87),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$unread', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Messages',
                        style: TextStyle(color: Colors.white, fontSize: 40,
                            fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                    SizedBox(height: 8),
                    SizedBox(
                      width: 40, height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF39FF14),
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Media / mic error from WebRTC service
            SliverToBoxAdapter(
              child: Consumer<ChatWebRTCService>(builder: (_, s, __) {
                if (s.mediaError == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.mediaError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                  ]),
                );
              }),
            ),

            // Error banner
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              ),

            // ── Online Users ─────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Text('ONLINE FRIENDS',
                    style: TextStyle(color: Color(0xFFB5BBC7), fontSize: 12,
                        fontWeight: FontWeight.w900, letterSpacing: 2.0)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: _isLoading
                    ? const Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Color(0xFF00FF87), strokeWidth: 2)))
                    : _players.isEmpty
                        ? const Center(
                            child: Text('No friends online',
                                style: TextStyle(color: Colors.white24, fontSize: 13)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _players.length,
                            itemBuilder: (_, i) => _buildOnlinePlayer(_players[i]),
                          ),
              ),
            ),

            // ── Voice Rooms ──────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Text('VOICE ROOMS',
                    style: TextStyle(color: Color(0xFFB5BBC7), fontSize: 12,
                        fontWeight: FontWeight.w900, letterSpacing: 2.0)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 42,
                child: Consumer<ChatWebRTCService>(builder: (_, s, __) {
                  const rooms = [('Global', 'Global'), ('Alpha', 'TeamA'), ('Bravo', 'TeamB')];
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: rooms.length,
                    itemBuilder: (_, i) {
                      final (label, id) = rooms[i];
                      final active = s.currentVoiceRoomId == id;
                      return GestureDetector(
                        onTap: () => active ? s.leaveVoiceRoom() : s.joinVoiceRoom(id),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFF39FF14) : const Color(0xFF1B1E25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(label.toUpperCase(),
                                style: TextStyle(
                                  color: active ? Colors.black : Colors.white70,
                                  fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),

            // ── Groups ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.groupChat),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1C23),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF11151D),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.hub_rounded, color: Color(0xFF65FF87), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Groups & Rooms',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text('Chat with multiple friends at once',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                        ]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00FF87), size: 28),
                        onPressed: _createGroupDialog,
                      ),
                      const Icon(Icons.groups_rounded, color: Colors.white10, size: 24),
                    ]),
                  ),
                ),
              ),
            ),

            // ── Recent Chats ─────────────────────────────────────
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text('RECENT CHATS',
                    style: TextStyle(color: Color(0xFFB5BBC7), fontSize: 12,
                        fontWeight: FontWeight.w900, letterSpacing: 2.0)),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF00FF87))),
              )
            else if (_conversations.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('Start a conversation above!',
                      style: TextStyle(color: Colors.white24, fontSize: 16)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      try {
                        return _buildRecentChat(_conversations[i]);
                      } catch (e) {
                        debugPrint('Chat tile error: $e');
                        return const SizedBox.shrink();
                      }
                    },
                    childCount: _conversations.length,
                  ),
                ),
              ),
          ],
        ),
      ),

      // Active voice room banner
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Consumer<ChatWebRTCService>(builder: (_, s, __) {
        if (s.currentVoiceRoomId == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF12141C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.mic_rounded, color: Color(0xFFA855F7)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CONNECTED VOICE', style: TextStyle(color: Color(0xFFA855F7), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text(s.currentVoiceRoomId!.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              ]),
            ),
            IconButton(
              onPressed: s.toggleMute,
              icon: Icon(s.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: s.isMuted ? Colors.redAccent : Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white12),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: s.leaveVoiceRoom,
              icon: const Icon(Icons.call_end_rounded, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
          ]),
        );
      }),
    );
  }
}
