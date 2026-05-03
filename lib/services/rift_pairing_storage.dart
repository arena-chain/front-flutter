import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted Rift relay pairing credentials.
///
/// Saved AFTER a successful pairing handshake (status reaches `connected`).
/// Used on subsequent app launches / re-entries to LoL Control to skip the
/// QR / manual-entry form when the desktop's Conduit is still running with
/// the same pairing code.
///
/// Cleared only by an explicit user action ("Forget paired PC" button on
/// the pairing screen) — NOT by `RiftService.disconnect()`, since back-button
/// navigation from the lobby is allowed to leave the WS dropped while keeping
/// the saved creds alive.
class RiftPairingStorage {
  static const String _kPairingKey = 'rift_pairing_v1';

  Future<void> save({
    required String ip,
    required String port,
    required String code,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kPairingKey,
      jsonEncode({'ip': ip, 'port': port, 'code': code, 'savedAt': DateTime.now().toIso8601String()}),
    );
  }

  Future<RiftPairingCreds?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPairingKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final ip = m['ip']?.toString() ?? '';
      final port = m['port']?.toString() ?? '';
      final code = m['code']?.toString() ?? '';
      if (ip.isEmpty || code.length != 6) return null;
      return RiftPairingCreds(ip: ip, port: port.isEmpty ? '51001' : port, code: code);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPairingKey);
  }

  Future<bool> hasSaved() async => (await load()) != null;
}

class RiftPairingCreds {
  final String ip;
  final String port;
  final String code;
  const RiftPairingCreds({required this.ip, required this.port, required this.code});
}
