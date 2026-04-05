import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/stream_api.dart';
import 'package:arena_chain_flutter/core/models/stream_model.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:intl/intl.dart';

class ScheduledStreamsScreen extends StatefulWidget {
  const ScheduledStreamsScreen({super.key});

  @override
  State<ScheduledStreamsScreen> createState() => _ScheduledStreamsScreenState();
}

class _ScheduledStreamsScreenState extends State<ScheduledStreamsScreen> {
  final StreamApi _streamApi = StreamApi();
  List<StreamModel> _streams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await _streamApi.getAllStreams();
    setState(() {
      _streams = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C08),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ARENA LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF00FF00),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSection('EN DIRECT', _streams.where((s) => s.isLive).toList()),
                  const SizedBox(height: 32),
                  _buildSection('PROGRAMMÉ', _streams.where((s) => !s.isLive).toList()),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<StreamModel> streams) {
    if (streams.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 4),
        ),
        const SizedBox(height: 16),
        ...streams.map((stream) => _buildStreamCard(stream)),
      ],
    );
  }

  Widget _buildStreamCard(StreamModel stream) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.liveStream, arguments: stream.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF16181D).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Container(
                      color: Colors.black,
                      width: double.infinity,
                      child: stream.thumbnailUrl != null 
                        ? Image.network(stream.thumbnailUrl!, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.5))
                        : const Icon(Icons.videocam_outlined, color: Colors.white10, size: 48),
                    ),
                    if (stream.isLive)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0000),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stream.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stream.channel?.name ?? 'Studio',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (!stream.isLive && stream.scheduledStartTime != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('START', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
                          Text(
                            DateFormat('HH:mm').format(stream.scheduledStartTime!),
                            style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
