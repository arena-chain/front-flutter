import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/services/rift_service.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_lobby_screen.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_champ_select_screen.dart';

const _kBg = Color(0xFF0A0E1A);
const _kGold = Color(0xFFC89B3C);

class LolQueueScreen extends StatefulWidget {
  const LolQueueScreen({super.key});

  @override
  State<LolQueueScreen> createState() => _LolQueueScreenState();
}

class _LolQueueScreenState extends State<LolQueueScreen> {
  StreamSubscription<LcuEvent>? _sub;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _matchFound = false;
  String _gameflowPhase = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_matchFound) setState(() => _elapsedSeconds++);
    });
    _sub = context.read<RiftService>().lcuEvents.listen(_onLcuEvent);
  }

  void _onLcuEvent(LcuEvent event) {
    if (event.uri.contains('/lol-matchmaking/v1/ready-check')) {
      final data = event.data;
      if (data is Map<String, dynamic>) {
        final state = data['state']?.toString() ?? '';
        if (state == 'InProgress') {
          setState(() => _matchFound = true);
        }
      }
    }
    if (event.uri.contains('/lol-gameflow/v1/gameflow-phase') ||
        event.uri.contains('/lol-gameflow/v1/session')) {
      final phase = event.data is String ? event.data : (event.data?['phase'] ?? '');
      _gameflowPhase = phase.toString();

      if (_gameflowPhase == 'ChampSelect') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LolChampSelectScreen()),
        );
      } else if (_gameflowPhase == 'Lobby' || _gameflowPhase == 'None') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LolLobbyScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  void _accept() {
    context.read<RiftService>().sendLcuRequest('POST', '/lol-matchmaking/v1/ready-check/accept');
  }

  void _decline() {
    context.read<RiftService>().sendLcuRequest('POST', '/lol-matchmaking/v1/ready-check/decline');
  }

  void _cancelQueue() {
    context.read<RiftService>().sendLcuRequest('DELETE', '/lol-lobby/v2/lobby/matchmaking/search');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LolLobbyScreen()),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _matchFound ? _buildMatchFound() : _buildSearching(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearching() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(strokeWidth: 3, color: _kGold),
        ),
        const SizedBox(height: 24),
        const Text(
          'Searching for Match…',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _formatTime(_elapsedSeconds),
          style: const TextStyle(color: _kGold, fontSize: 36, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _cancelQueue,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchFound() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, color: _kGold, size: 72),
        const SizedBox(height: 20),
        const Text(
          'Match Found!',
          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _decline,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Decline', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _accept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Accept', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
