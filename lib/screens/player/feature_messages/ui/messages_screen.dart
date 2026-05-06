import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:arena_chain_flutter/screens/player/feature_friends/view_model/friends_view_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_messages/ui/live_room_screen.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';

/// Player DMs / threads — UI shell until a messages API is wired.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    this.embeddedInPlayerShell = false,
  });

  /// Inside [PlayerHomeScreen] tabs: menu opens drawer; no inner [Scaffold] so parent nav stays correct.
  final bool embeddedInPlayerShell;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {

  static const Color _background = Color(0xFF000000);
  static const Color _surface = Color(0xFF0A0A0A);
  static const Color _card = Color(0xFF1A1C23);
  static const Color _neon = Color(0xFF39FF14);
  late TabController _tabController;
  static const _tabTitles = ['Chats', 'Friends', 'Received', 'Sent'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<FriendsViewModel>();
      if (vm.friends.isEmpty && !vm.isLoading) vm.loadFriends();
      vm.loadPendingRequests();
      vm.loadSentRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        Consumer<FriendsViewModel>(
          builder: (context, vm, _) => _tabSlider(vm),
        ),
        Expanded(
          child: Consumer<FriendsViewModel>(
            builder: (context, vm, _) => TabBarView(
              controller: _tabController,
              children: [
                _tabBody(bottomInset: bottomInset, children: _buildChatsTab(context)),
                _tabBody(
                    bottomInset: bottomInset,
                    children: _buildFriendsTab(context, vm)),
                _tabBody(bottomInset: bottomInset, children: _buildReceivedTab(vm)),
                _tabBody(bottomInset: bottomInset, children: _buildSentTab(vm)),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.embeddedInPlayerShell) {
      return ColoredBox(color: _background, child: body);
    }

    return Scaffold(
      backgroundColor: _background,
      body: body,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 10),
          child: Row(
            children: [
              _buildLeading(context),
              Expanded(
                child: Text(
                  'Messages',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    shadows: [
                      Shadow(color: _neon.withValues(alpha: 0.2), blurRadius: 10),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend),
                icon: Icon(Icons.person_add_alt_rounded, color: _neon.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        border: Border.all(color: _neon.withValues(alpha: 0.22)),
      ),
      child: IconButton(
        icon: Icon(
          widget.embeddedInPlayerShell ? Icons.menu_rounded : Icons.arrow_back_rounded,
          color: _neon.withValues(alpha: 0.92),
        ),
        onPressed: () {
          if (widget.embeddedInPlayerShell) {
            Scaffold.maybeOf(context)?.openDrawer();
          } else {
            Navigator.maybePop(context);
          }
        },
      ),
    );
  }

  Widget _threadTile({
    required String title,
    required String preview,
    required String time,
    required bool unread,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unread ? _neon.withValues(alpha: 0.4) : _neon.withValues(alpha: 0.14),
            ),
            boxShadow: unread
                ? [
                    BoxShadow(
                      color: _neon.withValues(alpha: 0.06),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _neon.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.forum_rounded,
                  color: _neon.withValues(alpha: 0.85),
                  size: 22,
                ),
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
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: unread ? 0.55 : 0.42),
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _neon,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _neon.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabSlider(FriendsViewModel vm) {
    final counts = [
      2, // demo chat rows for now
      vm.friends.length,
      vm.pendingRequests.length,
      vm.sentRequests.length,
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _neon.withValues(alpha: 0.08)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: _neon.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _neon.withValues(alpha: 0.35)),
        ),
        labelColor: _neon,
        unselectedLabelColor: Colors.white70,
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        tabs: List.generate(_tabTitles.length, (i) {
          return Tab(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _tabTitles[i],
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${counts[i]}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildChatsTab(BuildContext context) => [
        _helperText('Direct messages and team threads will appear here.'),
        const SizedBox(height: 12),
        _threadTile(
          title: 'Team chat',
          preview: 'Match tonight at 9 — confirm roster',
          time: '2h',
          unread: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LiveRoomScreen(
                channelId: 'team-chat',
                title: 'Team chat',
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _threadTile(
          title: 'Arena-Chain Support',
          preview: 'Thanks for your feedback!',
          time: '1d',
          unread: false,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LiveRoomScreen(
                channelId: 'arena-support',
                title: 'Arena-Chain Support',
              ),
            ),
          ),
        ),
      ];

  List<Widget> _buildFriendsTab(BuildContext context, FriendsViewModel vm) {
    if (vm.friends.isEmpty) return [_emptyText('No friends yet')];
    return vm.friends
        .map((f) {
          final counterpart = f.counterpartFor(vm.currentUserId);
          final name = _friendLabelFromFriendship(f, vm.currentUserId);
          final friendId = counterpart?.id.trim() ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _relationTile(
              name: name,
              status: 'Friend',
              onTap: friendId.isEmpty
                  ? null
                  : () => Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => LiveRoomScreen(
                            channelId: LiveRoomScreen.directMessageChannelId(
                              vm.currentUserId,
                              friendId,
                            ),
                            title: name,
                          ),
                        ),
                      ),
            ),
          );
        })
        .toList();
  }

  List<Widget> _buildReceivedTab(FriendsViewModel vm) {
    if (vm.pendingRequests.isEmpty) return [_emptyText('No received requests')];
    return vm.pendingRequests
        .map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _requestTile(
                name: _friendLabelFromFriendship(r, vm.currentUserId),
                subtitle: 'Sent you a request',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: _neon),
                      onPressed: () => vm.acceptRequest(r.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      onPressed: () => vm.rejectRequest(r.id),
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }

  List<Widget> _buildSentTab(FriendsViewModel vm) {
    if (vm.sentRequests.isEmpty) return [_emptyText('No sent requests')];
    return vm.sentRequests
        .map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _requestTile(
                name: _friendLabelFromFriendship(r, vm.currentUserId),
                subtitle: 'Request pending',
                trailing: Text(
                  'Sent',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                ),
              ),
            ))
        .toList();
  }

  Widget _tabBody({required double bottomInset, required List<Widget> children}) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset),
      children: children,
    );
  }

  Widget _helperText(String text) => Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.48),
          fontSize: 14,
          height: 1.35,
        ),
      );

  Widget _emptyText(String text) => Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Center(
          child: Text(
            text,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      );

  Widget _relationTile({
    required String name,
    required String status,
    VoidCallback? onTap,
  }) {
    final child = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _neon.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _surface,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: _neon, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                Text(status,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }

  Widget _requestTile({
    required String name,
    required String subtitle,
    required Widget trailing,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _neon.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _surface,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: _neon, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      );

  String _friendLabelFromFriendship(FriendshipModel f, String myUserId) {
    return f.counterpartFor(myUserId)?.nickname ?? 'Unknown';
  }
}
