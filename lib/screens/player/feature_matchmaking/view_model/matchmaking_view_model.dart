import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arena_chain_flutter/core/repositories/feature_matchmaking/matchmaking_repository.dart';
import 'package:arena_chain_flutter/core/models/feature_matchmaking/ticket_model.dart';
import 'package:arena_chain_flutter/core/models/feature_matchmaking/game_match_model.dart';
import 'package:arena_chain_flutter/core/api/riot/riot_api.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';

enum MatchmakingStatus {
  idle,
  searching,
  pendingAcceptance,
  accepted,
  cancelled,
  expired,
  error,
}

class ConnectedAccountInfo {
  final int? originalIconId;
  final String riotGameName;
  final String riotTagLine;
  final String riotRegion;
  final String riotPuuid;
  final String riotLinkStatus;

  ConnectedAccountInfo({
    this.originalIconId,
    required this.riotGameName,
    required this.riotTagLine,
    required this.riotRegion,
    required this.riotPuuid,
    required this.riotLinkStatus,
  });

  Map<String, dynamic> toMatchmakingPayload() {
    return {
      'originalIconId': originalIconId ?? 0,
      'riotGameName': riotGameName,
      'riotLinkStatus': riotLinkStatus,
      'riotPuuid': riotPuuid,
      'riotRegion': riotRegion,
      'riotTagLine': riotTagLine,
    };
  }

  String get serverLabel {
    switch (riotRegion.toLowerCase()) {
      case 'euw1':
        return 'EUW';
      case 'eun1':
        return 'EUNE';
      case 'na1':
        return 'NA';
      case 'kr':
        return 'KR';
      case 'br1':
        return 'BR';
      case 'tr1':
        return 'TR';
      case 'ru':
        return 'RU';
      case 'la1':
        return 'LAN';
      case 'la2':
        return 'LAS';
      case 'jp1':
        return 'JP';
      case 'oc1':
        return 'OCE';
      default:
        return riotRegion.toUpperCase();
    }
  }
}

class MatchmakingViewModel extends ChangeNotifier {
  final MatchmakingRepository _repository;
  final RiotApi _riotApi = RiotApi();
  final TokenStorage _tokenStorage = TokenStorage();

  MatchmakingViewModel({MatchmakingRepository? repository})
      : _repository = repository ?? MatchmakingRepository();

  // ── State ──────────────────────────────────────────────────────────────

  MatchmakingStatus _status = MatchmakingStatus.idle;
  MatchmakingStatus get status => _status;

  TicketModel? _ticket;
  TicketModel? get ticket => _ticket;

  String? _activeGameId;
  String? get activeGameId => _activeGameId;

  GameMatchModel? _activeGame;
  GameMatchModel? get activeGame => _activeGame;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _userExplicitlyAccepted = false;

  Timer? _pollTimer;

  String selectedGame = 'LOL';
  String selectedMode = 'CUSTOM_1V1';
  String selectedServer = 'EUW';
  String selectedPlayerRegion = 'ALL';

  bool _isScheduleMode = false;
  bool get isScheduleMode => _isScheduleMode;

  DateTime? _scheduledTime;
  DateTime? get scheduledTime => _scheduledTime;

  // ── Scheduled tickets state ────────────────────────────────────────────

  List<TicketModel> _scheduledTickets = [];
  List<TicketModel> get scheduledTickets => List.unmodifiable(_scheduledTickets);

  Timer? _scheduledPollTimer;

  // ── Schedule conflict state ────────────────────────────────────────────

  TicketModel? _conflictingTicket;
  TicketModel? get conflictingTicket => _conflictingTicket;

  // ── Connected account state ─────────────────────────────────────────

  bool _isLoadingLinkStatus = true;
  bool get isLoadingLinkStatus => _isLoadingLinkStatus;

  String _linkStatus = 'unlinked';
  String get linkStatus => _linkStatus;

  ConnectedAccountInfo? _connectedAccount;
  ConnectedAccountInfo? get connectedAccount => _connectedAccount;

  bool _isAccountSelected = false;
  bool get isAccountSelected => _isAccountSelected;

  static const List<String> servers = ['EUW', 'EUNE', 'NA', 'KR', 'BR'];
  static const List<String> playerRegions = [
    'ALL',
    'TUN',
    'MAR',
    'DZA',
    'LBY',
    'EGY',
    'MRT',
  ];

  // ── Persistence keys ───────────────────────────────────────────────────

  static const String _activeGameIdKey = 'mm_active_game_id';
  static const String _activeTicketIdKey = 'mm_active_ticket_id';

