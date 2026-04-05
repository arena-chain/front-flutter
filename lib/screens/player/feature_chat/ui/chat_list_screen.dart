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
      final r2 = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/users/search?nickname='), headers: {'Authorization': 'Bearer $t'});
      if (mounted) {
        setState(() {
          if (r1.statusCode == 200) {
            final data1 = json.decode(r1.body);
            _conversations = (data1 is List) ? data1 : [];
          }
          if (r2.statusCode == 200) {
            final data2 = json.decode(r2.body);
            _players = (data2 is List) ? data2.take(12).toList() : [];
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
      onTap: () => Navigator.pushNamed(context, AppRoutes.chatDetail, arguments: {'userId': u['_id'], 'nickname': n, 'avatar': u['avatar']}),
      child: Container(width: 70, margin: const EdgeInsets.only(right: 15), child: Column(children: [
        Stack(
          children: [
            Container(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF00FF87).withOpacity(0.15), blurRadius: 12, spreadRadius: 1)]),
              child: _safeAvatar(u['avatar']?.toString(), n, size: 58)),
            Positioned(bottom: 2, right: 2, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: const Color(0xFF00FF87), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0A0E1A), width: 2.5))))
          ],
        ),
        const SizedBox(height: 8),
        Text(n, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)
      ])),
    );
  }

  Widget _buildRecentChat(dynamic c, BuildContext context) {
    final u = c['interlocutor'] ?? {}; 
    final n = u['nickname']?.toString() ?? 'Player';
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.chatDetail, arguments: {'userId': u['_id'], 'nickname': n, 'avatar': u['avatar']}),
      child: Container(margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(16), 
        decoration: BoxDecoration(color: const Color(0xFF13172E).withOpacity(0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Row(children: [
          _safeAvatar(u['avatar']?.toString(), n, size: 55), 
          const SizedBox(width: 15), 
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), 
            const SizedBox(height: 6),
            Text(c['lastMessage']?.toString() ?? 'Click here to send a message...', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)
          ]))
        ])
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int pCount = _safeLen(_players);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 5), child: Row(children: [
                    const Expanded(child: Text('Messages', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5))),
                    Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle), child: IconButton(onPressed: _load, icon: const Icon(Icons.sync, color: Color(0xFF00FF87), size: 22))),
                ])),
                Consumer<ChatWebRTCService>(builder: (_, s, __) => s.mediaError != null 
                  ? Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.error_outline, color: Colors.redAccent, size: 20), const SizedBox(width: 10), Expanded(child: Text(s.mediaError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)))])) 
                  : const SizedBox.shrink()),
                if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
                if (pCount > 0) ...[
                  const Padding(padding: EdgeInsets.fromLTRB(20, 15, 20, 15), child: Text('ONLINE NOW', style: TextStyle(color: Color(0xFF00FF87), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0))),
                  SizedBox(height: 90, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: pCount, itemBuilder: (_, i) {
                        try { return _buildOnlinePlayer(_players[i], context); } catch (_) { return const SizedBox.shrink(); }
                      })),
                ],
                const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 12), child: Text('VOICE ROOMS', style: TextStyle(color: Color(0xFFA855F7), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0))),
                SizedBox(height: 50, child: Consumer<ChatWebRTCService>(builder: (_, s, __) {
                    final rooms = ['Global', 'Alpha', 'Bravo'];
                    return ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: 3, itemBuilder: (_, i) {
                      final rId = rooms[i];
                      final id = (rId == 'Alpha' ? 'TeamA' : (rId == 'Bravo' ? 'TeamB' : 'Global'));
                      final active = s.currentVoiceRoomId == id;
                      return GestureDetector(onTap: () => s.joinVoiceRoom(id),
                        child: Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 28), decoration: BoxDecoration(gradient: active ? const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF6B21A8)]) : null, color: active ? null : const Color(0xFF13172E), borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? const Color(0xFFA855F7).withOpacity(0.5) : Colors.white10), boxShadow: active ? [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))] : null),
                          child: Center(child: Text(rId, style: TextStyle(color: active ? Colors.white : Colors.white60, fontWeight: FontWeight.bold, fontSize: 14)))));
                    });
                })),
                const Padding(padding: EdgeInsets.fromLTRB(20, 25, 20, 15), child: Text('RECENT CHATS', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0))),
                Expanded(child: (_isLoading == true)
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)))
                  : cCount == 0 
                    ? const Center(child: Text('Start a conversation above!', style: TextStyle(color: Colors.white24, fontSize: 16)))
                    : ListView.builder(itemCount: cCount, padding: const EdgeInsets.symmetric(horizontal: 20), itemBuilder: (_, i) {
                        try { return _buildRecentChat(_conversations[i], context); } catch (_) { return const SizedBox.shrink(); }
                      })),
              ],
            ),
          ),
          Consumer<ChatWebRTCService>(builder: (_, s, __) => s.currentVoiceRoomId == null ? const SizedBox.shrink() : Positioned(bottom: 25, left: 20, right: 20,
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), decoration: BoxDecoration(color: const Color(0xFF0A0E1A).withOpacity(0.95), borderRadius: BorderRadius.circular(25), border: Border.all(color: const Color(0xFFA855F7), width: 1.5), boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.2), blurRadius: 20, spreadRadius: 2)]),
              child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFA855F7).withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.multitrack_audio, color: Color(0xFFA855F7))), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('Voice Connected', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)), Text('${s.currentVoiceRoomId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))])),
                Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle), child: IconButton(onPressed: () => s.toggleMute(), icon: Icon(s.isMuted ? Icons.mic_off : Icons.mic, color: s.isMuted ? Colors.redAccent : Colors.white))), const SizedBox(width: 8),
                Container(decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle), child: IconButton(onPressed: () => s.leaveVoiceRoom(), icon: const Icon(Icons.call_end, color: Colors.redAccent)))],)))),
        ],
      ),
    );
  }
}
