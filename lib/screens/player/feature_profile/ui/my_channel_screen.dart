import 'package:flutter/material.dart';
import '../../../../core/models/channel_model.dart';
import '../../../../core/models/video_model.dart';
import '../../feature_live/ui/live_stream_screen.dart'; // Import Live Screen
import '../../feature_live/ui/schedule_stream_screen.dart'; // Import Schedule Screen

class MyChannelScreen extends StatefulWidget {
  const MyChannelScreen({super.key});

  @override
  State<MyChannelScreen> createState() => _MyChannelScreenState();
}

class _MyChannelScreenState extends State<MyChannelScreen> {
  // Mocking state: set to null to see "Create Channel", or an object to see "Channel"
  Channel? _myChannel;
  List<Video> _videos = [];

  final Color _backgroundColor = const Color(0xFF0A0E1A);
  final Color _cardColor = const Color(0xFF131625);
  final Color _accentColor = const Color(0xFF00E5FF); // Cyber punk blue cyan
  final Color _primaryActionColor = const Color(0xFFD32F2F); // Red for Go Live

  @override
  void initState() {
    super.initState();
    // Simulate fetching data.
    // _myChannel = null; // Uncomment to test empty state
    _myChannel = Channel(
      id: '1',
      name: 'SoloLineAbuse',
      ownerId: 'u1',
      subscriberCount: 2350,
      avatarUrl: 'https://cdn.midjourney.com/3c70f37e-61d0-4786-b485-6184e6221544/0_3.png', // Placeholder
      bannerUrl: 'https://cdn.midjourney.com/791097fa-e165-4f35-9852-641508dbfe08/0_0.png', // Placeholder
    );
    _videos = [
      Video(
        id: 'v1',
        title: 'Valorant - Ace Clutch!',
        status: VideoStatus.approved,
        uploadDate: DateTime.now().subtract(const Duration(days: 1)),
        views: 3420,
        thumbnailUrl: 'https://cdn.midjourney.com/a4c9b369-02c3-4c9f-b3a5-502844fd7167/0_2.png', // Valorant style
      ),
      Video(
        id: 'v2',
        title: 'League of Legends - Grand Finals',
        status: VideoStatus.approved,
        uploadDate: DateTime.now().subtract(const Duration(days: 3)),
        views: 12500,
        thumbnailUrl: 'https://cdn.midjourney.com/791097fa-e165-4f35-9852-641508dbfe08/0_0.png', // LoL style
      ),
      Video(
        id: 'v3',
        title: 'CS:GO 2 - Sniper Montage',
        status: VideoStatus.approved,
        uploadDate: DateTime.now().subtract(const Duration(days: 7)),
        views: 890,
        thumbnailUrl: 'https://cdn.midjourney.com/f7d39ccf-863a-4a6c-b4db-540292723652/0_1.png', // Shooter style
      ),
      Video(
        id: 's1',
        title: 'Ranked Push to Diamond',
        status: VideoStatus.scheduled,
        uploadDate: DateTime.now(),
        scheduledDate: DateTime.now().add(const Duration(hours: 2)),
        thumbnailUrl: 'https://cdn.midjourney.com/f7d39ccf-863a-4a6c-b4db-540292723652/0_1.png',
      ),
      Video(
        id: 's2',
        title: 'Tournament Finals - Live Commentary',
        status: VideoStatus.scheduled,
        uploadDate: DateTime.now(),
        scheduledDate: DateTime.now().add(const Duration(days: 1)),
        thumbnailUrl: 'https://cdn.midjourney.com/791097fa-e165-4f35-9852-641508dbfe08/0_0.png',
      ),
    ];
  }

  void _createChannel() {
    setState(() {
      _myChannel = Channel(
        id: '2',
        name: 'New Player',
        ownerId: 'u1',
        subscriberCount: 0,
      );
    });
  }

