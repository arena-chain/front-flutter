import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/services/rift_service.dart';

const _kSheetBg = Color(0xFF0D1117);
const _kGold = Color(0xFFC89B3C);

const _kAvailChat = Color(0xFF44B37B);
const _kAvailAway = Color(0xFFC89B3C);
const _kAvailDnd = Color(0xFFC84B4B);
const _kAvailOffline = Color(0xFF6B7280);
const _kAvailMobile = Color(0xFF3B82F6);

/// Opens Mimic-style invite friends bottom sheet (leader only from lobby).
Future<void> showInviteFriendsBottomSheet(
  BuildContext context, {
  required RiftService riftService,
  required List<dynamic> invitations,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _InviteFriendsModal(
      riftService: riftService,
      invitations: invitations,
    ),
  );
}

class _InviteFriendsModal extends StatelessWidget {
  final RiftService riftService;
  final List<dynamic> invitations;

  const _InviteFriendsModal({
    required this.riftService,
    required this.invitations,
  });

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final height = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: height * 0.9,
        child: DraggableScrollableSheet(
          initialChildSize: 1,
          minChildSize: 0.55,
          maxChildSize: 1,
          expand: true,
          builder: (context, scrollController) {
            return _InviteFriendsBody(
              riftService: riftService,
              scrollController: scrollController,
              initialInvitations: invitations,
            );
          },
        ),
      ),
    );
  }
}

class _InviteFriendsBody extends StatefulWidget {
  final RiftService riftService;
  final ScrollController scrollController;
  final List<dynamic> initialInvitations;

  const _InviteFriendsBody({
    required this.riftService,
    required this.scrollController,
    required this.initialInvitations,
  });

  @override
  State<_InviteFriendsBody> createState() => _InviteFriendsBodyState();
}

class _LcuFriend {
  final int summonerId;
  final String name;
  final String gameName;
  final String availability;

  _LcuFriend({
    required this.summonerId,
    required this.name,
    required this.gameName,
    required this.availability,
  });

  String get displayName {
    final g = gameName.trim();
    if (g.isNotEmpty) return g;
    return name.trim().isNotEmpty ? name.trim() : '#$summonerId';
  }

  static _LcuFriend? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final sid = m['summonerId'];
    int? id;
    if (sid is int) {
      id = sid;
    } else if (sid is num) {
      id = sid.toInt();
    }
    if (id == null || id <= 0) return null;
    return _LcuFriend(
      summonerId: id,
      name: m['name']?.toString() ?? '',
      gameName: m['gameName']?.toString() ?? '',
      availability: (m['availability']?.toString() ?? 'offline').toLowerCase(),
    );
  }

  int get _sortGroup {
    switch (availability) {
      case 'chat':
        return 0;
      case 'away':
        return 1;
      case 'dnd':
        return 2;
      case 'mobile':
        return 3;
      case 'offline':
        return 4;
      default:
        return 5;
    }
  }

  static int compare(_LcuFriend a, _LcuFriend b) {
    final c = a._sortGroup.compareTo(b._sortGroup);
    if (c != 0) return c;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  }
}

class _InviteFriendsBodyState extends State<_InviteFriendsBody> {
  StreamSubscription<LcuEvent>? _sub;
  Timer? _friendsWaitTimer;
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _loading = true;
  bool _receivedFriendsPush = false;
  String? _loadError;
  /// Per-friend LCU pushes keyed by full path `/lol-chat/v1/friends/{id@realm}`.
  final Map<String, Map<String, dynamic>> _friendsMap = {};
  List<_LcuFriend> _friends = [];
  int _filterTab = 0;
  final Set<int> _optimisticInvited = {};

