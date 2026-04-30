import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/core/api/feature_auth/token_storage.dart';
import 'package:arena_chain_flutter/core/api/steam/steam_api.dart';
import 'package:arena_chain_flutter/screens/player/feature_home/viewmodel/linked_accounts_viewmodel.dart';

class LinkSteamScreen extends StatefulWidget {
  const LinkSteamScreen({super.key});

  @override
  State<LinkSteamScreen> createState() => _LinkSteamScreenState();
}

class _LinkSteamScreenState extends State<LinkSteamScreen> {
  static const Color _neon = Color(0xFF39FF14);
  final _steamIdController = TextEditingController();
  final SteamApi _steam = SteamApi();
  final TokenStorage _tokens = TokenStorage();
  bool _linking = false;
  bool _verifying = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _steamIdController.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    final id = _steamIdController.text.trim();
    if (id.isEmpty) {
      setState(() => _message = 'Enter your Steam ID (64-bit numeric).');
      return;
    }
    setState(() {
      _linking = true;
      _message = null;
      _success = false;
    });
    try {
      final t = await _tokens.getAccessToken();
      if (t == null) throw Exception('Not authenticated');
      final res = await _steam.link(steamId: id, token: t);
      setState(() {
        _linking = false;
        _message = res['message']?.toString() ?? 'Linked. Now verify.';
        _success = true;
      });
    } catch (e) {
      setState(() {
        _linking = false;
        _message = e.toString().replaceAll('Exception: ', '');
        _success = false;
      });
    }
  }

  Future<void> _verify() async {
    final id = _steamIdController.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _verifying = true;
      _message = null;
      _success = false;
    });
    try {
      final t = await _tokens.getAccessToken();
      if (t == null) throw Exception('Not authenticated');
      await _steam.verify(steamId: id, token: t);
      if (!mounted) return;
      await context.read<LinkedAccountsViewModel>().refresh();
      setState(() {
        _verifying = false;
        _message = 'Steam account verified.';
        _success = true;
      });
    } catch (e) {
      setState(() {
        _verifying = false;
        _message = e.toString().replaceAll('Exception: ', '');
        _success = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('Link Steam', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Connect your Steam account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your Steam ID64 (from your profile URL) then link and verify.',
              style: TextStyle(color: Color(0xFF7A86AC), fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _steamIdController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Steam ID',
                labelStyle: const TextStyle(color: Color(0xFF7A86AC)),
                filled: true,
                fillColor: const Color(0xFF1A1F36),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.numbers, color: Color(0xFF7A86AC)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F36),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _neon.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'STATUS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_message != null)
                    Text(
                      _message!,
                      style: TextStyle(
                        color: _success ? _neon : const Color(0xFFFF6B6B),
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _linking ? null : _link,
              style: ElevatedButton.styleFrom(
                backgroundColor: _neon,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _linking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('LINK STEAM', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _verifying ? null : _verify,
              style: OutlinedButton.styleFrom(
                foregroundColor: _neon,
                side: BorderSide(color: _neon.withValues(alpha: 0.85)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _verifying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _neon),
                    )
                  : const Text('VERIFY WITH STEAM', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
