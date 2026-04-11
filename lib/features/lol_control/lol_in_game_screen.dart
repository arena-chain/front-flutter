import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/services/rift_service.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_control_pairing_screen.dart';

const _kBg = Color(0xFF0A0E1A);
const _kGold = Color(0xFFC89B3C);

class LolInGameScreen extends StatelessWidget {
  const LolInGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videogame_asset, size: 72, color: _kGold),
                const SizedBox(height: 24),
                const Text(
                  'Game in Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'In-game controls will be added in Phase 4.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<RiftService>().disconnect();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LolControlPairingScreen()),
                        (route) => route.isFirst,
                      );
                    },
                    icon: const Icon(Icons.link_off, color: Colors.redAccent),
                    label: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
