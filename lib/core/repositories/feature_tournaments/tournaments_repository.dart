import 'package:arena_chain_flutter/core/models/feature_tournaments/ticket_model.dart';
import 'package:arena_chain_flutter/core/api/feature_tournaments/tournaments_api.dart';
import 'package:arena_chain_flutter/core/dto/tournaments/create_tournament_dto.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';

class TournamentsRepository {
  final TournamentsApi _api;

  TournamentsRepository({TournamentsApi? api}) : _api = api ?? TournamentsApi();

  Future<TournamentModel> createTournament(CreateTournamentDto dto) async {
    try {
      return await _api.createTournament(dto);
    } catch (e) {
      throw Exception('Failed to create tournament: ${e.toString()}');
    }
  }

  Future<List<TournamentModel>> getTournaments() async {
    try {
      return await _api.getTournaments();
    } catch (e) {
      throw Exception('Failed to load tournaments: ${e.toString()}');
    }
  }

  Future<List<TicketModel>> bookTicket({
    required String tournamentId,
    required String userId,
    required String ticketType,
    required int quantity,
  }) async {
    try {
      return await _api.bookTicket(
        tournamentId: tournamentId,
        userId: userId,
        ticketType: ticketType,
        quantity: quantity,
      );
    } catch (e) {
      throw Exception('Failed to book ticket: ${e.toString()}');
    }
  }

  Future<List<TicketModel>> getMyTickets(String userId) async {
    try {
      return await _api.getMyTickets(userId);
    } catch (e) {
      throw Exception('Failed to fetch tickets: ${e.toString()}');
    }
  }
}
