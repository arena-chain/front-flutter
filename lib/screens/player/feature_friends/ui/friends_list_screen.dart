import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/player/feature_friends/view_model/friends_view_model.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_messages/ui/live_room_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<FriendsViewModel>();
      viewModel.loadFriends();
      viewModel.loadPendingRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00FF00),
          labelColor: const Color(0xFF00FF00),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsList(),
              _buildRequestsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.group,
                  color: Color(0xFF00FF00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'My Friends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF00FF00)),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.addFriend);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return Consumer<FriendsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.friends.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00FF00)),
          );
        }

        if (viewModel.friends.isEmpty) {
          return const Center(
            child: Text(
              'No friends yet',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: viewModel.friends.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final friendship = viewModel.friends[index];
            final myId = viewModel.currentUserId;
            final friendUser = friendship.counterpartFor(myId);
            final nickname = friendUser?.nickname ?? 'Unknown';
            const statusText = 'Friend';

            return _buildFriendItem(
              context,
              nickname: nickname,
              statusText: statusText,
              friendUser: friendUser,
              myUserId: myId,
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return Consumer<FriendsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.pendingRequests.isEmpty) {
          return const Center(
            child: Text(
              'No pending requests',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: viewModel.pendingRequests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final friendship = viewModel.pendingRequests[index];
            final requester = friendship.requester;
            final nickname =
                requester is FriendUser ? requester.nickname : 'Unknown';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1221),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A1F36)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F36),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber),
                    ),
                    child: const Icon(
                      Icons.question_mark,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Wants to be your friend',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF00FF00)),
                    onPressed: () {
                      viewModel.acceptRequest(friendship.id);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      viewModel.rejectRequest(friendship.id);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openFriendChat(
    BuildContext context, {
    required String myUserId,
    required FriendUser? friend,
    required String title,
  }) {
    final friendId = friend?.id.trim() ?? '';
    if (friendId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LiveRoomScreen(
          channelId: LiveRoomScreen.directMessageChannelId(myUserId, friendId),
          title: title,
        ),
      ),
    );
  }

  Widget _buildFriendItem(
    BuildContext context, {
    required String nickname,
    required String statusText,
    required FriendUser? friendUser,
    required String myUserId,
  }) {
    void open() => _openFriendChat(
          context,
          myUserId: myUserId,
          friend: friendUser,
          title: nickname,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1221),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A1F36)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F36),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00FF00).withOpacity(0.5),
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.message_outlined,
                    color: Color(0xFF7A86AC)),
                onPressed: open,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
