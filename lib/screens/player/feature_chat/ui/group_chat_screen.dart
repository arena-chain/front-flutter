import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:arena_chain_flutter/core/services/chat_webrtc_service.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _groups = [];
  bool _loading = true;
  String? _error;
  dynamic _activeGroup;
  List<dynamic> _messages = [];
  bool _loadingMessages = false;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription? _socketSub;
  String? _token;
  String? _userId;
  List<dynamic> _myFriends = [];
  bool _loadingFriends = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = Provider.of<ChatWebRTCService>(context, listen: false);
      s.connectChatSocket();
      _socketSub = s.messageStream.listen((msg) {
        if (msg is Map && msg['groupId'] != null &&
            _activeGroup != null && msg['groupId'] == _activeGroup['_id']) {
          setState(() {
            // Check for duplicates (Optimistic UI vs Socket Echo)
            final String mId = (msg['_id'] ?? msg['id'] ?? '').toString();
            final bool exists = _messages.any((m) {
               final String existingId = (m['_id'] ?? m['id'] ?? '').toString();
               return existingId.isNotEmpty && existingId == mId;
            });
            if (!exists) {
              _messages.add(msg);
              _scrollToBottom();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    _socketSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      _token = await TokenStorage().getAccessToken();
      if (_token == null) {
        setState(() { _loading = false; _error = 'Auth required'; });
        return;
      }
      
      // Get user id from token payload
      final parts = _token!.split('.');
      if (parts.length == 3) {
        try {
          final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
          _userId = (payload['sub'] ?? payload['id'] ?? payload['_id'] ?? '').toString();
        } catch(_) {}
      }

      final r1 = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/group-chat/my'), headers: {'Authorization': 'Bearer $_token'});
      
      if (mounted) {
        setState(() {
          _loading = false;
          if (r1.statusCode == 200) {
            final data = json.decode(r1.body);
            _groups = data is List ? data : [];
          }
        });
      }

      // Load friends for invitation
      await _fetchFriends();
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _fetchFriends() async {
    if (_userId == null) return;
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/friendship/friends/$_userId'), headers: {'Authorization': 'Bearer $_token'});
      if (res.statusCode == 200) {
        final List<dynamic> friendships = json.decode(res.body);
        final List<dynamic> mappedFriends = friendships.map((f) {
          final reqId = (f['requesterId']?['_id'] ?? f['requesterId'] ?? '').toString();
          final isRequester = reqId == _userId;
          final otherUser = isRequester ? f['recipientId'] : f['requesterId'];
          
          return {
            'userId': (otherUser?['_id'] ?? otherUser ?? '').toString(),
            'nickname': otherUser?['nickname'] ?? 'Unknown Player',
            'avatar': otherUser?['avatar'],
          };
        }).toList();
        if (mounted) setState(() => _myFriends = mappedFriends);
      }
    } catch(_) {}
  }

  Future<void> _selectGroup(dynamic group) async {
    setState(() { _activeGroup = group; _loadingMessages = true; _messages = []; });
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/group-chat/${group['_id']}/messages'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (mounted && res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() { _messages = data is List ? data : []; _loadingMessages = false; });
        _scrollToBottom();
        
        // Join socket room
        final s = Provider.of<ChatWebRTCService>(context, listen: false);
        s.joinGroupRoom(group['_id']);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  void _sendMsg() {
    final text = _msgController.text.trim();
    if (text.isEmpty || _activeGroup == null) return;
    final s = Provider.of<ChatWebRTCService>(context, listen: false);
    s.sendGroupMessage(_activeGroup['_id'], text);
    _msgController.clear();
    // Optimistic UI
    setState(() => _messages.add({
      'senderId': _userId,
      'senderNickname': 'You',
      'message': text,
      'createdAt': DateTime.now().toIso8601String(),
      'groupId': _activeGroup['_id'],
    }));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showCreateDialog(String type) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final List<String> selectedFriendIds = [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF12141C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.1))),
          title: Text(type == 'room' ? 'Create My Room' : 'Create Group Chat',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _input(nameCtrl, 'Name *'),
                  const SizedBox(height: 14),
                  _input(descCtrl, 'Description (optional)'),
                  if (type == 'group') ...[
                    const SizedBox(height: 20),
                    const Text('INVITE FRIENDS', style: TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    if (_myFriends.isEmpty)
                      const Text('No friends yet. Add friends to invite them.', style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic))
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _myFriends.length,
                          itemBuilder: (context, index) {
                            final f = _myFriends[index];
                            final fid = f['userId'].toString();
                            final fname = f['nickname'] ?? 'Friend';
                            final isSelected = selectedFriendIds.contains(fid);
                            return CheckboxListTile(
                              title: Text(fname, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              value: isSelected,
                              activeColor: const Color(0xFF00FF87),
                              checkColor: Colors.black,
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onChanged: (val) {
                                setModalState(() { if (val!) selectedFriendIds.add(fid); else selectedFriendIds.remove(fid); });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: type == 'room' ? const Color(0xFFA855F7) : const Color(0xFF00FF87),
                foregroundColor: type == 'room' ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                _createGroup(name, descCtrl.text.trim(), type, selectedFriendIds);
              },
              child: const Text('CREATE', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createGroup(String name, String desc, String type, [List<String>? initialMembers]) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/group-chat'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': desc,
          'type': type,
          'memberIds': initialMembers ?? [],
          'isPrivate': type == 'room',
        }),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        final group = json.decode(res.body);
        setState(() => _groups.insert(0, group));
        if (mounted) _selectGroup(group);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showMembersDialog() async {
    final members = _activeGroup['members'] as List? ?? [];
    if (members.isEmpty) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12141C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: const Text('GROUP PARTICIPANTS', style: TextStyle(color: Color(0xFF00FF87), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (ctx, i) {
              final m = members[i];
              String nickname = 'Unknown Player';
              String? avatar;
              if (m is Map) {
                nickname = m['nickname'] ?? 'Player';
                avatar = m['avatar'];
              }
              final isOwner = (_activeGroup['ownerId']?['_id'] ?? _activeGroup['ownerId']).toString() == (_userId ?? '').toString();
              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  child: avatar != null ? null : Text(nickname[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                title: Text(nickname, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: (isOwner && m['userId'] != _userId) 
                  ? IconButton(icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 20), onPressed: () => _kickMember(m['userId']))
                  : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _kickMember(String memberId) async {
    if (_activeGroup == null) return;
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/group-chat/${_activeGroup['_id']}/leave?memberId=$memberId'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final updated = json.decode(res.body);
        setState(() => _activeGroup = updated);
        if (mounted) {
          Navigator.pop(context);
          _showMembersDialog();
        }
      }
    } catch(e) { /* ignore */ }
  }

  Future<void> _deleteGroup(String gid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12141C),
        title: const Text('DELETE GROUP?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to delete this room? This cannot be undone.', style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await http.delete(Uri.parse('${ApiConfig.baseUrl}/api/group-chat/$gid'), headers: {'Authorization': 'Bearer $_token'});
      if (res.statusCode == 200) {
        setState(() {
          _groups.removeWhere((g) => g['_id'] == gid);
          _activeGroup = null;
        });
      }
    } catch(e) { /* ignore */ }
  }

  Future<void> _invitePlayer(String friendId) async {
    if (_activeGroup == null) return;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/group-chat/${_activeGroup['_id']}/invite'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'memberId': friendId}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member invited!'), backgroundColor: Color(0xFF00FF87)),
          );
          // Refresh active group data to update member count
          _load();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _showInviteDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12141C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: const Text('Invite to Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
        content: SizedBox(
          width: double.maxFinite,
          child: _myFriends.isEmpty
            ? const Text('No friends found to invite.', style: TextStyle(color: Colors.white38))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _myFriends.length,
                itemBuilder: (context, index) {
                  final f = _myFriends[index];
                  final fid = f['userId'].toString();
                  // Check if already in group
                  bool inGroup = false;
                  if (_activeGroup['members'] is List) {
                    inGroup = (_activeGroup['members'] as List).any((m) => (m is String ? m == fid : m['_id'] == fid));
                  }
                  if (inGroup) return const SizedBox.shrink();

                  return ListTile(
                    title: Text(f['nickname'] ?? 'Friend', style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.add, color: Color(0xFF00FF87)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _invitePlayer(fid);
                    },
                  );
                },
              ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withOpacity(0.07),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final groups = _groups.where((g) => g['type'] == 'group').toList();
    final rooms = _groups.where((g) => g['type'] == 'room').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(children: [
                const Expanded(
                  child: Text('Groups & Rooms',
                    style: TextStyle(color: Colors.white, fontSize: 28,
                        fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.sync, color: Color(0xFF00FF87)),
                ),
                PopupMenuButton<String>(
                  color: const Color(0xFF12141C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: _showCreateDialog,
                  icon: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF87).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.add, color: Color(0xFF00FF87), size: 20),
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'group',
                      child: Row(children: const [
                        Icon(Icons.group, color: Color(0xFF00FF87), size: 18),
                        SizedBox(width: 10),
                        Text('New Group Chat', style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'room',
                      child: Row(children: const [
                        Icon(Icons.home, color: Color(0xFFA855F7), size: 18),
                        SizedBox(width: 10),
                        Text('My Room', style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                  ],
                ),
              ]),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFF00FF87).withOpacity(0.15),
                    const Color(0xFF00C864).withOpacity(0.05),
                  ]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.4), width: 1),
                ),
                labelColor: const Color(0xFF00FF87),
                unselectedLabelColor: Colors.white24,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'GROUPS (${groups.length})'),
                  Tab(text: 'MY ROOMS (${rooms.length})'),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)))
                : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                  : _activeGroup != null
                    ? _buildChatView()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGroupList(groups, 'group'),
                          _buildGroupList(rooms, 'room'),
                        ],
                      ),
            ),
          ],
        ),
        // Hidden Voice Renderers for Audio playback in Web/Desktop
        Positioned(
          left: -100, top: -100, width: 1, height: 1,
          child: Consumer<ChatWebRTCService>(
            builder: (_, s, __) => SizedBox(
              width: 1, height: 1,
              child: ListView(
                children: s.roomRenderers.values.map((r) => SizedBox(
                  width: 1, height: 1,
                  child: RTCVideoView(r),
                )).toList(),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
}

  Widget _buildGroupList(List<dynamic> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type == 'room' ? Icons.home_outlined : Icons.group_outlined,
                color: Colors.white12, size: 64),
            const SizedBox(height: 16),
            Text('No ${type == 'room' ? 'rooms' : 'groups'} yet',
                style: const TextStyle(color: Colors.white24, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: type == 'room'
                    ? const Color(0xFFA855F7).withOpacity(0.2)
                    : const Color(0xFF00FF87).withOpacity(0.2),
                foregroundColor: type == 'room' ? const Color(0xFFA855F7) : const Color(0xFF00FF87),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showCreateDialog(type),
              child: Text('Create ${type == 'room' ? 'My Room' : 'Group'}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }

    return Scrollbar(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final g = items[i];
          final color = type == 'room' ? const Color(0xFFA855F7) : const Color(0xFF00FF87);
          final initial = (g['name'] ?? 'G')[0].toUpperCase();
          final memberCount = (g['members'] as List?)?.length ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                if (g['_id'] != null) _selectGroup(g);
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withOpacity(0.12), width: 1),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.03), blurRadius: 20, spreadRadius: -5),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color.withOpacity(0.25), color.withOpacity(0.05)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g['name'] ?? '', style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.2)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 4)]),
                              ),
                              const SizedBox(width: 8),
                              Text('$memberCount member${memberCount != 1 ? 's' : ''} ${type == 'room' ? '• Voice Active' : ''}',
                                  style: TextStyle(color: type == 'room' ? const Color(0xFFA855F7) : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (g['description'] != null && (g['description'] as String).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(g['description'], maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic)),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.1), size: 28),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatView() {
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => setState(() { _activeGroup = null; _messages = []; }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((_activeGroup['name'] ?? '').toUpperCase(), style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              InkWell(
                onTap: _showMembersDialog,
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00FF87), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${(_activeGroup['members'] as List?)?.length ?? 0} PARTICIPANTS',
                        style: const TextStyle(color: Color(0xFF00FF87), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5, decoration: TextDecoration.underline)),
                  ],
                ),
              ),
            ],
          )),
          if ((_activeGroup['type'] ?? '') == 'room')
            Consumer<ChatWebRTCService>(builder: (_, s, __) {
              final inThisRoom = s.currentVoiceRoomId == _activeGroup['_id'];
              return IconButton(
                style: IconButton.styleFrom(backgroundColor: inThisRoom ? const Color(0xFFA855F7).withOpacity(0.1) : Colors.transparent),
                icon: Icon(inThisRoom ? Icons.volume_up_rounded : Icons.mic_rounded,
                    color: inThisRoom ? const Color(0xFFA855F7) : Colors.white24, size: 22),
                onPressed: () {
                  if (inThisRoom) s.leaveVoiceRoom();
                  else s.joinVoiceRoom(_activeGroup['_id']);
                },
              );
            }),
          if ((_activeGroup['ownerId'] ?? '').toString() == (_userId ?? '').toString() && (_activeGroup['type'] ?? '') == 'group')
            IconButton(
              icon: const Icon(Icons.person_add_rounded, color: Color(0xFF00FF87), size: 22),
              onPressed: _showInviteDialog,
            ),
          if ((_activeGroup['ownerId']?['_id'] ?? _activeGroup['ownerId']).toString() == (_userId ?? '').toString())
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
              onPressed: () => _deleteGroup(_activeGroup['_id']),
            ),
        ]),
      ),

      // Messages
      Expanded(
        child: _loadingMessages
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)))
          : _messages.isEmpty
            ? const Center(child: Text('No messages yet. Say something! 👋',
                style: TextStyle(color: Colors.white24)))
            : Scrollbar(
                controller: _scrollController,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _buildMsgBubble(_messages[i]),
                ),
              ),
      ),

      // Input
      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Say something cool...',
                  hintStyle: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: (_) => _sendMsg(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMsg,
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00FF87), Color(0xFF00C864)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: const Color(0xFF00FF87).withOpacity(0.2), blurRadius: 15, spreadRadius: 2)],
              ),
              child: const Icon(Icons.send_rounded, color: Color(0xFF0A0E1A), size: 24),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildMsgBubble(dynamic msg) {
    final isSelf = (msg['senderId']?.toString() ?? '') == (_userId ?? '');
    final time = msg['createdAt'] != null
        ? TimeOfDay.fromDateTime(DateTime.parse(msg['createdAt'])).format(context)
        : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSelf) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.1),
              child: Text(
                (msg['senderNickname'] ?? '?')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isSelf)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(msg['senderNickname'] ?? 'Player',
                      style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelf
                      ? const LinearGradient(colors: [Color(0xFF00FF87), Color(0xFF00C864)])
                      : null,
                  color: isSelf ? null : Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isSelf ? const Radius.circular(18) : const Radius.circular(4),
                    bottomRight: isSelf ? const Radius.circular(4) : const Radius.circular(18),
                  ),
                ),
                child: Text(msg['message'] ?? '',
                    style: TextStyle(
                        color: isSelf ? const Color(0xFF0A0E1A) : Colors.white,
                        fontSize: 14)),
              ),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
