import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/view_model/tournaments_view_model.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/ui/tournament_details_screen.dart';
import 'package:intl/intl.dart';

class TournamentsListScreen extends StatefulWidget {
  const TournamentsListScreen({super.key});

  @override
  State<TournamentsListScreen> createState() => _TournamentsListScreenState();
}

class _TournamentsListScreenState extends State<TournamentsListScreen> {
  static const Color _background = Color(0xFF000000);
  static const Color _surface = Color(0xFF0A0A0A);
  static const Color _card = Color(0xFF1A1C23);
  static const Color _neon = Color(0xFF39FF14);
  static const Color _danger = Color(0xFFFF0055);

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
    return ColoredBox(
      color: _background,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Consumer<TournamentsViewModel>(
              builder: (context, tournamentsVm, _) {
                return RefreshIndicator(
                  color: _neon,
                  backgroundColor: _surface,
                  onRefresh: () => context.read<TournamentsViewModel>().loadTournaments(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (tournamentsVm.isLoading)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _neon.withValues(alpha: 0.85),
                            ),
                          ),
                        )
                      else if (tournamentsVm.error != null)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: _danger,
                                  size: 48,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Error loading tournaments',
                                  style: TextStyle(
                                    color: _danger,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tournamentsVm.error!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.48),
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._buildTournamentListSlivers(tournamentsVm.officialTournaments),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _neon.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: _neon.withValues(alpha: 0.15),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: _neon.withValues(alpha: 0.95),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Tournaments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(color: _neon.withValues(alpha: 0.2), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Upcoming official tournaments',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTournamentListSlivers(List<TournamentModel> tournaments) {
    if (tournaments.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 88,
                  width: 88,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        color: _neon.withValues(alpha: 0.14),
                        size: 86,
                      ),
                      Icon(
                        Icons.emoji_events_rounded,
                        color: _neon.withValues(alpha: 0.58),
                        size: 72,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No official tournaments found',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back soon for ranked events and qualifiers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index < tournaments.length - 1 ? 16 : 0),
                child: _buildTournamentCard(tournaments[index]),
              );
            },
            childCount: tournaments.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildTournamentCard(TournamentModel tournament) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isFull = tournament.participants.length >= tournament.maxTeams;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TournamentDetailsScreen(tournament: tournament),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _neon.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: _neon.withValues(alpha: 0.06),
              blurRadius: 16,
            ),
          ],
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
                  color: tournament.status.toUpperCase() == 'OPEN_REGISTRATION'
                      ? _neon.withValues(alpha: 0.12)
                      : tournament.status.toUpperCase() == 'ONGOING'
                          ? Colors.cyan.withValues(alpha: 0.12)
                          : _danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tournament.status.toUpperCase() == 'OPEN_REGISTRATION'
                        ? _neon.withValues(alpha: 0.45)
                        : tournament.status.toUpperCase() == 'ONGOING'
                            ? Colors.cyan.withValues(alpha: 0.45)
                            : _danger.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  tournament.status,
                  style: TextStyle(
                    color: tournament.status.toUpperCase() == 'OPEN_REGISTRATION'
                        ? _neon.withValues(alpha: 0.95)
                        : tournament.status.toUpperCase() == 'ONGOING'
                            ? Colors.cyanAccent
                            : _danger,
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
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _neon.withValues(alpha: 0.22)),
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

          SizedBox(
            width: double.infinity,
              child: FilledButton(
              onPressed: (isFull || !tournament.canRegisterNow)
                  ? null
                  : () {
                      Navigator.pushNamed(
                        context,
                        '/tournaments/booking',
                        arguments: tournament,
                      );
                    },
              style: FilledButton.styleFrom(
                backgroundColor: isFull ? _surface : _neon,
                foregroundColor: isFull ? Colors.white.withValues(alpha: 0.4) : Colors.black,
                disabledBackgroundColor: _surface,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.38),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: isFull
                    ? BorderSide(color: _neon.withValues(alpha: 0.15))
                    : BorderSide.none,
              ),
              child: Text(
                isFull
                    ? 'Registration Full'
                    : (tournament.canRegisterNow ? 'Reserve' : 'Registration Unavailable'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
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
            Icon(icon, color: _neon.withValues(alpha: 0.65), size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
