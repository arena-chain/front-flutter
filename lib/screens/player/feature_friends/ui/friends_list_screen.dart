import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/player/feature_friends/view_model/friends_view_model.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load data after first frame
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)));
        }

        if (viewModel.friends.isEmpty) {
          return const Center(child: Text('No friends yet', style: TextStyle(color: Colors.grey)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: viewModel.friends.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final friendship = viewModel.friends[index];
            // Determine which user is the friend.
            // Since we know currentUserId, we can filter, but ViewModel returns FriendshipModel.
            // FriendshipModel has requester and recipient which can be Map or String.
            // Assuming the API returns populated objects as per our earlier reading.
            // However, our model parsing logic: `requester` and `recipient` are dynamic.
            // We need a way to get the friend user safely.
            
            // For now, let's assume we can get friend details.
            // We need to know who "I" am to show the "Other" person.
            final myId = viewModel.currentUserId;
            
            // Helper to get friend data manually (since model helper was stubbed)
            dynamic friendData;
            // requester can be String (ID) or FriendUser object
            if (friendship.requester is FriendUser && (friendship.requester as FriendUser).id != myId) {
               friendData = friendship.requester;
            } else if (friendship.recipient is FriendUser && (friendship.recipient as FriendUser).id != myId) {
               friendData = friendship.recipient;
            } 
            
            // Fallback if we can't identify
            final nickname = friendData is FriendUser ? friendData.nickname : 'Unknown';
            final statusText = 'Friend'; // Could be online status later

            return _buildFriendItem(nickname, statusText);
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return Consumer<FriendsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.pendingRequests.isEmpty) {
          return const Center(child: Text('No pending requests', style: TextStyle(color: Colors.grey)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: viewModel.pendingRequests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
             final friendship = viewModel.pendingRequests[index];
             final requester = friendship.requester;
             final nickname = requester is FriendUser ? requester.nickname : 'Unknown';

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
                    child: const Icon(Icons.question_mark, color: Colors.amber, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildFriendItem(String nickname, String statusText) {
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F36),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.5)),
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
            icon: const Icon(Icons.message_outlined, color: Color(0xFF7A86AC)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
