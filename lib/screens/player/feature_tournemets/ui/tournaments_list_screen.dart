import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/view_model/tournaments_view_model.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';
import 'package:intl/intl.dart';

class TournamentsListScreen extends StatefulWidget {
  const TournamentsListScreen({super.key});

  @override
  State<TournamentsListScreen> createState() => _TournamentsListScreenState();
}

class _TournamentsListScreenState extends State<TournamentsListScreen> {
  @override
  void initState() {
    super.initState();
    
    // Load tournaments when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentsViewModel>().loadTournaments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Consumer<TournamentsViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00FF00),
                  ),
                );
              }

              if (viewModel.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFFF0055),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading tournaments',
                        style: const TextStyle(
                          color: Color(0xFFFF0055),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.error!,
                        style: const TextStyle(color: Color(0xFF7A86AC)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return _buildTournamentList(viewModel.officialTournaments);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      Icons.emoji_events,
                      color: Color(0xFF00FF00),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tournaments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upcoming official tournaments',
            style: TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentList(List<TournamentModel> tournaments) {
    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.emoji_events_outlined,
              color: Color(0xFF7A86AC),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No official tournaments found',
              style: TextStyle(
                color: Color(0xFF7A86AC),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: tournaments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return _buildTournamentCard(tournament);
      },
    );
  }

  Widget _buildTournamentCard(TournamentModel tournament) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isFull = tournament.participants.length >= tournament.maxTeams;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1A1F36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tournament.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tournament.type == 'RANKED'
                      ? const Color(0xFF00FF00).withOpacity(0.1)
                      : const Color(0xFFFF0055).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tournament.type == 'RANKED'
                        ? const Color(0xFF00FF00).withOpacity(0.3)
                        : const Color(0xFFFF0055).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  tournament.type,
                  style: TextStyle(
                    color: tournament.type == 'RANKED'
                        ? const Color(0xFF00FF00)
                        : const Color(0xFFFF0055),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Game info (you can enhance this with game name from catalog)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F36),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tournament.gameId, // TODO: Replace with game name from catalog
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: dateFormat.format(tournament.startDate),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.monetization_on,
                  label: 'Prize',
                  value: tournament.prizePool ?? 'TBD',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.groups,
                  label: 'Players',
                  value: '${tournament.participants.length}/${tournament.maxTeams}',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: 'Online', // TODO: Add location field if needed
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

            // Registration button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isFull 
                  ? null 
                  : () {
                      Navigator.pushNamed(
                        context, 
                        '/tournaments/booking',
                        arguments: tournament,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFull 
                    ? const Color(0xFF1A1F36) 
                    : const Color(0xFF00FF00),
                foregroundColor: isFull 
                    ? const Color(0xFF7A86AC) 
                    : const Color(0xFF0A0E1A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isFull ? 'Registration Full' : 'Reserve',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF7A86AC), size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7A86AC),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
