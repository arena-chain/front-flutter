import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/core/api/player_social_api.dart';
import 'package:arena_chain_flutter/core/repositories/feature_friends/friends_repository.dart';
import 'package:arena_chain_flutter/screens/player/feature_friends/view_model/friends_view_model.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friendship_model.dart';

/// Instagram-style public profile + desktop `profile/renderer.js` stats (ELO, tier, ranks, Riot, PRO).
class PlayerPublicProfileScreen extends StatefulWidget {
  const PlayerPublicProfileScreen({
    super.key,
    required this.targetUserId,
    this.prefillNickname,
    this.prefillEmail,
    this.prefillAvatarUrl,
  });

  final String targetUserId;
  final String? prefillNickname;
  final String? prefillEmail;
  final String? prefillAvatarUrl;

  @override
  State<PlayerPublicProfileScreen> createState() => _PlayerPublicProfileScreenState();
}

class _PlayerPublicProfileScreenState extends State<PlayerPublicProfileScreen> {
  final PlayerSocialApi _socialApi = PlayerSocialApi();
  final FriendsRepository _friendsRepo = FriendsRepository();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _playerJson;
  List<dynamic> _ranks = [];
  List<FriendshipModel> _theirFriends = [];
  String? _friendshipStatus;
  bool _actionLoading = false;

  bool get _isSelf {
    final me = context.read<AuthViewModel>().currentUser?.id;
    return me != null && me == widget.targetUserId;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// [silent]: refresh lists/stats without full-screen spinner (after follow/accept/unfollow).
  /// Fetches player / ranks / friends / status independently so one failure does not block the rest.
  Future<void> _load({bool silent = false}) async {
    final me = context.read<AuthViewModel>().currentUser?.id;
    final vm = context.read<FriendsViewModel>();
    final targetId = widget.targetUserId.trim();

    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() => _error = null);
    }

    Object? playerError;
    Map<String, dynamic>? player;
    try {
      player = await _socialApi.getPlayerByUserId(targetId);
    } catch (e) {
      playerError = e;
    }

    List<FriendshipModel> theirFriends = _theirFriends;
    try {
      theirFriends = await _friendsRepo.getFriends(targetId);
    } catch (_) {}

    List<dynamic> ranks = _ranks;
    try {
      ranks = await _socialApi.getRanksForUser(targetId);
    } catch (_) {
      ranks = [];
    }

