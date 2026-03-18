import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/player/feature_matchmaking/view_model/matchmaking_view_model.dart';
import 'package:arena_chain_flutter/core/models/feature_matchmaking/game_match_model.dart';

class GameRoomScreen extends StatelessWidget {
  const GameRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchmakingViewModel>(
      builder: (context, vm, _) {
        final game = vm.activeGame;
        if (game == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0E1A),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFF7A86AC), size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Game data unavailable',
                    style: TextStyle(color: Color(0xFF7A86AC), fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF1A1F36)),
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return _GameRoomBody(game: game, vm: vm);
      },
    );
  }
}

class _GameRoomBody extends StatelessWidget {
  final GameMatchModel game;
  final MatchmakingViewModel vm;

  const _GameRoomBody({required this.game, required this.vm});

  @override
  Widget build(BuildContext context) {
    final roomId = game.roomInfo?.roomId ?? '';
    final map = game.roomInfo?.map ?? "Summoner's Rift";

    final blueTeam =
        game.participants.where((p) => p.team == 'BLUE').toList();
    final redTeam =
        game.participants.where((p) => p.team == 'RED').toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.meeting_room, color: Color(0xFF00FF00), size: 24),
            SizedBox(width: 8),
            Text(
              'Game Room',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00FF00)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Color(0xFF00FF00), size: 8),
                const SizedBox(width: 6),
                Text(
                  game.status == 'ACCEPTED' ? 'READY' : game.status,
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPassKeySection(context, roomId),
            const SizedBox(height: 24),
            _buildMatchInfoSection(map),
            const SizedBox(height: 24),
            if (blueTeam.isNotEmpty || redTeam.isNotEmpty) ...[
              _buildTeamsSection(blueTeam, redTeam),
              const SizedBox(height: 24),
            ],
            _buildInstructions(),
            const SizedBox(height: 32),
            _buildDoneButton(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Pass Key Section ──────────────────────────────────────────────────

  Widget _buildPassKeySection(BuildContext context, String roomId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FF00).withOpacity(0.08),
            const Color(0xFF0F1221),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FF00).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.vpn_key, color: Color(0xFF00FF00), size: 32),
          const SizedBox(height: 8),
          const Text(
            'GAME PASS KEY',
            style: TextStyle(
              color: Color(0xFF7A86AC),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F36),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00FF00).withOpacity(0.4),
              ),
            ),
            child: Text(
              roomId,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (ctx) => ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: roomId));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Pass key copied!'),
                    backgroundColor: Color(0xFF00FF00),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Pass Key'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Match Info Section ────────────────────────────────────────────────

  Widget _buildMatchInfoSection(String map) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1F36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.sports_esports,
                  label: 'Mode',
                  value: game.modeLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.people,
                  label: 'Players',
                  value: '${game.numberOfParticipant}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.dns,
                  label: 'Server',
                  value: game.server ?? '—',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.public,
                  label: 'Region',
                  value: (game.region != null && game.region!.isNotEmpty)
                      ? game.region!
                      : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoTile(
            icon: Icons.map,
            label: 'Map',
            value: map,
          ),
          if (game.isScheduled) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00CCFF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF00CCFF).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule,
                      color: Color(0xFF00CCFF), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Scheduled Match  ·  ${game.createdAt != null ? DateFormat('MMM d, HH:mm').format(game.createdAt!) : '—'}',
                    style: const TextStyle(
                      color: Color(0xFF00CCFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00FF00), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7A86AC),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Teams Section ─────────────────────────────────────────────────────

  Widget _buildTeamsSection(
    List<ParticipantModel> blueTeam,
    List<ParticipantModel> redTeam,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teams',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (blueTeam.isNotEmpty) ...[
          _buildTeamHeader('BLUE SIDE', const Color(0xFF4488FF)),
          const SizedBox(height: 8),
          ...blueTeam
              .map((p) => _buildPlayerCard(p, const Color(0xFF4488FF))),
          const SizedBox(height: 16),
        ],
        if (redTeam.isNotEmpty) ...[
          _buildTeamHeader('RED SIDE', const Color(0xFFFF4444)),
          const SizedBox(height: 8),
          ...redTeam
              .map((p) => _buildPlayerCard(p, const Color(0xFFFF4444))),
        ],
      ],
    );
  }

  Widget _buildTeamHeader(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildPlayerCard(ParticipantModel participant, Color teamColor) {
    final account = participant.riotAccountInfo;
    final hasAccount = account != null && account.riotGameName != null;
    final iconId = account?.originalIconId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1221),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: teamColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasAccount
                    ? const Color(0xFFC89B3C)
                    : const Color(0xFF1A1F36),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasAccount && iconId != null && iconId > 0
                  ? Image.network(
                      'https://ddragon.leagueoflegends.com/cdn/14.1.1/img/profileicon/$iconId.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text(
                          'LoL',
                          style: TextStyle(
                            color: Color(0xFFC89B3C),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.person,
                        color: teamColor.withOpacity(0.5),
                        size: 22,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAccount
                      ? '${account!.riotGameName}#${account.riotTagLine ?? ''}'
                      : 'Player',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hasAccount
                      ? 'ELO: ${participant.elo}  ·  ${_serverLabel(account!.riotRegion)}'
                      : 'ELO: ${participant.elo}',
                  style: const TextStyle(
                    color: Color(0xFF7A86AC),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: teamColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${participant.elo}',
              style: TextStyle(
                color: teamColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _serverLabel(String? riotRegion) {
    if (riotRegion == null) return '';
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
      default:
        return riotRegion.toUpperCase();
    }
  }

  // ── Instructions ──────────────────────────────────────────────────────

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.orangeAccent.withOpacity(0.25)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: Colors.orangeAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'How to join',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _InstructionStep(
              number: '1', text: 'Open League of Legends on your PC'),
          SizedBox(height: 6),
          _InstructionStep(
              number: '2', text: 'Go to Play > Custom Game > Create'),
          SizedBox(height: 6),
          _InstructionStep(
              number: '3',
              text: 'Use the pass key above as the room name'),
          SizedBox(height: 6),
          _InstructionStep(
              number: '4',
              text: 'Wait for all players to join, then start!'),
        ],
      ),
    );
  }

  // ── Done Button ───────────────────────────────────────────────────────

  Widget _buildDoneButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          vm.resetState();
          Navigator.pop(context);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF1A1F36)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Done — Return to Home',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
