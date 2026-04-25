import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/models/feature_ticketing/ticketing_models.dart';
import 'package:arena_chain_flutter/core/api/feature_ticketing/ticketing_api.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import 'dart:convert';
import 'package:arena_chain_flutter/screens/player/feature_ticketing/ticket_details_screen.dart';

class TicketWalletScreen extends StatefulWidget {
  const TicketWalletScreen({super.key});

  @override
  State<TicketWalletScreen> createState() => _TicketWalletScreenState();
}

class _TicketWalletScreenState extends State<TicketWalletScreen> {
  final _api = TicketingApi();
  List<TicketModel> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final list = await _api.getMyTickets();
      if (mounted) setState(() => _tickets = list);
    } catch (e) {
      debugPrint('Error loading tickets: \$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Ticket theme data for visual variety
  static const _ticketThemes = [
    _TicketTheme('PREMIUM ACCESS', Color(0xFF00FF87), 'VALORANT\nCHAMPIONS', 'GRAND\nFINALS', 'A-04', 'ULTRA-12B', '01', 'VLR VS FNC', 'AUG 24'),
    _TicketTheme('ELITE CIRCUIT', Color(0xFFFF00FF), 'LEC\nSUMMER\nSPLIT', 'BERLIN\nFINALS', 'E-11', 'VIP-B', '001', 'G2 VS KC', 'SEPT 12'),
    _TicketTheme('FOUNDER ACCESS', Color(0xFF00BFFF), 'DOTA 2\nTI13', 'EGIS\nEDITION', 'Z-99', 'FLOORGEN-P', '777', 'LIQUID VS SPIRIT', 'OCT 10'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Hex grid background
          Positioned.fill(child: CustomPaint(painter: _HexGridPainter())),

          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)))
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Header
                      SliverToBoxAdapter(child: _buildHeader()),
                      // Tickets grid
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: _tickets.isEmpty
                            ? const SliverToBoxAdapter(child: _EmptyVault())
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final theme = _ticketThemes[index % _ticketThemes.length];
                                    return InkWell(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => TicketDetailsScreen(ticket: _tickets[index])),
                                      ),
                                      child: _NeonCommandCard(
                                        ticket: _tickets[index],
                                        theme: theme,
                                        index: index,
                                      ),
                                    );
                                  },
                                  childCount: _tickets.length,
                                ),
                              ),
                      ),
                      // Sync new asset card
                      SliverToBoxAdapter(child: _buildSyncCard()),
                      // Bottom stats
                      SliverToBoxAdapter(child: _buildStats()),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            children: [
              // Drawer menu button for consistency
              Builder(
                builder: (context) => InkWell(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Neon Command logo
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEON COMMAND',
                      style: TextStyle(
                          color: Color(0xFF00FF87),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.0)),
                  Text('AUTHENTICATED STATUS',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                ],
              ),
              const Spacer(),
              _headerIcon(Icons.monitor_heart_outlined),
              const SizedBox(width: 10),
              _headerIcon(Icons.settings_outlined),
            ],
          ),
          const SizedBox(height: 28),
          // Digital Vault title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00FF87), Color(0xFF00CC6A)],
            ).createShader(bounds),
            child: const Text('DIGITAL VAULT',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 2.0)),
          ),
          const SizedBox(height: 6),
          Text('AUTHENTICATED ASSET MANAGEMENT // LAYER 2 PROTOCOL',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
          const SizedBox(height: 10),
          // Live status
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFF00FF87), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('LIVE STATUS: STABLE',
                        style: TextStyle(color: Color(0xFF00FF87), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.5), size: 18),
    );
  }

  Widget _buildSyncCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: InkWell(
        onTap: () {
          // If in a drawer/nested nav, we might need a specific way to switch tabs.
          // For now, we go back to the previous screen or pop.
          Navigator.of(context).pop();
        },
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.12), style: BorderStyle.solid),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.confirmation_num_outlined, color: Color(0xFF00FF87), size: 24),
                ),
                const SizedBox(height: 14),
                const Text('BROWSE AVAILABLE TICKETS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0)),
                const SizedBox(height: 6),
                Text('SECURE YOUR ACCESS TO THE NEXT TOURNAMENTS',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatBox(label: 'TOTAL ASSETS', value: '${_tickets.length}', color: Colors.white),
          const SizedBox(width: 8),
          _StatBox(label: 'VAULT VALUE', value: '2.4 ETH', color: const Color(0xFFFF00FF)),
          const SizedBox(width: 8),
          _StatBox(label: 'XP MULTIPLIER', value: 'X1.8', color: const Color(0xFF00BFFF)),
          const SizedBox(width: 8),
          _StatBox(label: 'VERIFICATION', value: 'S-TIER', color: Colors.white),
        ],
      ),
    );
  }
}

// ─── Ticket Theme Data ────────────────────────────────────────────────────
class _TicketTheme {
  final String badge;
  final Color accent;
  final String titleTop;
  final String titleHighlight;
  final String gate;
  final String section;
  final String seat;
  final String matchup;
  final String date;
  const _TicketTheme(this.badge, this.accent, this.titleTop, this.titleHighlight,
      this.gate, this.section, this.seat, this.matchup, this.date);
}

