import 'package:arena_chain_flutter/core/api/feature_tournaments/tournaments_api.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _tdBg = Color(0xFF000000);
const _tdSurface = Color(0xFF0A0A0A);
const _tdCard = Color(0xFF1A1C23);
const _tdNeon = Color(0xFF39FF14);

class TournamentDetailsScreen extends StatefulWidget {
  final TournamentModel tournament;
  const TournamentDetailsScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailsScreen> createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> with SingleTickerProviderStateMixin {
  final _api = TournamentsApi();

  late TabController _tabs;
  late TournamentModel _tournament;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _tournament = widget.tournament;
    _loadDetails();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final details = await _api.getTournamentById(widget.tournament.id);
      if (!mounted) return;
      setState(() => _tournament = details);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _tdBg,
      body: Column(
        children: [
          _Header(tournament: _tournament, tabs: _tabs),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _tdNeon))
                : _error != null
                    ? _ErrorState(error: _error!, onRetry: _loadDetails)
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _OverviewTab(tournament: _tournament),
                          _PhasesTab(tournament: _tournament),
                          _TeamsTab(tournament: _tournament),
                          _TicketsTab(tournament: _tournament),
                          _RulesTab(tournament: _tournament),
                        ],
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomRegisterBar(tournament: _tournament),
    );
  }
}

class _Header extends StatelessWidget {
  final TournamentModel tournament;
  final TabController tabs;
  const _Header({required this.tournament, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _tdSurface,
        border: Border(bottom: BorderSide(color: Color(0xFF222633))),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tournament.type} · ${tournament.format}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: tournament.status),
                ],
              ),
            ),
            TabBar(
              controller: tabs,
              isScrollable: true,
              indicatorColor: _tdNeon,
              labelColor: _tdNeon,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Phases'),
                Tab(text: 'Teams'),
                Tab(text: 'Tickets'),
                Tab(text: 'Rules'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final TournamentModel tournament;
  const _OverviewTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM dd, yyyy · HH:mm');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        _InfoCard(
          title: 'Description',
          child: Text(
            tournament.description?.trim().isNotEmpty == true ? tournament.description! : 'No description provided',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ),
        _InfoCard(
          title: 'Dates',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Start', dateFmt.format(tournament.startDate)),
              _kv('End', dateFmt.format(tournament.endDate)),
              _kv('Registration Start', _fmtDate(tournament.registrationStart, dateFmt)),
              _kv('Registration End', _fmtDate(tournament.registrationEnd, dateFmt)),
              _kv('Ticket Sales Start', _fmtDate(tournament.ticketSalesStart, dateFmt)),
            ],
          ),
        ),
        _InfoCard(
          title: 'Capacity',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Teams', '${tournament.currentTeams}/${tournament.maxTeams}'),
              _kv('Registration Open', tournament.registrationOpen ? 'Yes' : 'No'),
            ],
          ),
        ),
        _InfoCard(
          title: 'Prize',
          child: _kv('Prize Pool', tournament.prizePool ?? 'Not announced'),
        ),
      ],
    );
  }
}

class _PhasesTab extends StatelessWidget {
  final TournamentModel tournament;
  const _PhasesTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    if (tournament.phases.isEmpty) return const _EmptyText('No phases yet');
    final fmt = DateFormat('MMM dd');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      itemCount: tournament.phases.length,
      itemBuilder: (_, i) {
        final p = tournament.phases[i];
        return _InfoCard(
          title: p.name,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Status', p.status),
              _kv('Start', p.startDate != null ? fmt.format(p.startDate!) : 'TBD'),
              _kv('End', p.endDate != null ? fmt.format(p.endDate!) : 'TBD'),
              _kv('Matches', '${p.matchesCount}'),
            ],
          ),
        );
      },
    );
  }
}

class _TeamsTab extends StatelessWidget {
  final TournamentModel tournament;
  const _TeamsTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    if (tournament.teams.isEmpty && tournament.participants.isEmpty) {
      return const _EmptyText('No teams registered yet');
    }
    final rows = tournament.teams.isNotEmpty ? tournament.teams : tournament.participants;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      itemCount: rows.length,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _tdCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2F3F)),
        ),
        child: Text(rows[i], style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _TicketsTab extends StatelessWidget {
  final TournamentModel tournament;
  const _TicketsTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    if (tournament.ticketTypes.isEmpty) return const _EmptyText('No ticket types available');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      itemCount: tournament.ticketTypes.length,
      itemBuilder: (_, i) {
        final t = tournament.ticketTypes[i];
        return _InfoCard(
          title: t.name,
          child: _kv('Price', t.price ?? 'Free'),
        );
      },
    );
  }
}

class _RulesTab extends StatelessWidget {
  final TournamentModel tournament;
  const _RulesTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    if (tournament.rulesText == null || tournament.rulesText!.trim().isEmpty) {
      return const _EmptyText('No rules provided');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        _InfoCard(
          title: 'Rules',
          child: Text(
            tournament.rulesText!,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _BottomRegisterBar extends StatelessWidget {
  final TournamentModel tournament;
  const _BottomRegisterBar({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: _tdSurface,
        border: Border(top: BorderSide(color: Color(0xFF222633))),
      ),
      child: FilledButton(
        onPressed: tournament.canRegisterNow
            ? () => Navigator.pushNamed(
                  context,
                  '/tournaments/booking',
                  arguments: tournament,
                )
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: _tdNeon,
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFF20252E),
          disabledForegroundColor: Colors.white38,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(tournament.canRegisterNow ? 'Register / Join' : 'Registration Unavailable'),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _tdCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    Color c;
    if (s == 'PENDING_APPROVAL') {
      c = Colors.grey;
    } else if (s == 'OPEN_REGISTRATION') {
      c = Colors.greenAccent;
    } else if (s == 'ONGOING') {
      c = Colors.cyanAccent;
    } else if (s == 'COMPLETED') {
      c = Colors.green;
    } else if (s == 'CANCELLED' || s == 'REJECTED' || s == 'BLOCKED') {
      c = Colors.deepOrangeAccent;
    } else {
      c = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Text(
        s,
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 44),
            const SizedBox(height: 10),
            Text(error, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _tdNeon, foregroundColor: Colors.black),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;
  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
      ),
    );
  }
}

Widget _kv(String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(k, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12))),
          Expanded(child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );

String _fmtDate(DateTime? date, DateFormat fmt) => date == null ? 'N/A' : fmt.format(date);