    String? status;
    if (me != null && me != targetId) {
      try {
        status = await _socialApi.getFriendshipStatus(me, targetId);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      if (player != null) {
        _playerJson = player;
      }
      _ranks = ranks;
      _theirFriends = theirFriends;
      _mergeFriendshipWithVm(vm, status);
      if (!silent) {
        _loading = false;
        if (_playerJson == null && playerError != null) {
          _error = playerError.toString();
        } else {
          _error = null;
        }
      }
    });
  }

  /// Prefer [FriendsViewModel] lists over a stale `/friendship/status` response right after accept.
  void _mergeFriendshipWithVm(FriendsViewModel vm, String? apiStatus) {
    final rel = vm.relationToSearchUser(widget.targetUserId.trim());
    if (apiStatus == 'ACCEPTED') {
      _friendshipStatus = 'ACCEPTED';
      return;
    }
    if (rel == FriendSearchRelation.friends) {
      _friendshipStatus = 'ACCEPTED';
    } else if (rel == FriendSearchRelation.pendingIncoming || rel == FriendSearchRelation.pendingOutgoing) {
      _friendshipStatus = 'PENDING';
    } else if (apiStatus != null) {
      _friendshipStatus = apiStatus;
    }
  }

  Map<String, dynamic> _userInfo() {
    final raw = _playerJson?['userId'];
    if (raw is Map<String, dynamic>) return raw;
    return {};
  }

  String _nickname() {
    final u = _userInfo();
    final n = (u['nickname'] ?? widget.prefillNickname).toString();
    if (n.isNotEmpty) return n;
    return 'Player';
  }

  String _email() {
    final u = _userInfo();
    final e = (u['email'] ?? widget.prefillEmail).toString();
    return e;
  }

  String? _avatarUrl() {
    final u = _userInfo();
    final a = u['avatar']?.toString();
    if (a != null && a.isNotEmpty) return a;
    return widget.prefillAvatarUrl;
  }

  String _region() {
    final u = _userInfo();
    return (u['region'] ?? 'EU').toString();
  }

  int _elo() => (_playerJson?['elo'] as num?)?.toInt() ?? 1000;
  String _tier() => (_playerJson?['rank'] ?? 'Unranked').toString();
  bool _isPro() => _playerJson?['isPro'] == true;
  bool _isVerified() => _playerJson?['isVerified'] == true;
  String _riotStatus() => (_playerJson?['riotLinkStatus'] ?? 'unlinked').toString();
  String? _riotRiotLine() {
    final g = _playerJson?['riotGameName']?.toString();
    final t = _playerJson?['riotTagLine']?.toString();
    if (g == null || g.isEmpty) return null;
    return '$g${t != null && t.isNotEmpty ? '#$t' : ''}';
  }

  Future<void> _follow() async {
    final me = context.read<AuthViewModel>().currentUser?.id;
    if (me == null) return;
    setState(() => _actionLoading = true);
    try {
      await _friendsRepo.sendFriendRequest(me, widget.targetUserId);
      if (!mounted) return;
      final st = await _socialApi.getFriendshipStatus(me, widget.targetUserId);
      setState(() {
        _friendshipStatus = st ?? 'PENDING';
        _actionLoading = false;
      });
      if (!mounted) return;
      await context.read<FriendsViewModel>().loadAllFriendData();
      if (!mounted) return;
      await _load(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _unfollow() async {
    final me = context.read<AuthViewModel>().currentUser?.id;
    if (me == null) return;
    setState(() => _actionLoading = true);
    try {
      await _friendsRepo.removeFriend(me, widget.targetUserId);
      if (!mounted) return;
      setState(() {
        _friendshipStatus = 'NONE';
        _actionLoading = false;
      });
      await context.read<FriendsViewModel>().loadAllFriendData();
      if (!mounted) return;
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _acceptIncoming() async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    final vm = context.read<FriendsViewModel>();
    var fid = vm.incomingFriendshipIdForUser(widget.targetUserId);
    if (fid == null || fid.isEmpty) {
      await vm.loadAllFriendData();
      fid = vm.incomingFriendshipIdForUser(widget.targetUserId);
    }
    if (fid == null || fid.isEmpty) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find this friend request. Open Friends and pull to refresh, then try again.')),
      );
      return;
    }
    try {
      await vm.acceptRequest(fid);
      if (!mounted) return;
      setState(() {
        _friendshipStatus = 'ACCEPTED';
        _actionLoading = false;
      });
      await _load(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are now friends')));
    } catch (e) {
      final es = e.toString();
      final alreadyHandled = es.contains('no longer pending') || es.contains('No longer pending');
      if (alreadyHandled) {
        try {
          await vm.loadAllFriendData();
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _friendshipStatus = 'ACCEPTED';
          _actionLoading = false;
        });
        await _load(silent: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are now friends')));
        return;
      }
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  List<FriendUser> _friendUsersPreview() {
    final uid = widget.targetUserId.trim();
    final out = <FriendUser>[];
    for (final f in _theirFriends) {
      final req = f.requester;
      final rec = f.recipient;
      if (req is FriendUser && !FriendsViewModel.sameUserId(req.id, uid)) {
        out.add(req);
      } else if (rec is FriendUser && !FriendsViewModel.sameUserId(rec.id, uid)) {
        out.add(rec);
      }
    }
    return out.take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        foregroundColor: Colors.white,
        title: const Text('Profile'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : Consumer<FriendsViewModel>(
                  builder: (context, vm, _) {
                    return RefreshIndicator(
                      color: const Color(0xFF00FF00),
                      onRefresh: () async {
                        await vm.loadAllFriendData();
                        await _load();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAvatar(),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _nickname(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        if (_isPro())
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFD700),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'PRO',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF1a0a00),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _email(),
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.white24),
                                          ),
                                          child: Text(
                                            _tier().toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _region(),
                                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_riotRiotLine() != null && _riotStatus() == 'verified') ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF4654).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFFFF4654).withValues(alpha: 0.35)),
                                            ),
                                            child: const Text(
                                              'RIOT LINKED',
                                              style: TextStyle(
                                                color: Color(0xFFFF4654),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _riotRiotLine()!,
                                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _statCell('${_theirFriends.length}', 'Friends'),
                              _statCell('${_ranks.length}', 'Ranked'),
                              _statCell('${_elo()}', 'ELO'),
                              _statCell(
                                _isPro() ? 'PRO' : (_isVerified() ? 'VERIFIED' : 'STANDARD'),
                                'Account',
                              ),
                            ],
                          ),
                        ),
                        if (!_isSelf) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildRelationshipActions(vm),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text(
                                'Friends',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_theirFriends.length}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Builder(
                          builder: (context) {
                            final preview = _friendUsersPreview();
                            if (preview.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'No friends to show',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                                ),
                              );
                            }
                            return SizedBox(
                              height: 72,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: preview.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 10),
                                itemBuilder: (context, i) {
                                  final u = preview[i];
                                  return Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: const Color(0xFF1A1F36),
                                        backgroundImage: u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                                            ? NetworkImage(u.avatarUrl!)
                                            : null,
                                        child: u.avatarUrl == null || u.avatarUrl!.isEmpty
                                            ? Text(
                                                u.nickname.isNotEmpty ? u.nickname[0].toUpperCase() : '?',
                                                style: const TextStyle(
                                                  color: Color(0xFF00FF00),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 64,
                                        child: Text(
                                          u.nickname,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'GAME RANKINGS',
                              style: TextStyle(
                                color: Color(0xFF00FF00),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_ranks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF131625),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF1A1F36)),
                              ),
                              child: Center(
                                child: Text(
                                  'No game rankings yet',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                                ),
                              ),
                            ),
                          )
                        else
                          ..._ranks.map((raw) {
                            final m = raw as Map<String, dynamic>;
                            final gameName = _gameName(m);
                            final tier = (m['tier'] ?? '—').toString();
                            final div = m['division'];
                            final elo = (m['elo'] ?? 0).toString();
                            final wins = (m['wins'] as num?)?.toInt() ?? 0;
                            final losses = (m['losses'] as num?)?.toInt() ?? 0;
                            final total = (m['totalMatches'] as num?)?.toInt() ?? 0;
                            final winRate = total > 0 ? ((wins / total) * 100).round() : 0;
                            final streak = (m['currentStreak'] as num?)?.toInt() ?? 0;
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131625),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF1A1F36)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            gameName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          elo,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '$tier${div != null ? ' · DIV $div' : ''}',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _miniStat('$wins', 'WINS', const Color(0xFF00FF00)),
                                        _miniStat('$losses', 'LOSSES', const Color(0xFFFF4654)),
                                        _miniStat('$winRate%', 'WIN RATE', Colors.white),
                                        _miniStat(
                                          streak > 0 ? '+$streak' : '$streak',
                                          'STREAK',
                                          streak >= 0 ? const Color(0xFF00FF00) : const Color(0xFFFF4654),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                    );
                  },
                ),
    );
  }

  String _gameName(Map<String, dynamic> m) {
    final g = m['game'];
    if (g is Map) {
      return (g['title'] ?? g['name'] ?? 'Game').toString();
    }
    return 'Game';
  }

  Widget _miniStat(String v, String label, Color c) {
    return Column(
      children: [
        Text(v, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 14)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9)),
      ],
    );
  }

  Widget _statCell(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final url = _avatarUrl();
    final size = 88.0;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackAvatar(size),
        ),
      );
    }
    return _fallbackAvatar(size);
  }

  Widget _fallbackAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00FF00).withValues(alpha: 0.35), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        _nickname().isNotEmpty ? _nickname()[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Color(0xFF00FF00),
          fontSize: 36,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildRelationshipActions(FriendsViewModel vm) {
    final st = _friendshipStatus ?? 'NONE';
    final rel = vm.relationToSearchUser(widget.targetUserId);
    final incomingFid = vm.incomingFriendshipIdForUser(widget.targetUserId);

    if (_actionLoading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FF00)),
        ),
      );
    }

    // VM friend lists update as soon as accept completes — avoids stale PENDING vs wrong "Request pending".
    if (rel == FriendSearchRelation.friends || st == 'ACCEPTED') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _unfollow,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Unfollow', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      );
    }

    if (rel == FriendSearchRelation.pendingIncoming ||
        (st == 'PENDING' && incomingFid != null && incomingFid.isNotEmpty)) {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _acceptIncoming,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00FF00).withValues(alpha: 0.25),
                foregroundColor: const Color(0xFF00FF00),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Accept request', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      );
    }

    if (rel == FriendSearchRelation.pendingOutgoing || st == 'PENDING') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
          ),
          child: const Text(
            'Request pending',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: _follow,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00FF00).withValues(alpha: 0.22),
              foregroundColor: const Color(0xFF00FF00),
              side: const BorderSide(color: Color(0xFF00FF00)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Follow', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}
