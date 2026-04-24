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
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
