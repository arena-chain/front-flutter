import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart' as config;
import 'package:arena_chain_flutter/core/services/chat_webrtc_service.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class ChatDetailScreen extends StatefulWidget {
  final String userId;
  final String nickname;
  final String? avatar;

  const ChatDetailScreen({
    super.key,
    required this.userId,
    required this.nickname,
    this.avatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _showEmojiPicker = false;
  final TextEditingController _msgController = TextEditingController();

  final List<String> _emojis = [
    '🎮', '🕹️', '🔥', '🏆', '💣', '🔫', '🚀', '🛡️', '❤️', '💀', '👑', '💎',
    '👊', '⚡', '🌟', '👾', '👽', '🤖', '👻', '💥', '✨', '💯', '😎', '😂'
  ];

  StreamSubscription? _msgSub;

  @override
  void initState() {
    super.initState();
    _fetchConversation();
    _markAsRead();

    // Listen for new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService = Provider.of<ChatWebRTCService>(context, listen: false);
      chatService.connectChatSocket();
      _msgSub = chatService.messageStream.listen((data) {
        if (data == null) return;
        
        final String sId = data['senderId']?.toString() ?? '';
        final String rId = data['receiverId']?.toString() ?? '';
        
        // If message is from interlocutor OR from me to interlocutor
        if (mounted && (sId == widget.userId || rId == widget.userId)) {
          setState(() {
            // Check if message already exists to avoid duplicates
            final exists = _messages.any((m) => m['_id'] == data['_id']);
            if (!exists) {
              _messages.insert(0, data);
            }
          });
          if (sId == widget.userId) _markAsRead();
        }
      });
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _msgController.dispose();
    super.dispose();
  }

  String _sanitize(dynamic msg) {
    if (msg == null) return '';
    final str = msg.toString();
    if (str.contains('§')) return 'Sent an encrypted message';
    if (str.startsWith(':')) {
       final parts = str.split(':');
       // If it follows :id:text or similar, extract the text part
       if (parts.length > 2) return parts.sublist(2).join(':').trim();
       // If it is just :something: then it might be a code
       if (parts.length == 3 && parts[2].isEmpty) return parts[1];
       return str;
    }
    return str;
  }

  Future<void> _markAsRead() async {
    try {
      final token = await TokenStorage().getAccessToken();
      await http.patch(
        Uri.parse('${config.ApiConfig.baseUrl}/api/chat/read/${widget.userId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _fetchConversation() async {
    try {
      final token = await TokenStorage().getAccessToken();
      final res = await http.get(
        Uri.parse('${config.ApiConfig.baseUrl}/api/chat/conversation/${widget.userId}?limit=50'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _messages = data is List ? List.from(data) : [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      final token = await TokenStorage().getAccessToken();
      final res = await http.delete(
        Uri.parse('${config.ApiConfig.baseUrl}/api/chat/message/$messageId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() {
          _messages.removeWhere((m) => m != null && m['_id'] == messageId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message deleted'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }

  Future<void> _clearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1221),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Clear Conversation?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This will delete all messages with this user permanently.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('CLEAR ALL', style: TextStyle(color: Color(0xFFFF0055), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final token = await TokenStorage().getAccessToken();
        await http.delete(
          Uri.parse('${config.ApiConfig.baseUrl}/api/chat/conversation/${widget.userId}'),
          headers: {'Authorization': 'Bearer $token'},
        );
        setState(() => _messages = []);
      } catch (e) {
        debugPrint('Error clearing conversation: $e');
      }
    }
  }

  void _showDeleteOption(dynamic msg) {
    if (msg == null) return;
    final msgId = msg['_id'];
    if (msgId == null) return;

    HapticFeedback.heavyImpact(); // iPhone-style physical feedback

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1221),
      barrierColor: Colors.black.withOpacity(0.8),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(5)), margin: const EdgeInsets.only(bottom: 20)),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFF0055).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline, color: Color(0xFFFF0055)),
                ),
                title: const Text('Delete for everyone', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('This message will be removed for both users', style: TextStyle(color: Colors.white38, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(msgId);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                  child: const Icon(Icons.copy, color: Colors.white70),
                ),
                title: const Text('Copy Text', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: msg['message'] ?? ''));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, String fallback) {
    String? validUrl = url;
    if (validUrl != null && validUrl.contains('dicebear') && validUrl.contains('/svg')) {
      validUrl = validUrl.replaceAll('/svg', '/png');
    }

    if (validUrl == null || validUrl.isEmpty || validUrl.endsWith('.svg')) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFF00FF00).withOpacity(0.2),
        child: Text(
          (fallback.isNotEmpty == true) ? fallback[0].toUpperCase() : 'P', 
          style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.bold)
        ),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFF00FF00).withOpacity(0.2),
      backgroundImage: NetworkImage(validUrl),
      onBackgroundImageError: (_, __) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: Row(
          children: [
            _buildAvatar(widget.avatar, widget.nickname),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.nickname,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F1221),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFFF0055), size: 22),
            tooltip: 'Clear Conversation',
            onPressed: _clearConversation,
          ),
        ],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showEmojiPicker = false),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)))
                  : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final msg = _messages[i];
                            if (msg == null) return const SizedBox.shrink();
                            final isMe = msg['senderId'] != widget.userId; 
                            
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: GestureDetector(
                                onLongPress: () => _showDeleteOption(msg),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                      decoration: BoxDecoration(
                                        color: isMe ? const Color(0xFF00FF00).withOpacity(0.15) : const Color(0xFF1E2235),
                                        borderRadius: BorderRadius.circular(18).copyWith(
                                          bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(18),
                                          bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(0),
                                        ),
                                        border: Border.all(color: isMe ? const Color(0xFF00FF00).withOpacity(0.3) : Colors.white.withOpacity(0.05)),
                                      ),
                                      child: Text(
                                        _sanitize(msg['message']),
                                        style: TextStyle(
                                          color: isMe ? const Color(0xFF00FF00) : Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                                      child: Text(
                                        msg['createdAt'] != null 
                                          ? TimeOfDay.fromDateTime(DateTime.parse(msg['createdAt'])).format(context)
                                          : 'Just now',
                                        style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10, fontWeight: FontWeight.bold),
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
          
          if (_showEmojiPicker)
            Container(
              height: 120,
              color: const Color(0xFF0F1221),
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      _msgController.text += _emojis[index];
                      setState(() => _showEmojiPicker = false);
                    },
                    child: Center(
                      child: Text(_emojis[index], style: const TextStyle(fontSize: 26)),
                    ),
                  );
                },
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1221),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                      color: const Color(0xFF00FF00),
                    ),
                    onPressed: () {
                      setState(() => _showEmojiPicker = !_showEmojiPicker);
                      if (_showEmojiPicker) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      onTap: () => setState(() => _showEmojiPicker = false),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF1E2235),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final text = _msgController.text.trim();
                      if (text.isNotEmpty) {
                        final chatService = Provider.of<ChatWebRTCService>(context, listen: false);
                        chatService.sendPrivateMessage(widget.userId, text);
                        
                        _msgController.clear();
                        setState(() => _showEmojiPicker = false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00FF00),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward, color: Colors.black, size: 22),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
