import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/core/services/chat_webrtc_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _conversations = [];
  List<dynamic> _players = [];
  bool? _isLoading = true;
  String? _error;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = Provider.of<ChatWebRTCService>(context, listen: false);
      s.connectChatSocket();
      _sub = s.messageStream.listen((_) => _load());
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final t = await TokenStorage().getAccessToken();
      if (t == null) {
        setState(() { _isLoading = false; _error = "Auth Required"; });
        return;
      }
      final r1 = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/chat/inbox'), headers: {'Authorization': 'Bearer $t'});
      http.Response? r2;
      for (final endpoint in [
        '${ApiConfig.baseUrl}/api/presence/friends/online',
        '${ApiConfig.baseUrl}/presence/friends/online',
      ]) {
        final resp = await http.get(Uri.parse(endpoint), headers: {'Authorization': 'Bearer $t'});
        if (resp.statusCode == 200) {
          r2 = resp;
          break;
        }
      }
      if (mounted) {
        setState(() {
          if (r1.statusCode == 200) {
            final data1 = json.decode(r1.body);
            _conversations = (data1 is List) ? data1 : [];
          }
          if (r2 != null && r2.statusCode == 200) {
            final data2 = json.decode(r2.body);
            debugPrint('Presence Data: ${r2.body}');
            _players = (data2 is List) ? data2 : [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = "Connect Error"; });
    }
  }

  int _safeLen(dynamic list) {
    try { return (list is List) ? list.length : 0; } catch (_) { return 0; }
  }

  Widget _safeAvatar(String? url, String? name, {double size = 45}) {
    String sUrl = url?.toString() ?? "";
    final sName = name?.toString() ?? "?";
    
    // Auto-fix relative urls
    if (sUrl != "" && !sUrl.startsWith("http") && !sUrl.startsWith("data:") && sUrl != "null") {
      if (sUrl.startsWith("/")) sUrl = "${ApiConfig.baseUrl}$sUrl";
      else sUrl = "${ApiConfig.baseUrl}/$sUrl";
    }

    // Convert Dicebear SVGs to PNGs for native Flutter support
    if (sUrl.contains("dicebear.com")) {
      sUrl = sUrl.replaceAll("/svg", "/png");
      sUrl = sUrl.replaceAll(".svg", ".png");
    }

    // Block remaining unsupported SVGs
    final hasUrl = sUrl != "" && !sUrl.endsWith(".svg") && sUrl != "null";
    
    double h = 200.0;
    try { if (sName != "") h = (sName.codeUnitAt(0) * 20.0) % 360.0; } catch(_) {}
    
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF13172E), border: Border.all(color: Colors.white10)),
      child: ClipOval(child: hasUrl
        ? Image.network(sUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _colorAvatar(sName, h))
        : _colorAvatar(sName, h)),
    );
  }

  Widget _colorAvatar(String n, double h) {
    String initial = "?";
    try { if (n != "") initial = n[0].toUpperCase(); } catch (_) {}
    return Container(
      color: HSVColor.fromAHSV(1.0, h, 0.7, 0.5).toColor(),
      child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
    );
  }

  Widget _buildOnlinePlayer(dynamic u, BuildContext context) {
    final n = u['nickname']?.toString() ?? 'Player';
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.chatDetail, arguments: {
        'userId': (u['userId'] ?? u['_id'] ?? '').toString(),
        'nickname': n,
        'avatar': u['avatar']?.toString()
      }),
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 18),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3), width: 2),
                    boxShadow: [BoxShadow(color: const Color(0xFF00FF87).withOpacity(0.1), blurRadius: 12)],
                  ),
                  child: ClipOval(
                    child: _safeAvatar(u['avatar']?.toString(), n, size: 64),
                  ),
                ),
                Positioned(
                  right: 2, bottom: 2,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF87),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0A0E1A), width: 3),
                      boxShadow: [BoxShadow(color: const Color(0xFF00FF87).withOpacity(0.5), blurRadius: 5)],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(n, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.2), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentChat(dynamic c, BuildContext context) {
    final u = c['interlocutor'] ?? {}; 
    final n = u['nickname']?.toString() ?? 'Player';
    final lastMsg = c['lastMessage']?.toString() ?? 'Click here to send a message...';
    final isUnread = (c['unreadCount'] ?? 0) > 0;
    final time = c['lastMessageAt']?.toString() ?? c['updatedAt']?.toString();
    String timeLabel = '';
    if (time != null && time.isNotEmpty) {
      try {
        final dt = DateTime.parse(time).toLocal();
        final now = DateTime.now();
        final diff = now.difference(dt);
        if (diff.inDays >= 2) {
          timeLabel = '${diff.inDays} DAYS AGO';
        } else if (diff.inDays == 1) {
          timeLabel = 'YESTERDAY';
        } else {
          final hh = dt.hour.toString().padLeft(2, '0');
          final mm = dt.minute.toString().padLeft(2, '0');
          timeLabel = '$hh:$mm';
        }
      } catch (_) {}
    }
    
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.chatDetail, arguments: {
        'userId': (u['_id'] ?? u['userId'] ?? '').toString(),
        'nickname': (u['nickname'] ?? 'Player').toString(),
        'avatar': u['avatar']?.toString(),
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _safeAvatar(u['avatar']?.toString(), n, size: 52),
                if (u['isActive'] == true)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(width: 13, height: 13, decoration: BoxDecoration(color: const Color(0xFF00FF87), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0A0E1A), width: 2))),
                  ),
              ],
            ),
            const SizedBox(width: 12), 
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeLabel.isNotEmpty)
                        Text(
                          timeLabel,
                          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMsg,
                    style: TextStyle(
                      color: isUnread ? const Color(0xFF65FF87) : Colors.white54,
                      fontSize: 15,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int cCount = _safeLen(_conversations);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          Consumer<ChatWebRTCService>(
            builder: (_, s, __) {
              final views = <Widget>[];
              try {
                s.roomRenderers.forEach((k, v) {
                  if (v != null) views.add(SizedBox(width: 1, height: 1, child: RTCVideoView(v)));
                });
              } catch (_) {}
              if (_safeLen(views) == 0) return const SizedBox.shrink();
              return Positioned(
                left: 0, top: 0, width: 2, height: 2,
                child: Stack(
                  children: views.map((v) => SizedBox(
                    width: 2, height: 2,
                    child: v,
                  )).toList(),
                ),
              );
            },
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Messages',
                          style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF39FF14),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Consumer<ChatWebRTCService>(builder: (_, s, __) => s.mediaError != null 
                    ? Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.error_outline, color: Colors.redAccent, size: 20), const SizedBox(width: 10), Expanded(child: Text(s.mediaError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)))])) 
                    : const SizedBox.shrink()),
                ),
                if (_error != null) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))),
                
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(20, 18, 20, 10), child: Text('VOICE ROOMS', style: TextStyle(color: Color(0xFFB5BBC7), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0)))),
                SliverToBoxAdapter(
                  child: SizedBox(height: 42, child: Consumer<ChatWebRTCService>(builder: (_, s, __) {
                      final rooms = ['Global', 'Alpha', 'Bravo'];
                      return ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: 3, itemBuilder: (_, i) {
                        final rId = rooms[i];
                        final id = (rId == 'Alpha' ? 'TeamA' : (rId == 'Bravo' ? 'TeamB' : 'Global'));
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
                              child: Text(
                                rId.toUpperCase(),
                                style: TextStyle(color: active ? Colors.black : Colors.white70, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.2),
                              ),
                            ),
                          ),
                        );
                      });
                  })),
                ),
                
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
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Groups & Rooms',
                                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text('Chat with multiple friends at once',
                                  style: TextStyle(color: Colors.white70, fontSize: 15)),
                            ],
                          )),
                          const Icon(Icons.groups_rounded, color: Color(0xFF2A3A2A), size: 26),
                        ]),
                      ),
                    ),
                  ),
                ),

                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                  sliver: SliverToBoxAdapter(child: Text('RECENT CHATS', style: TextStyle(color: Color(0xFFB5BBC7), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0))),
                ),
                
                if (_isLoading == true)
                  const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: Color(0xFF00FF87))))
                else if (cCount == 0)
                  const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('Start a conversation above!', style: TextStyle(color: Colors.white24, fontSize: 16))))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          try { return _buildRecentChat(_conversations[i], context); } catch (_) { return const SizedBox.shrink(); }
                        },
                        childCount: cCount,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Consumer<ChatWebRTCService>(builder: (_, s, __) => s.currentVoiceRoomId == null ? const SizedBox.shrink() : Positioned(
            bottom: 30, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(16), 
              decoration: BoxDecoration(
                color: const Color(0xFF12141C).withOpacity(0.98), 
                borderRadius: BorderRadius.circular(28), 
                border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3), width: 1.5), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 25, spreadRadius: 5)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: const Color(0xFFA855F7).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.multitrack_audio_rounded, color: Color(0xFFA855F7)),
                  ),
                  const SizedBox(width: 14), 
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        const Text('CONNECTED VOICE', style: TextStyle(color: Color(0xFFA855F7), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)), 
                        const SizedBox(height: 2),
                        Text(s.currentVoiceRoomId!.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => s.toggleMute(), 
                    icon: Icon(s.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, color: s.isMuted ? Colors.redAccent : Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => s.leaveVoiceRoom(), 
                    icon: const Icon(Icons.call_end_rounded, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.redAccent),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
