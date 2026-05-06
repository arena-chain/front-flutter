import 'package:arena_chain_flutter/core/dto/tournaments/create_tournament_dto.dart';
import 'package:arena_chain_flutter/core/models/feature_friends/friend_user_model.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';
import 'package:arena_chain_flutter/core/models/feature_catalog/catalog_model.dart';
import 'package:arena_chain_flutter/core/repositories/feature_friends/friends_repository.dart';
import 'package:arena_chain_flutter/core/repositories/feature_tournaments/tournaments_repository.dart';
import 'package:arena_chain_flutter/core/repositories/feature_catalog/catalog_repository.dart';
import 'package:flutter/material.dart';

class TournamentsViewModel extends ChangeNotifier {
  final TournamentsRepository _tournamentsRepository;
  final FriendsRepository _friendsRepository;
  final CatalogRepository _catalogRepository;
  final String currentUserId;

  List<TournamentModel> _tournaments = [];
  List<FriendUser> _availableFriends = [];
  List<CatalogModel> _availableGames = [];
  bool _isLoading = false;
  String? _error;

  List<TournamentModel> get tournaments => _tournaments;
  List<FriendUser> get availableFriends => _availableFriends;
  List<CatalogModel> get availableGames => _availableGames;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered tournament getters
  List<TournamentModel> get rankedTournaments =>
      _tournaments.where((t) => t.type == 'RANKED').toList();

  List<TournamentModel> get officialTournaments =>
      _tournaments.where((t) => t.type == 'OFFICIAL').toList();

  List<TournamentModel> get myTournaments =>
      _tournaments.where((t) => t.organizerId == currentUserId).toList();


  TournamentsViewModel({
    required this.currentUserId,
    TournamentsRepository? tournamentsRepository,
    FriendsRepository? friendsRepository,
    CatalogRepository? catalogRepository,
  })  : _tournamentsRepository =
            tournamentsRepository ?? TournamentsRepository(),
        _friendsRepository = friendsRepository ?? FriendsRepository(),
        _catalogRepository = catalogRepository ?? CatalogRepository();

  Future<void> loadTournaments() async {
    _setLoading(true);
    try {
      _tournaments = await _tournamentsRepository.getTournaments();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFriendsForInvite() async {
    try {
      final friendships = await _friendsRepository.getFriends(currentUserId);
      
      // Extract friend users from friendships
      _availableFriends = friendships
          .map((friendship) => friendship.counterpartFor(currentUserId))
          .whereType<FriendUser>()
          .toList();
      
      notifyListeners();
    } catch (e) {
      print('Error loading friends: $e');
    }
  }


  Future<void> loadGames() async {
    try {
      _availableGames = await _catalogRepository.getGames();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load games: ${e.toString()}';
      print('Error loading games: $e');
      notifyListeners();
    }
  }


  Future<bool> createTournament({
    required String name,
    required String gameId,
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    required int maxTeams,
    String? prizePool,
    List<String>? invitedUserIds,
  }) async {
    _setLoading(true);
    try {
      final dto = CreateTournamentDto(
        name: name,
        gameId: gameId,
        type: 'RANKED', // Default to RANKED as per requirements
        format: format,
        startDate: startDate,
        endDate: endDate,
        maxTeams: maxTeams,
        prizePool: prizePool,
        organizerId: currentUserId,
        invitedUserIds: invitedUserIds,
      );

      await _tournamentsRepository.createTournament(dto);
      _error = null;
      
      // Reload tournaments to show the new one
      await loadTournaments();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