// ─── Neon Command Split Card ──────────────────────────────────────────────
class _NeonCommandCard extends StatelessWidget {
  final TicketModel ticket;
  final _TicketTheme theme;
  final int index;

  const _NeonCommandCard({required this.ticket, required this.theme, required this.index});

  /// Determine QR data string to display.
  /// Backend qrCode is a base64 data URL — we show ticketNumber as QR data instead.
  String _qrData() {
    final q = ticket.qrCode;
    if (q.startsWith('data:image') || q.startsWith('iVBOR')) {
      return ticket.ticketNumber.isNotEmpty ? ticket.ticketNumber : ticket.id;
    }
    return q.isNotEmpty ? q : ticket.ticketNumber;
  }

  /// True if qrCode is a base64 image we can show as a network image.
  bool get _hasBase64Image {
    return ticket.qrCode.startsWith('data:image');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111411),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: theme.accent.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Main split row
          SizedBox(
            height: 260,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── LEFT: Protocol Core ─────────────────────────
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge row
                        Row(
                          children: [
                            // Badge: ticket type
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.accent.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                ticket.typeRaw.toUpperCase(),
                                style: TextStyle(
                                    color: theme.accent,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: ticket.isValid
                                    ? theme.accent.withOpacity(0.15)
                                    : Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                ticket.status,
                                style: TextStyle(
                                    color: ticket.isValid ? theme.accent : Colors.red,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900),
                              ),
                            ),
                            if (ticket.isNFT) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.token, size: 8, color: Colors.amber),
                                    SizedBox(width: 4),
                                    Text(
                                      'NFT',
                                      style: TextStyle(
                                          color: Colors.amber,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Accent line
                        Container(width: 28, height: 2, color: theme.accent),
                        const SizedBox(height: 16),
                        // Title: tournament name (real data)
                        Text(
                          ticket.eventName.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.5),
                        ),
                        // Ticket number in accent color
                        Text(
                          ticket.ticketNumber.isNotEmpty
                              ? ticket.ticketNumber
                              : '#${ticket.id.length > 8 ? ticket.id.substring(ticket.id.length - 8) : ticket.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: theme.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 22),
                        // Price / Type info row
                        Row(
                          children: [
                            _InfoCol(label: 'TYPE', value: ticket.typeRaw.toUpperCase()),
                            const SizedBox(width: 20),
                            _InfoCol(label: 'PRICE', value: '\$${ticket.price.toStringAsFixed(0)}'),
                            const SizedBox(width: 20),
                            _InfoCol(
                              label: 'STATUS',
                              value: ticket.status.length > 4
                                  ? ticket.status.substring(0, 4)
                                  : ticket.status,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Event date line
                        Row(
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.accent.withOpacity(0.2),
                                border: Border.all(color: theme.accent.withOpacity(0.4), width: 1),
                              ),
                              child: Icon(Icons.event, size: 10, color: theme.accent),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${ticket.eventDateTime.day.toString().padLeft(2, '0')}/'
                              '${ticket.eventDateTime.month.toString().padLeft(2, '0')}/'
                              '${ticket.eventDateTime.year}',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // ─── Vertical divider with dots ─────────────────
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top notch
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Dashed vertical line
                    ...List.generate(8, (_) => Container(
                      width: 1, height: 8,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: Colors.white.withOpacity(0.1),
                    )),
                    // Bottom notch
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                // ─── RIGHT: Encryption Core ─────────────────────
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // QR Code framed
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1A0D),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: theme.accent.withOpacity(0.2), width: 2),
                          ),
                          child: _hasBase64Image
                              ? Image.memory(
                                  base64Decode(ticket.qrCode.split(',').last),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : QrImageView(
                                  data: _qrData(),
                                  version: QrVersions.auto,
                                  size: 100.0,
                                  foregroundColor: theme.accent.withOpacity(0.7),
                                  backgroundColor: Colors.transparent,
                                ),
                        ),
                        const SizedBox(height: 14),
                        Text('SCAN AT PORTAL',
                            style: TextStyle(
                                color: theme.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Text(
                          'TOKEN_ID #${ticket.id.length > 6 ? ticket.id.substring(ticket.id.length - 6).toUpperCase() : ticket.id.toUpperCase()}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.25),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Column (GATE / SECTION / SEAT) ──────────────────────────────────
class _InfoCol extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3)),
      ],
    );
  }
}

// ─── Stat Box (bottom) ────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Vault ──────────────────────────────────────────────────────────
class _EmptyVault extends StatelessWidget {
  const _EmptyVault();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 16),
            const Text('VAULT EMPTY',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3)),
            const SizedBox(height: 8),
            Text('No authenticated assets detected',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Hex Grid Background Painter ──────────────────────────────────────────
class _HexGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const double hexSize = 30;
    final double w = hexSize * 2;
    final double h = hexSize * sqrt(3);

    for (double y = -h; y < size.height + h; y += h) {
      for (double x = -w; x < size.width + w; x += w * 1.5) {
        final offsetY = ((x / (w * 1.5)).round() % 2 == 0) ? 0.0 : h / 2;
        _drawHex(canvas, Offset(x, y + offsetY), hexSize, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * pi / 180;
      final x = center.dx + size * cos(angle);
      final y = center.dy + size * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