  static bool _isPerFriendUri(String uri) =>
      uri.startsWith('/lol-chat/v1/friends/');

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _searchFocus.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadFriends();
    });
  }

  void _cancelFriendsWaitTimer() {
    _friendsWaitTimer?.cancel();
    _friendsWaitTimer = null;
  }

  void _startFriendsWaitWindow() {
    _cancelFriendsWaitTimer();
    _friendsWaitTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_friendsMap.isEmpty) {
        setState(() {
          _loading = false;
          _loadError =
              'Friends list unavailable — make sure League is running';
        });
      }
    });
  }

  void _loadFriends() {
    final rift = widget.riftService;
    // ignore: avoid_print
    print('[Invite] Loading friends, rift status=${rift.status}');
    if (rift.status != RiftConnectionStatus.connected) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Not connected to League';
        });
      }
      return;
    }
    // ignore: avoid_print
    print('[Invite] Listening for LCU pushes /lol-chat/v1/friends/<id> (no GET)');
    _sub ??= rift.lcuEvents.listen(_onLcuEvent);
    _startFriendsWaitWindow();
  }

  void _onRetryFriends() {
    _cancelFriendsWaitTimer();
    final rift = widget.riftService;
    if (rift.status != RiftConnectionStatus.connected) {
      setState(() {
        _loadError = 'Not connected. Reconnect from the pairing screen.';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loadError = null;
      _loading = true;
      _receivedFriendsPush = false;
      _friendsMap.clear();
      _friends = [];
    });
    _startFriendsWaitWindow();
  }

  List<_LcuFriend> _friendsFromMap() {
    final parsed = <_LcuFriend>[];
    for (final m in _friendsMap.values) {
      final f = _LcuFriend.tryParse(m);
      if (f != null) parsed.add(f);
    }
    parsed.sort(_LcuFriend.compare);
    return parsed;
  }

  void _onLcuEvent(LcuEvent event) {
    if (!_isPerFriendUri(event.uri)) return;
    if (!mounted) return;

    // ignore: avoid_print
    print(
        '[Invite] Friend push uri=${event.uri} status=${event.httpStatus} dataType=${event.data.runtimeType}');

    if (event.httpStatus == 404) {
      _friendsMap.remove(event.uri);
      setState(() {
        _loading = false;
        _loadError = null;
        _friends = _friendsFromMap();
      });
      return;
    }

    if (event.httpStatus != 200) {
      setState(() {
        _loading = false;
        _loadError = 'Failed to load friends';
        _friends = _friendsFromMap();
      });
      return;
    }

    final data = event.data;
    if (data is! Map) {
      return;
    }
    _friendsMap[event.uri] = Map<String, dynamic>.from(data);

    if (!_receivedFriendsPush) {
      _receivedFriendsPush = true;
      _cancelFriendsWaitTimer();
    }

    setState(() {
      _loading = false;
      _loadError = null;
      _friends = _friendsFromMap();
    });
  }

  bool _isInvitedToLobby(int summonerId) {
    if (_optimisticInvited.contains(summonerId)) return true;
    for (final raw in widget.initialInvitations) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final tid = m['toSummonerId'];
      int? id;
      if (tid is int) {
        id = tid;
      } else if (tid is num) {
        id = tid.toInt();
      }
      if (id != summonerId) continue;
      final state = m['state']?.toString() ?? '';
      if (state == 'Pending' || state == 'Accepted') return true;
    }
    return false;
  }

  List<_LcuFriend> get _filteredBySearch {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return List<_LcuFriend>.from(_friends);
    return _friends.where((f) {
      return f.name.toLowerCase().contains(q) || f.gameName.toLowerCase().contains(q);
    }).toList();
  }

  List<_LcuFriend> get _filteredByTab {
    final base = _filteredBySearch;
    switch (_filterTab) {
      case 1:
        return base.where((f) => f.availability == 'chat').toList();
      case 2:
        return base.where((f) => f.availability == 'away').toList();
      case 3:
        return base.where((f) => f.availability == 'dnd').toList();
      default:
        return base;
    }
  }

  void _sendInvite(_LcuFriend f) {
    if (_isInvitedToLobby(f.summonerId)) return;
    setState(() => _optimisticInvited.add(f.summonerId));
    widget.riftService.sendLcuRequest(
      'POST',
      '/lol-lobby/v2/lobby/invitations',
      [
        {'toSummonerId': f.summonerId}
      ],
    );
  }

  @override
  void dispose() {
    _cancelFriendsWaitTimer();
    _sub?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Widget _availabilityDot(_LcuFriend f) {
    Color c;
    switch (f.availability) {
      case 'chat':
        c = _kAvailChat;
        break;
      case 'away':
        c = _kAvailAway;
        break;
      case 'dnd':
        c = _kAvailDnd;
        break;
      case 'mobile':
        c = _kAvailMobile;
        break;
      case 'offline':
      default:
        c = _kAvailOffline;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }

  String _availabilityLabel(_LcuFriend f) {
    if (f.availability == 'dnd') return 'In Game';
    return '';
  }

  Widget _filterChip(String label, int index) {
    final sel = _filterTab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _filterTab = index),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? _kGold.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? _kGold : Colors.white24),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: sel ? _kGold : Colors.white70,
                fontSize: 13,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _friendRow(_LcuFriend f) {
    final invited = _isInvitedToLobby(f.summonerId);
    final sub = _availabilityLabel(f);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          _availabilityDot(f),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: const TextStyle(color: _kAvailDnd, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (invited)
            Text(
              'Invited ✓',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            )
          else
            OutlinedButton(
              onPressed: () => _sendInvite(f),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kGold,
                side: const BorderSide(color: _kGold),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Invite', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredByTab;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Material(
        color: _kSheetBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Invite Friends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _search,
                focusNode: _searchFocus,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search summoner name...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.35),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kGold, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _filterChip('All', 0),
                  _filterChip('Online', 1),
                  _filterChip('Away', 2),
                  _filterChip('In Game', 3),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Colors.white10),
            Expanded(
              child: _loading
                  ? ListView(
                      controller: widget.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                            child: CircularProgressIndicator(
                                color: _kGold, strokeWidth: 2.5)),
                      ],
                    )
                  : _loadError != null
                      ? ListView(
                          controller: widget.scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _loadError!,
                                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  OutlinedButton(
                                    onPressed: _onRetryFriends,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _kGold,
                                      side: const BorderSide(color: _kGold),
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : list.isEmpty
                          ? ListView(
                              controller: widget.scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
                                Center(
                                  child: Text(
                                    'No friends found',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              controller: widget.scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                              itemCount: list.length * 2 - 1,
                              itemBuilder: (context, index) {
                                if (index.isOdd) {
                                  return const Divider(height: 1, color: Colors.white10);
                                }
                                final i = index ~/ 2;
                                return _friendRow(list[i]);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