  void _showGoLiveOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Go Live',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to start streaming.',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildOptionCard(
                      icon: Icons.videocam,
                      title: 'Stream Now',
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.pop(context); // Close bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LiveStreamScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOptionCard(
                      icon: Icons.calendar_today,
                      title: 'Schedule',
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ScheduleStreamScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_myChannel == null) {
      return _buildNoChannelView();
    }
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60), // Space for avatar
                  Center(child: _buildUserInfo()),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                  _buildStatsSection(),
                  const SizedBox(height: 32),
                  const Text(
                    'Recent Videos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildSliverVideoList(),
          const SliverToBoxAdapter(
             child: SizedBox(height: 80), // Bottom padding
          ),
        ],
      ),
    );
  }

  Widget _buildSliverVideoList() {
    final approvedVideos = _videos.where((v) => v.status == VideoStatus.approved).toList();
    if (approvedVideos.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('No videos uploaded yet.', style: TextStyle(color: Colors.grey[600])),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final video = approvedVideos[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail placeholder
                  Stack(
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.black26,
                        child: video.thumbnailUrl != null
                            ? Image.network(
                                video.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image, color: Colors.white24)),
                              )
                            : const Center(child: Icon(Icons.videogame_asset, size: 50, color: Colors.white24)),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('12:45', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${video.views} views',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(Icons.circle, size: 4, color: Colors.grey[700]),
                            ),
                            Text(
                              '2 days ago',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: approvedVideos.length,
      ),
    );
  }

  // ... (Keep existing _buildSliverAppBar, _buildUserInfo, _buildActionButtons, _buildStatsSection, _buildStatItem, _buildVerticalDivider) ...
  // Note: I will need to manually preserve them if I am replacing the whole block, or rely on context. 
  // Since I replaced a large chunk, I will re-implement them or leave them if they were outside the replaced range.
  // The replaced range ended at 299, let's assume helper methods are still there or I need to include them if they were inside.
  // Wait, I am replacing from 'initState' down to 'build'. The helpers like _buildSliverAppBar were seemingly *after* build in previous file state.
  // I need to be careful. The previous state had helper methods after `build`.

  // To be safe, I should probably output the helper methods I'm calling in `build` or ensure they are preserved.
  // Let's assume the user wants me to replace the logic. I will include the necessary helper methods for the tabs and lists.

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: _backgroundColor,
      expandedHeight: 200.0,
      pinned: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: const BackButton(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Banner Image
            Positioned.fill(
              child: _myChannel!.bannerUrl != null
                  ? Image.network(
                      _myChannel!.bannerUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: _cardColor),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_cardColor, _backgroundColor],
                        ),
                      ),
                    ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      _backgroundColor.withOpacity(0.9),
                      _backgroundColor,
                    ],
                    stops: const [0.0, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            // Avatar (Half inside/half outside handled by padding in body, but visual here)
            Container(
              transform: Matrix4.translationValues(0, 50, 0),
              child: CircleAvatar(
                radius: 54, // Border width
                backgroundColor: _backgroundColor,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: _cardColor,
                  backgroundImage: _myChannel!.avatarUrl != null
                      ? NetworkImage(_myChannel!.avatarUrl!)
                      : null,
                  child: _myChannel!.avatarUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _myChannel!.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tunisia • Pro Gamer',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showGoLiveOptions,
            icon: const Icon(Icons.live_tv, color: Colors.white),
            label: const Text('GO LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryActionColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 8,
              shadowColor: _primaryActionColor.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('Subscribers', '${_myChannel!.subscriberCount}'),
          _buildVerticalDivider(),
          _buildStatItem('Total Views', '12.5K'),
          _buildVerticalDivider(),
          _buildStatItem('Live Streams', '42'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white12,
    );
  }



  Widget _buildNoChannelView() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: Icon(Icons.videocam_outlined, size: 64, color: _accentColor),
            ),
            const SizedBox(height: 24),
            const Text(
              'Start Your Journey',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a channel to stream your games,\nupload videos, and build your community.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _createChannel,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: const Text('Create Channel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}


