import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/player/feature_friends/view_model/friends_view_model.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';

/// Search players: **friends first**, then others. Non-friends get **Follow** (friend request).
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsViewModel>().loadAllFriendData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<FriendsViewModel>().searchUsers(query);
    });
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
      final vm = context.read<FriendsViewModel>();
      vm.loadAllFriendData();
      final q = _searchController.text.trim();
      if (q.length >= 2) {
        vm.searchUsers(q);
      }
    });
  }

  Widget _avatar(FriendUser user, {double radius = 22}) {
    final url = user.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackAvatar(user, radius),
        ),
      );
    }
    return _fallbackAvatar(user, radius);
  }

  Widget _fallbackAvatar(FriendUser user, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF00FF00).withValues(alpha: 0.2),
      child: Text(
        user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
        style: const TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _trailing(BuildContext context, FriendsViewModel vm, FriendUser user) {
    final rel = vm.relationToSearchUser(user.id);

    if (rel == FriendSearchRelation.friends) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text(
          'Following',
          style: TextStyle(
            color: const Color(0xFF00FF00).withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (rel == FriendSearchRelation.pendingIncoming) {
      final fid = vm.incomingFriendshipIdForUser(user.id);
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF22d3ee),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: fid == null
              ? null
              : () async {
                  try {
                    await vm.acceptRequest(fid);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You are now friends')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                },
          child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
    }

    if (rel == FriendSearchRelation.pendingOutgoing) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          'Requested',
          style: TextStyle(color: Colors.amber.withValues(alpha: 0.95), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilledButton(
        onPressed: () async {
          try {
            await vm.sendFriendRequest(user.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request sent')),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e')),
            );
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF00FF00).withValues(alpha: 0.2),
          foregroundColor: const Color(0xFF00FF00),
          side: const BorderSide(color: Color(0xFF00FF00)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(72, 36),
        ),
        child: const Text('Follow', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0C08),
        leading: const BackButton(color: Colors.white),
        title: const Text('Find players', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by nickname (min. 2 characters)',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00FF00)),
                filled: true,
                fillColor: const Color(0xFF1A1F36),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00FF00)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<FriendsViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isSearchLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)));
                  }

                  if (viewModel.error != null && viewModel.searchResults.isEmpty) {
                    return Center(
                      child: Text(viewModel.error!, style: const TextStyle(color: Colors.redAccent)),
                    );
                  }

                  final q = _searchController.text.trim();
                  if (q.length < 2) {
                    return Center(
                      child: Text(
                        'Type at least 2 characters to search',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    );
                  }

                  final rows = viewModel.sortedSearchResults;
                  if (rows.isEmpty) {
                    return const Center(
                      child: Text('No users found', style: TextStyle(color: Colors.white70)),
                    );
                  }

                  return ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = rows[index];
                      return Material(
                        color: const Color(0xFF1A1F36),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openProfile(user),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                _avatar(user),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.nickname,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _trailing(context, viewModel, user),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
