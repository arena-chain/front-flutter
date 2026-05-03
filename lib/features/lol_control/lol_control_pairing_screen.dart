import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/services/rift_service.dart';
import 'package:arena_chain_flutter/features/lol_control/lol_lobby_screen.dart';
import 'package:arena_chain_flutter/features/lol_control/qr_scanner_screen.dart';

const _kBg = Color(0xFF0A0E1A);
const _kGold = Color(0xFFC89B3C);
const _kSurface = Color(0xFF111827);

class LolControlPairingScreen extends StatefulWidget {
  const LolControlPairingScreen({super.key});

  @override
  State<LolControlPairingScreen> createState() => _LolControlPairingScreenState();
}

class _LolControlPairingScreenState extends State<LolControlPairingScreen> {
  final _ipController = TextEditingController(text: '192.168.1.145');
  final _portController = TextEditingController(text: '51001');
  final _codeController = TextEditingController();
  bool _navigated = false;

  bool _autoResuming = false;
  bool _hasSavedPairing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapAutoResume());
  }

  Future<void> _bootstrapAutoResume() async {
    if (!mounted) return;
    final rift = context.read<RiftService>();

    if (rift.status == RiftConnectionStatus.connected) return;

    final saved = await rift.pairingStorage.load();
    if (!mounted) return;
    if (saved == null) {
      setState(() => _hasSavedPairing = false);
      return;
    }

    setState(() {
      _hasSavedPairing = true;
      _autoResuming = true;
      _ipController.text = saved.ip;
      _portController.text = saved.port;
      _codeController.text = saved.code;
    });

    await rift.connect(saved.ip, saved.port, saved.code);
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (context.read<RiftService>().status != RiftConnectionStatus.connected) {
        setState(() => _autoResuming = false);
      }
    });
  }

  Future<void> _forgetPaired() async {
    await context.read<RiftService>().forgetPairing();
    if (!mounted) return;
    setState(() {
      _hasSavedPairing = false;
      _autoResuming = false;
      _ipController.text = '192.168.1.145';
      _portController.text = '51001';
      _codeController.text = '';
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _connect() {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    final code = _codeController.text.trim();
    if (ip.isEmpty || code.length != 6) return;

    context.read<RiftService>().connect(ip, port.isEmpty ? '51001' : port, code);
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<QrPairingPayload>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result == null || !mounted) return;

    setState(() {
      _ipController.text = result.ip;
      _portController.text = result.port;
      _codeController.text = result.code;
    });

    // Auto-connect after scan — matches the user's UX intent: "the request
    // of connecting will be sent to the desktop app as the current flow exists".
    // The user still sees the populated fields for ~1 frame so they can verify.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'LoL Control',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<RiftService>(
        builder: (context, rift, _) {
          // Navigate only once the desktop user has approved (first LCU data received).
          if (!_navigated && rift.status == RiftConnectionStatus.connected) {
            _navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LolLobbyScreen()),
              );
            });
          }

          final busy = rift.status == RiftConnectionStatus.connecting ||
              rift.status == RiftConnectionStatus.waitingForApproval;

          final showAutoResumeOverlay =
              _autoResuming && rift.status != RiftConnectionStatus.connected;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const Icon(Icons.sports_esports, size: 64, color: _kGold),
                const SizedBox(height: 16),
                const Text(
                  'Connect to Rift Relay',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan the QR code shown in Arena Chain Conduit on your PC,\nor enter the IP and 6-digit code manually.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 32),

                _buildLabel('PC IP Address'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _ipController,
                  hint: '192.168.1.145',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                _buildLabel('Port'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _portController,
                  hint: '51001',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                _buildLabel('Pairing Code'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _codeController,
                  hint: '000000',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 32),

                // ── status banners ─────────────────────────
                if (rift.status == RiftConnectionStatus.connecting)
                  _buildStatusRow(
                    icon: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kGold),
                    ),
                    text: 'Connecting to Rift…',
                    color: Colors.white70,
                  ),

                if (rift.status == RiftConnectionStatus.waitingForConduit)
                  _buildBanner(
                    text: 'Conduit not connected — make sure Conduit is running on your PC.',
                    bgColor: Colors.orange.withValues(alpha: 0.12),
                    borderColor: Colors.orangeAccent.withValues(alpha: 0.45),
                    textColor: Colors.orangeAccent,
                  ),

                if (rift.status == RiftConnectionStatus.waitingForApproval)
                  _buildStatusRow(
                    icon: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kGold),
                    ),
                    text: 'Waiting for approval on your PC…',
                    color: _kGold,
                  ),

                if (rift.status == RiftConnectionStatus.error)
                  _buildBanner(
                    text: rift.errorMessage,
                    bgColor: Colors.red.withValues(alpha: 0.15),
                    borderColor: Colors.redAccent.withValues(alpha: 0.4),
                    textColor: Colors.redAccent,
                  ),

                // ── scan-qr button ─────────────────────────
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : _scanQr,
                    icon: const Icon(Icons.qr_code_scanner, size: 20),
                    label: const Text(
                      'Scan QR code',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kGold,
                      side: BorderSide(color: _kGold.withValues(alpha: 0.6), width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── connect button ─────────────────────────
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: busy ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGold,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: _kGold.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Connect',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (_hasSavedPairing && !_autoResuming) ...[
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: _forgetPaired,
                    icon: const Icon(Icons.link_off, size: 16, color: Colors.redAccent),
                    label: const Text(
                      'Forget paired PC',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
              if (showAutoResumeOverlay)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xCC000000),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: _kGold),
                          const SizedBox(height: 16),
                          const Text(
                            'Reconnecting to your PC…',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Make sure Arena Chain Conduit is running.',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => setState(() => _autoResuming = false),
                            child: const Text(
                              'Use a different PC',
                              style: TextStyle(color: _kGold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusRow({required Widget icon, required String text, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 12),
          Flexible(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Widget _buildBanner({
    required String text,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        counterText: '',
        filled: true,
        fillColor: _kSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kGold),
        ),
      ),
    );
  }
}
