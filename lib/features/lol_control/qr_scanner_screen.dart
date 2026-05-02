import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const _kGold = Color(0xFFC89B3C);

/// Result returned from the scanner via Navigator.pop.
class QrPairingPayload {
  final String ip;
  final String port;
  final String code;

  const QrPairingPayload({
    required this.ip,
    required this.port,
    required this.code,
  });
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Parses `arenachain://pair?ip=<IP>&port=<PORT>&code=<CODE>` OR a raw JSON
  /// blob `{"ip":"...","port":51001,"code":"123456"}`. Returns null on any
  /// malformed input so the caller can show an inline error and keep scanning.
  QrPairingPayload? _parse(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    // URL form (preferred — what the desktop emits).
    try {
      final uri = Uri.parse(s);
      if (uri.scheme == 'arenachain' && uri.host == 'pair') {
        final ip = uri.queryParameters['ip'];
        final port = uri.queryParameters['port'];
        final code = uri.queryParameters['code'];
        if (ip != null && code != null && code.length == 6) {
          return QrPairingPayload(
            ip: ip,
            port: (port == null || port.isEmpty) ? '51001' : port,
            code: code,
          );
        }
      }
    } catch (_) {}

    // JSON fallback.
    try {
      final trimmed = s.startsWith('{') ? s : null;
      if (trimmed != null) {
        // Lightweight regex parse to avoid dragging dart:convert into the
        // hot path; the payload is tiny and well-known.
        final ipM = RegExp(r'"ip"\s*:\s*"([^"]+)"').firstMatch(trimmed);
        final portM = RegExp(r'"port"\s*:\s*"?(\d+)"?').firstMatch(trimmed);
        final codeM = RegExp(r'"code"\s*:\s*"(\d{6})"').firstMatch(trimmed);
        if (ipM != null && codeM != null) {
          return QrPairingPayload(
            ip: ipM.group(1)!,
            port: portM?.group(1) ?? '51001',
            code: codeM.group(1)!,
          );
        }
      }
    } catch (_) {}

    return null;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      final parsed = _parse(raw);
      if (parsed != null) {
        _handled = true;
        Navigator.of(context).pop(parsed);
        return;
      }
    }
    // Show a single transient error if the QR is unreadable / wrong format.
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.black87,
        content: Text(
          'Not an Arena Chain pairing QR. Try again.',
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cutoutSide = size.shortestSide * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── camera ─────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── dimmed overlay with viewfinder cutout ──────
          IgnorePointer(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: cutoutSide,
                      height: cutoutSide,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── viewfinder border ──────────────────────────
          IgnorePointer(
            child: Center(
              child: Container(
                width: cutoutSide,
                height: cutoutSide,
                decoration: BoxDecoration(
                  border: Border.all(color: _kGold, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          // ── header bar (back + title + torch) ──────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Scan pairing QR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, state, _) {
                      final on = state.torchState == TorchState.on;
                      return IconButton(
                        icon: Icon(
                          on ? Icons.flash_on : Icons.flash_off,
                          color: on ? _kGold : Colors.white,
                        ),
                        onPressed: () => _controller.toggleTorch(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── instruction text below cutout ──────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).viewPadding.bottom + 32,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Point your camera at the QR code shown in Arena Chain Conduit on your PC.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