  // ── Auth lifecycle ─────────────────────────────────────────────────────

  bool _isAuthenticated = false;
  bool _isRestoring = false;

  void onAuthChanged(bool authenticated) {
    if (authenticated && !_isAuthenticated) {
      _isAuthenticated = true;
      fetchLinkStatus();
      restoreMatchmakingState();
    } else if (!authenticated && _isAuthenticated) {
      _isAuthenticated = false;

      final gameId = _activeGameId;
      if (gameId != null && _activeGame?.status == 'ACCEPTED') {
        _repository.acknowledgeGame(gameId).catchError((_) {});
      }

      _stopPolling();
      _stopScheduledPoll();
      _clearPersistedState();
      _reset();
      _connectedAccount = null;
      _isAccountSelected = false;
      _linkStatus = 'unlinked';
      _isLoadingLinkStatus = true;
      notifyListeners();
    }
  }

  // ── Connected account fetching ──────────────────────────────────────

  Future<void> fetchLinkStatus() async {
    _isLoadingLinkStatus = true;
    notifyListeners();
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        _isLoadingLinkStatus = false;
        notifyListeners();
        return;
      }

      final result = await _riotApi.getLinkStatus(token: token);
      _linkStatus = result['status'] ?? 'unlinked';

      if (_linkStatus == 'verified') {
        _connectedAccount = ConnectedAccountInfo(
          originalIconId: result['originalIconId'] as int?,
          riotGameName: result['riotGameName'] ?? '',
          riotTagLine: result['riotTagLine'] ?? '',
          riotRegion: result['riotRegion'] ?? '',
          riotPuuid: result['riotPuuid'] ?? '',
          riotLinkStatus: _linkStatus,
        );
      } else {
        _connectedAccount = null;
      }
    } catch (e) {
      debugPrint('Fetch link status error: $e');
    } finally {
      _isLoadingLinkStatus = false;
      notifyListeners();
    }
  }

  void selectAccount(ConnectedAccountInfo account) {
    _isAccountSelected = true;
    _connectedAccount = account;
    selectedServer = account.serverLabel;
    notifyListeners();
  }

  void deselectAccount() {
    _isAccountSelected = false;
    notifyListeners();
  }

  // ── Persistence helpers ────────────────────────────────────────────────

  Future<void> _persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeGameId != null) {
        await prefs.setString(_activeGameIdKey, _activeGameId!);
      } else {
        await prefs.remove(_activeGameIdKey);
      }
      if (_ticket != null) {
        await prefs.setString(_activeTicketIdKey, _ticket!.id);
      } else {
        await prefs.remove(_activeTicketIdKey);
      }
    } catch (e) {
      debugPrint('Persist matchmaking state error: $e');
    }
  }

  Future<void> _clearPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeGameIdKey);
      await prefs.remove(_activeTicketIdKey);
    } catch (e) {
      debugPrint('Clear matchmaking state error: $e');
    }
  }

  // ── Restore on app (re)start ──────────────────────────────────────────

  Future<void> restoreMatchmakingState() async {
    if (_isRestoring) return;
    if (_status != MatchmakingStatus.idle) return;

    _isRestoring = true;
    try {
      await fetchScheduledTickets();

      final ticket = await _repository.getActiveTicket();
      if (ticket != null) {
        _ticket = ticket;

        if (ticket.status == 'SEARCHING') {
          _status = MatchmakingStatus.searching;
          await _persistState();
          _startPollingForMatch();
          notifyListeners();
          _isRestoring = false;
          return;
        }

        if (ticket.status == 'MATCHED' && ticket.gameId != null) {
          _activeGameId = ticket.gameId;
          try {
            final g = await _repository.getGame(ticket.gameId!);
            _activeGame = g;
            _activeGameId = g.id;
            _updateStatusFromGame(g);
            await _persistState();
            if (_status == MatchmakingStatus.pendingAcceptance) {
              _startPollingGame(g.id);
            }
          } catch (_) {
            _reset();
            await _clearPersistedState();
          }
          notifyListeners();
          _isRestoring = false;
          return;
        }
      }

      final game = await _repository.getActiveGame();
      if (game != null) {
        _activeGame = game;
        _activeGameId = game.id;
        _updateStatusFromGame(game);
        await _persistState();
        if (_status == MatchmakingStatus.pendingAcceptance) {
          _startPollingGame(game.id);
        }
        notifyListeners();
        _isRestoring = false;
        return;
      }

      if (_scheduledTickets.isNotEmpty) {
        _startScheduledPoll();
      }

      await _clearPersistedState();
    } catch (e) {
      debugPrint('Restore matchmaking state error: $e');
    } finally {
      _isRestoring = false;
    }
  }

  // ── Schedule mode ──────────────────────────────────────────────────────

  void toggleScheduleMode() {
    _isScheduleMode = !_isScheduleMode;
    if (!_isScheduleMode) {
      _scheduledTime = null;
    }
    notifyListeners();
  }

  void setScheduledTime(DateTime time) {
    _scheduledTime = time;
    notifyListeners();
  }

  void clearScheduledTime() {
    _scheduledTime = null;
    notifyListeners();
  }

  // ── Scheduled tickets management ───────────────────────────────────────

  Future<void> fetchScheduledTickets() async {
    try {
      _scheduledTickets = await _repository.getScheduledTickets();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch scheduled tickets error: $e');
    }
  }

  Future<void> cancelScheduledTicket(String ticketId) async {
    try {
      await _repository.cancelSearch(ticketId);
      _scheduledTickets.removeWhere((t) => t.id == ticketId);
      notifyListeners();
      if (_scheduledTickets.isEmpty) {
        _stopScheduledPoll();
      }
    } catch (e) {
      debugPrint('Cancel scheduled ticket error: $e');
    }
  }

  // ── Schedule conflict ──────────────────────────────────────────────────

  TicketModel? _findUpcomingConflict() {
    if (_scheduledTickets.isEmpty) return null;
    final now = DateTime.now();
    final thirtyMinLater = now.add(const Duration(minutes: 30));
    for (final t in _scheduledTickets) {
      if (t.scheduledAt != null &&
          t.scheduledAt!.isAfter(now) &&
          t.scheduledAt!.isBefore(thirtyMinLater)) {
        return t;
      }
    }
    return null;
  }

  void clearConflict() {
    _conflictingTicket = null;
    notifyListeners();
  }

  Future<void> cancelConflictAndSearch() async {
    if (_conflictingTicket == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.cancelSearch(_conflictingTicket!.id);
      _scheduledTickets.removeWhere((t) => t.id == _conflictingTicket!.id);
      _conflictingTicket = null;
      _isLoading = false;
      notifyListeners();
      await startSearch();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Start search ──────────────────────────────────────────────────────

  Future<void> startSearch() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isScheduleMode && _scheduledTime != null) {
        await _repository.findMatch(
          game: selectedGame,
          mode: selectedMode,
          server: selectedServer,
          region: selectedPlayerRegion,
          scheduledAt: _scheduledTime,
          riotAccountInfo: _connectedAccount?.toMatchmakingPayload(),
        );
        await fetchScheduledTickets();
        _isScheduleMode = false;
        _scheduledTime = null;
        _status = MatchmakingStatus.idle;
        _startScheduledPoll();
      } else {
        final conflict = _findUpcomingConflict();
        if (conflict != null) {
          _conflictingTicket = conflict;
          _isLoading = false;
          notifyListeners();
          return;
        }

        final ticket = await _repository.findMatch(
          game: selectedGame,
          mode: selectedMode,
          server: selectedServer,
          region: selectedPlayerRegion,
          riotAccountInfo: _connectedAccount?.toMatchmakingPayload(),
        );
        _ticket = ticket;
        await _persistState();
        _status = MatchmakingStatus.searching;
        _startPollingForMatch();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = MatchmakingStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Cancel search ─────────────────────────────────────────────────────

  Future<void> cancelSearch() async {
    if (_ticket == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.cancelSearch(_ticket!.id);
      _stopPolling();
      _reset();
      await _clearPersistedState();
      await fetchScheduledTickets();
      if (_scheduledTickets.isNotEmpty) {
        _startScheduledPoll();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Accept / Decline ──────────────────────────────────────────────────

  Future<void> acceptMatch() async {
    if (_activeGameId == null) return;

    _isLoading = true;
    _userExplicitlyAccepted = true;
    notifyListeners();

    try {
      final game = await _repository.acceptMatch(_activeGameId!);
      _activeGame = game;
      _updateStatusFromGame(game);
      await _persistState();
      if (_status == MatchmakingStatus.pendingAcceptance) {
        _startPollingGame(_activeGameId!);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> declineMatch() async {
    if (_activeGameId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.declineMatch(_activeGameId!);
      _stopPolling();
      _reset();
      await _clearPersistedState();
      await fetchScheduledTickets();
      if (_scheduledTickets.isNotEmpty) {
        _startScheduledPoll();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Polling ───────────────────────────────────────────────────────────

  void _startPollingForMatch() {
    _stopPolling();
    _stopScheduledPoll();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _checkForMatch();
    });
  }

  Future<void> _checkForMatch() async {
    try {
      final ticket = await _repository.getActiveTicket();
      debugPrint(
          'Poll: ticket=${ticket?.id}, status=${ticket?.status}, gameId=${ticket?.gameId}');

      if (ticket != null &&
          ticket.status == 'MATCHED' &&
          ticket.gameId != null) {
        _ticket = ticket;
        _activeGameId = ticket.gameId;
        _stopPolling();
        final game = await _repository.getGame(ticket.gameId!);
        debugPrint('Fetched game: id=${game.id}, status=${game.status}');
        _activeGame = game;
        _activeGameId = game.id;
        _updateStatusFromGame(game);
        await _persistState();
        notifyListeners();
        if (_status == MatchmakingStatus.pendingAcceptance) {
          _startPollingGame(game.id);
        }
        return;
      }
    } catch (e) {
      debugPrint('Matchmaking poll error: $e');
    }
  }

  void _startPollingGame(String gameId) {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final game = await _repository.getGame(gameId);
        _activeGame = game;
        _updateStatusFromGame(game);
        notifyListeners();

        if (game.status == 'ACCEPTED' || game.status == 'CANCELLED') {
          _stopPolling();
        }
      } catch (e) {
        debugPrint('Game poll error: $e');
      }
    });
  }

  // ── Scheduled tickets background poll ──────────────────────────────────

  void _startScheduledPoll() {
    _stopScheduledPoll();
    _scheduledPollTimer =
        Timer.periodic(const Duration(seconds: 10), (_) async {
      await _checkScheduledTickets();
    });
  }

  void _stopScheduledPoll() {
    _scheduledPollTimer?.cancel();
    _scheduledPollTimer = null;
  }

  Future<void> _checkScheduledTickets() async {
    if (_status != MatchmakingStatus.idle) return;

    try {
      await fetchScheduledTickets();

      final activeTicket = await _repository.getActiveTicket();
      if (activeTicket == null) return;

      if (activeTicket.status == 'MATCHED' && activeTicket.gameId != null) {
        _ticket = activeTicket;
        _activeGameId = activeTicket.gameId;
        _stopScheduledPoll();
        final game = await _repository.getGame(activeTicket.gameId!);
        _activeGame = game;
        _activeGameId = game.id;
        _updateStatusFromGame(game);
        await _persistState();
        notifyListeners();
        if (_status == MatchmakingStatus.pendingAcceptance) {
          _startPollingGame(game.id);
        }
      } else if (activeTicket.status == 'SEARCHING') {
        _ticket = activeTicket;
        _status = MatchmakingStatus.searching;
        _stopScheduledPoll();
        await _persistState();
        _startPollingForMatch();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Scheduled poll error: $e');
    }
  }

  void _updateStatusFromGame(GameMatchModel game) {
    switch (game.status) {
      case 'PENDING_ACCEPTANCE':
        _status = MatchmakingStatus.pendingAcceptance;
        break;
      case 'ACCEPTED':
        if (_userExplicitlyAccepted || game.roomInfo != null) {
          _status = MatchmakingStatus.accepted;
        } else {
          _status = MatchmakingStatus.pendingAcceptance;
        }
        break;
      case 'CANCELLED':
        if (_status == MatchmakingStatus.pendingAcceptance) {
          _status = MatchmakingStatus.expired;
        } else {
          _status = MatchmakingStatus.cancelled;
        }
        _clearPersistedState();
        break;
      default:
        break;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _reset() {
    _status = MatchmakingStatus.idle;
    _ticket = null;
    _activeGameId = null;
    _activeGame = null;
    _errorMessage = null;
    _userExplicitlyAccepted = false;
    _isScheduleMode = false;
    _scheduledTime = null;
    _conflictingTicket = null;
  }

  Future<void> resetState() async {
    final gameId = _activeGameId;
    if (gameId != null && _activeGame?.status == 'ACCEPTED') {
      try {
        await _repository.acknowledgeGame(gameId);
      } catch (e) {
        debugPrint('Acknowledge game error: $e');
      }
    }

    _stopPolling();
    _reset();
    await _clearPersistedState();
    await fetchScheduledTickets();
    if (_scheduledTickets.isNotEmpty) {
      _startScheduledPoll();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    _stopScheduledPoll();
    super.dispose();
  }
}
