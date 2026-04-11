import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:arena_chain_flutter/screens/player/feature_live/viewmodel/live_stream_viewmodel.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:intl/intl.dart';

class LiveStreamScreen extends StatefulWidget {
  final String streamId;

  const LiveStreamScreen({super.key, required this.streamId});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<String> _reactionChoices = ['👏', '🔥', '❤️', '🎉', '😂'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthViewModel>(context, listen: false);
      Provider.of<LiveStreamViewModel>(context, listen: false)
          .loadStream(widget.streamId, token: auth.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LiveStreamViewModel(),
      child: Consumer<LiveStreamViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF060709),
              body: Center(child: CircularProgressIndicator(color: Color(0xFF00FF87))),
            );
          }

          final stream = vm.stream;
          if (stream == null) {
            return const Scaffold(
              backgroundColor: Color(0xFF060709),
              body: Center(child: Text('Stream non trouvé', style: TextStyle(color: Colors.white))),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFF060709),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                stream.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: vm.isLive ? const Color(0xFFFF0000).withValues(alpha: 0.1) : Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: vm.isLive ? const Color(0xFFFF0000) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (vm.isLive)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF0000),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (vm.isLive) const SizedBox(width: 8),
                      Text(
                        vm.isLive ? 'EN DIRECT' : 'HORS LIGNE',
                        style: TextStyle(
                          color: vm.isLive ? const Color(0xFFFF0000) : Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // Video Player Area
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.black,
                    child: vm.isLive
                        ? RTCVideoView(vm.remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain)
                        : _buildOfflinePlaceholder(stream),
                  ),
                ),
                
                // Content Area
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B0C0F),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Stream Info & Reactions
                        _buildStreamHeader(stream, vm),
                        
                        // Chat Area
                        Expanded(child: _buildChatArea(vm)),
                        
                        // Input Area
                        _buildInputArea(vm),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfflinePlaceholder(dynamic stream) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            stream.scheduledStartTime != null
                ? 'Commence le ${DateFormat('dd/MM HH:mm').format(stream.scheduledStartTime!)}'
                : 'Aucun flux actif',
            style: const TextStyle(color: Colors.white30, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamHeader(dynamic stream, LiveStreamViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF00FF87).withValues(alpha: 0.1),
                backgroundImage: stream.channel?.avatarUrl != null 
                  ? NetworkImage(stream.channel!.avatarUrl!) 
                  : null,
                child: stream.channel?.avatarUrl == null 
                  ? const Icon(Icons.person, color: Color(0xFF00FF87)) 
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.channel?.name ?? 'Studio',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${stream.viewerCount} Spectateurs',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF87),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('SUIVRE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _reactionChoices.map((emoji) => InkWell(
              onTap: () => vm.sendReaction(emoji),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(LiveStreamViewModel vm) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: vm.chatMessages.length,
      itemBuilder: (context, index) {
        final msg = vm.chatMessages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${msg['senderNickname']}: ',
                  style: const TextStyle(
                    color: Color(0xFF00FF87),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: msg['message'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(LiveStreamViewModel vm) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF060709),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Envoyer un message...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _send(vm),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _send(vm),
            icon: const Icon(Icons.send_rounded, color: Color(0xFF00FF87)),
          ),
        ],
      ),
    );
  }

  void _send(LiveStreamViewModel vm) {
    if (_chatController.text.trim().isNotEmpty) {
      vm.sendMessage(_chatController.text.trim());
      _chatController.clear();
    }
  }
}
