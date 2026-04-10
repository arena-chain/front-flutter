import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/player/feature_friends/view_model/friends_view_model.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
<<<<<<< HEAD
import 'package:arena_chain_flutter/core/services/friends_presence_service.dart';

/// Friends / Pending / Sent / Blocked — mirrors desktop `freinds/renderer.js` tabs.
=======

>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
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
<<<<<<< HEAD
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsViewModel>().loadAllFriendData();
      context.read<FriendsPresenceNotifier>().connect();
=======
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<FriendsViewModel>();
      viewModel.loadFriends();
      viewModel.loadPendingRequests();
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  FriendUser? _otherAccepted(FriendshipModel f, String myId) {
    final req = f.requester;
    final rec = f.recipient;
    if (req is FriendUser && req.id != myId) return req;
    if (rec is FriendUser && rec.id != myId) return rec;
    if (req is String && req != myId) {
      return FriendUser(id: req, nickname: 'Player', email: '');
    }
    if (rec is String && rec != myId) {
      return FriendUser(id: rec, nickname: 'Player', email: '');
    }
    return null;
  }

  FriendUser? _requester(FriendshipModel f) {
    final req = f.requester;
    if (req is FriendUser) return req;
    if (req is String) return FriendUser(id: req, nickname: 'Player', email: '');
    return null;
  }

  FriendUser? _recipient(FriendshipModel f) {
    final rec = f.recipient;
    if (rec is FriendUser) return rec;
    if (rec is String) return FriendUser(id: rec, nickname: 'Player', email: '');
    return null;
  }

  void _openProfile(FriendUser user) {
    Navigator.pushNamed(
      context,
      AppRoutes.playerPublicProfile,
      arguments: <String, dynamic>{
        'userId': user.id,
        'nickname': user.nickname,
        'email': user.email,
        if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) 'avatar': user.avatarUrl,
      },
    ).then((_) {
      if (!mounted) return;
      context.read<FriendsViewModel>().loadAllFriendData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        foregroundColor: Colors.white,
        title: const Text('Friends'),
        actions: [
          IconButton(
            tooltip: 'Find players',
            icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF00FF00)),
=======
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
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.addFriend);
            },
          ),
        ],
<<<<<<< HEAD
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00FF00),
          labelColor: const Color(0xFF00FF00),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Friends'),
            Tab(
              child: Consumer<FriendsViewModel>(
                builder: (context, vm, _) {
                  final n = vm.pendingCount;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Pending'),
                      if (n > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4654),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$n',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const Tab(text: 'Sent'),
            const Tab(text: 'Blocked'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildPendingTab(),
          _buildSentTab(),
          _buildBlockedTab(),
=======
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

            dynamic friendData;
            if (friendship.requester is FriendUser &&
                (friendship.requester as FriendUser).id != myId) {
              friendData = friendship.requester;
            } else if (friendship.recipient is FriendUser &&
                (friendship.recipient as FriendUser).id != myId) {
              friendData = friendship.recipient;
            }

            final nickname =
                friendData is FriendUser ? friendData.nickname : 'Unknown';
            const statusText = 'Friend';

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
            icon: const Icon(Icons.message_outlined, color: Color(0xFF7A86AC)),
            onPressed: () {},
          ),
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
        ],
      ),
    );
  }
<<<<<<< HEAD

  Widget _buildFriendsTab() {
    return Consumer2<FriendsViewModel, FriendsPresenceNotifier>(
      builder: (context, vm, presence, _) {
        if (vm.isLoading && vm.friends.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)));
        }
        if (vm.friends.isEmpty) {
          return const Center(child: Text('No friends yet', style: TextStyle(color: Colors.white54)));
        }
        final myId = vm.currentUserId;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vm.friends.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final f = vm.friends[i];
            final other = _otherAccepted(f, myId);
            final nick = other?.nickname ?? 'Unknown';
            final uid = other?.id ?? '';
            final online = uid.isNotEmpty && presence.isOnline(uid);
            return _friendTile(
              nickname: nick,
              subtitle: online ? 'Online' : 'Offline',
              online: online,
              onTileTap: uid.isNotEmpty && other != null ? () => _openProfile(other) : null,
              actions: uid.isNotEmpty
                  ? [
                      TextButton(
                        onPressed: () => vm.removeFriend(uid),
                        child: const Text('Remove', style: TextStyle(color: Color(0xFFFF4654))),
                      ),
                      TextButton(
                        onPressed: () => vm.blockUser(uid),
                        child: const Text('Block', style: TextStyle(color: Color(0xFFFF4654))),
                      ),
                    ]
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildPendingTab() {
    return Consumer<FriendsViewModel>(
      builder: (context, vm, _) {
        if (vm.pendingRequests.isEmpty) {
          return const Center(child: Text('No pending requests', style: TextStyle(color: Colors.white54)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vm.pendingRequests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final f = vm.pendingRequests[i];
            final from = _requester(f);
            final nick = from?.nickname ?? 'Unknown';
            final uid = from?.id ?? '';
            return _friendTile(
              nickname: nick,
              subtitle: 'Wants to be your friend',
              onTileTap: uid.isNotEmpty && from != null ? () => _openProfile(from) : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.check, color: Color(0xFF00FF00)),
                  onPressed: () => vm.acceptRequest(f.id),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: () => vm.rejectRequest(f.id),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSentTab() {
    return Consumer<FriendsViewModel>(
      builder: (context, vm, _) {
        if (vm.sentRequests.isEmpty) {
          return const Center(child: Text('No sent requests', style: TextStyle(color: Colors.white54)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vm.sentRequests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final f = vm.sentRequests[i];
            final to = _recipient(f);
            final nick = to?.nickname ?? 'Unknown';
            final uid = to?.id ?? '';
            return _friendTile(
              nickname: nick,
              subtitle: 'Pending',
              trailing: const Text('PENDING', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w800, fontSize: 11)),
              onTileTap: uid.isNotEmpty && to != null ? () => _openProfile(to) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildBlockedTab() {
    return Consumer<FriendsViewModel>(
      builder: (context, vm, _) {
        if (vm.blocked.isEmpty) {
          return const Center(child: Text('No blocked users', style: TextStyle(color: Colors.white54)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vm.blocked.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final f = vm.blocked[i];
            final blocked = _recipient(f);
            final nick = blocked?.nickname ?? 'Unknown';
            final uid = blocked?.id ?? '';
            return _friendTile(
              nickname: nick,
              subtitle: blocked?.email ?? '',
              onTileTap: uid.isNotEmpty && blocked != null ? () => _openProfile(blocked) : null,
              actions: uid.isNotEmpty
                  ? [
                      TextButton(
                        onPressed: () => vm.unblockUser(uid),
                        child: const Text('Unblock', style: TextStyle(color: Colors.white70)),
                      ),
                    ]
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _friendTile({
    required String nickname,
    required String subtitle,
    VoidCallback? onTileTap,
    List<Widget>? actions,
    Widget? trailing,
    bool online = false,
  }) {
    return Material(
      color: const Color(0xFF131625),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTileTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1A1F36),
                    child: Text(
                      nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (online)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF00),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF131625), width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (actions != null) ...actions,
            ],
          ),
        ),
      ),
    );
  }
=======
>>>>>>> 7f48c8d910f42a96c7f3da11bcd36e3921c73056
}
