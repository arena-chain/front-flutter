import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/models/feature_ticketing/ticketing_models.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math' as math;
import 'dart:convert';

class TicketDetailsScreen extends StatelessWidget {
  final TicketModel ticket;
  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060606),
      bottomNavigationBar: _buildBottomNav(),
      body: Stack(
        children: [
          // Hex Background
          Positioned.fill(child: CustomPaint(painter: _HexGridPainter())),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildTopBar(),
                  const SizedBox(height: 24),
                  _buildBreadcrumbs(),
                  const SizedBox(height: 32),
                  _buildTicketCard(context),
                  _buildActionButtons(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF87).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Color(0xFF00FF87), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'NEON_PROTOCOL',
              style: TextStyle(
                color: Color(0xFF00FF87),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white10,
          child: Icon(Icons.person, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        _breadcrumbText('CORE'),
        _breadcrumbDivider(),
        _breadcrumbText('VAULT'),
        _breadcrumbDivider(),
        _breadcrumbText(ticket.eventName.replaceAll(' ', '_').toUpperCase(), active: true),
      ],
    );
  }

  Widget _breadcrumbText(String text, {bool active = false}) {
    return Text(
      text,
      style: TextStyle(
        color: active ? const Color(0xFF00FF87).withOpacity(0.8) : Colors.white24,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }

  Widget _breadcrumbDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.chevron_right, color: Colors.white10, size: 12),
    );
  }

  Widget _buildTicketCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00FF87), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    const Text('SECURE_CONNECTION_ESTABLISHED', 
                      style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
                Text(
                  'ID_${ticket.id.substring(ticket.id.length - 4).toUpperCase()}',
                  style: TextStyle(color: const Color(0xFFFF00FF).withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF00FF).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF00FF).withOpacity(0.2)),
                  ),
                  child: Text(ticket.typeRaw.toUpperCase(), 
                    style: const TextStyle(color: Color(0xFFFF00FF), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                const SizedBox(height: 24),
                Text(
                  ticket.eventName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    height: 0.95,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  '${ticket.typeRaw.toUpperCase()} ACCESS PASS',
                  style: const TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 2),
                ),
                
                if (ticket.eventImageUrl != null && ticket.eventImageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.network(
                        ticket.eventImageUrl!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // STAMP
                Center(
                  child: Transform.rotate(
                    angle: -0.15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFFF00FF).withOpacity(0.3), width: 3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'VIP_EXCLUSIVITY',
                        style: TextStyle(
                          color: const Color(0xFFFF00FF).withOpacity(0.3),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                
                // Grid details
                Row(
                  children: [
                    _DetailItem(label: 'LOCATION', value: ticket.eventLocation.toUpperCase()),
                    const SizedBox(width: 40),
                    _DetailItem(label: 'DATE_ENTRY', value: DateFormat('dd.MM.yyyy').format(ticket.eventDateTime)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _DetailItem(label: 'GATE_PORTAL', value: 'S-${ticket.ticketNumber.replaceAll('-', '').substring(0, 4).toUpperCase()}'),
                    const SizedBox(width: 40),
                    _DetailItem(label: 'ADDR_CODE', value: ticket.id.length > 8 ? ticket.id.substring(ticket.id.length - 8).toUpperCase() : 'OMEGA_294X_B', accent: true),
                  ],
                ),
                
                const SizedBox(height: 48),
                const Divider(color: Colors.white10),
                const SizedBox(height: 48),

                // QR CODE
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF87).withOpacity(0.02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF00FF87).withOpacity(0.05), blurRadius: 40, spreadRadius: 10),
                      ],
                    ),
                    child: _buildQrDisplay(),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user, color: Color(0xFF00FF87), size: 16),
                    const SizedBox(width: 8),
                    const Text('VALIDATED_ELITE_NODE', 
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'This encrypted token grants the bearer full access to the VIP Lounge, Player Post-Match areas, and the Priority Entry terminal. Digital authentication required at all checkpoints.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, height: 1.5),
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MiniBadge(label: 'ENCRYPTED'),
                    const SizedBox(width: 12),
                    _MiniBadge(label: 'NFT_SECURED'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pass securely downloaded to local storage. 📥', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: Color(0xFF00FF87),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF87),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00FF87).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: const Center(
                child: Text(
                  'DOWNLOAD_PASS',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Transfer protocol is currently locked for this item.', style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.redAccent.withOpacity(0.9),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: Colors.white.withOpacity(0.3), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'TRANSFER',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(icon: Icons.grid_view, label: 'HUD'),
          _NavItem(icon: Icons.confirmation_num, label: 'TICKETS', active: true),
          _NavItem(icon: Icons.lock, label: 'VAULT'),
          _NavItem(icon: Icons.person_outline, label: 'PROFILE'),
        ],
      ),
    );
  }

  Widget _buildQrDisplay() {
    final qrData = ticket.qrCode;
    
    // Check if it's a base64 data URL
    if (qrData.startsWith('data:image')) {
      try {
        final base64String = qrData.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        );
      } catch (e) {
        return const Icon(Icons.error_outline, color: Colors.red, size: 40);
      }
    }
    
    // Regular text to encode
    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: 200.0,
      gapless: false,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.white),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.white),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  const _DetailItem({required this.label, required this.value, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: accent ? const Color(0xFF00FF87) : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  const _MiniBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _NavItem({required this.icon, required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? const Color(0xFF00FF87) : Colors.white24, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF00FF87) : Colors.white24,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _HexGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const double hexSize = 40;
    final double h = hexSize * math.sqrt(3);
    final double w = hexSize * 2;

    for (double y = -h; y < size.height + h * 2; y += h) {
      for (double x = -w; x < size.width + w * 2; x += w * 1.5) {
        final offsetY = ((x / (w * 1.5)).round() % 2 == 0) ? 0.0 : h / 2;
        _drawHex(canvas, Offset(x, y + offsetY), hexSize, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i) * math.pi / 180;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
