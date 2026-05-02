import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/core/api/tickets_api.dart';
import 'package:arena_chain_flutter/core/models/ticket_model.dart';
import 'package:arena_chain_flutter/screens/feature_auth/viewmodel/auth_viewmodel.dart';
import 'package:arena_chain_flutter/navigation.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerTicketsScreen extends StatefulWidget {
  const PlayerTicketsScreen({super.key});

  @override
  State<PlayerTicketsScreen> createState() => _PlayerTicketsScreenState();
}

class _PlayerTicketsScreenState extends State<PlayerTicketsScreen> {
  final _api = TicketsApi();
  List<TicketModel> _tickets = [];
  bool _loading = true;
  String? _error;
  String _activeTab = 'All Tickets';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) {
      setState(() { _loading = false; _error = 'User not logged in'; });
      return;
    }
    try {
      setState(() { _loading = true; _error = null; });
      final list = await _api.getMyTickets(user.id);
      if (mounted) setState(() => _tickets = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'MY TICKETS',
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        leadingWidth: 160,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _load,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00CC44)),
                ),
                child: const Icon(Icons.refresh, color: Color(0xFF00CC44), size: 18),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00CC44)))
                : _error != null
                    ? _buildError()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['All Tickets', 'Leagues', 'Season Passes'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Row(
        children: tabs.map((tab) {
          final isActive = _activeTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(20),
                  border: isActive ? null : Border.all(color: const Color(0xFF222222)),
                ),
                child: Text(
                  tab,
                  style: GoogleFonts.rajdhani(
                    color: isActive ? Colors.black : const Color(0xFF555555),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    final filtered = _tickets.where((t) {
      if (_activeTab == 'Leagues') return t.league != null;
      if (_activeTab == 'Season Passes') return t.category == TicketCategory.NFT;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No tickets found in this category',
          style: TextStyle(color: Color(0xFF333333)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _TicketCard(ticket: filtered[index]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Color(0xFF777777))),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _load,
            child: const Text('Retry', style: TextStyle(color: Color(0xFF00CC44))),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TICKET CARD
// ─────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  const _TicketCard({required this.ticket});

  bool get _isNFT => ticket.category == TicketCategory.NFT;

  Color get _accentColor => _isNFT ? const Color(0xFF7B30FF) : const Color(0xFF00CC44);
  Color get _borderColor => _isNFT ? const Color(0xFF7B30FF) : const Color(0xFF00CC44);
  Color get _bgColor => _isNFT ? const Color(0xFF0E0A1A) : const Color(0xFF0D140D);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.ticketDetails, arguments: ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Glow background
              Positioned(
                right: 0, top: 0, bottom: 0,
                width: 140,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.8, -0.6),
                      radius: 1,
                      colors: [
                        (_isNFT ? const Color(0xFF8C32FF) : const Color(0xFF00C846)).withOpacity(0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Left accent bar
              Positioned(
                left: 0, top: 0, bottom: 0,
                width: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _isNFT
                          ? [const Color(0xFFCC66FF), const Color(0xFF7B30FF)]
                          : [const Color(0xFF00FF88), const Color(0xFF00AA44)],
                    ),
                  ),
                ),
              ),
              // Watermark
              Positioned(
                right: 14, bottom: 8,
                child: Text(
                  _isNFT ? 'NFT' : 'STD',
                  style: GoogleFonts.rajdhani(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: (_isNFT ? const Color(0xFF7820FF) : const Color(0xFF00B43C)).withOpacity(0.07),
                    letterSpacing: -1,
                  ),
                ),
              ),
              // Collectible ribbon
              if (_isNFT)
                Positioned(
                  right: -26, top: 15,
                  child: Transform.rotate(
                    angle: 0.663,
                    child: Container(
                      color: const Color(0xFF2E1A4A),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                      child: Text(
                        'COLLECTIBLE',
                        style: GoogleFonts.rajdhani(
                          color: const Color(0xFFB388FF),
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              // Main content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopRow(),
                    const SizedBox(height: 10),
                    _buildSeriesLabel(),
                    _buildEventTitle(),
                    const SizedBox(height: 16),
                    _buildTearLine(),
                    const SizedBox(height: 14),
                    _buildBottomRow(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Icon(
          _isNFT ? Icons.star_outline_rounded : Icons.business_outlined,
          color: _accentColor,
          size: 13,
        ),
        const SizedBox(width: 6),
        Text(
          _isNFT ? 'SEASON PASS' : (ticket.league != null ? 'LEAGUE' : 'TOURNAMENT'),
          style: GoogleFonts.rajdhani(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
            color: _isNFT ? const Color(0xFF6A3A9A) : const Color(0xFF3A6A3A),
          ),
        ),
        const Spacer(),
        _StatusBadge(status: ticket.status, isNFT: _isNFT),
      ],
    );
  }

  Widget _buildSeriesLabel() {
    return Text(
      ticket.league != null ? 'Arena Alpha League' : 'Championship Series',
      style: GoogleFonts.rajdhani(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: _isNFT ? const Color(0xFF3A2A5A) : const Color(0xFF333333),
      ),
    );
  }

  Widget _buildEventTitle() {
    String title = 'Arena Event';
    if (ticket.league != null) title = ticket.league!.name;
    else if (ticket.tournament != null) title = ticket.tournament!.name;
    
    return Text(
      title,
      style: GoogleFonts.rajdhani(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: _isNFT ? const Color(0xFFF0E8FF) : Colors.white,
        letterSpacing: 0.5,
        height: 1.1,
      ),
    );
  }

  Widget _buildTearLine() {
    return Row(
      children: [
        Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            shape: BoxShape.circle,
            border: Border.all(color: _borderColor, width: 1.5),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: CustomPaint(painter: _DashedLinePainter(
              color: _isNFT ? const Color(0xFF2A1040) : const Color(0xFF1C3A1C),
            )),
          ),
        ),
        Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            shape: BoxShape.circle,
            border: Border.all(color: _borderColor, width: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TICKET NO.',
              style: GoogleFonts.rajdhani(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: _isNFT ? const Color(0xFF2E1A4A) : const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.ticketNumber.toUpperCase(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _isNFT ? const Color(0xFF6A3A9A) : const Color(0xFF3A6A3A),
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _showQRCode(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isNFT ? const Color(0xFF140A22) : const Color(0xFF111111),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: _isNFT ? const Color(0xFF2E1A4A) : const Color(0xFF1E3A1E),
              ),
            ),
            child: Icon(Icons.qr_code_2_rounded, color: _accentColor, size: 20),
          ),
        ),
      ],
    );
  }

  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _accentColor, width: 1.5),
        ),
        title: Text(
          'Ticket QR Code',
          style: GoogleFonts.rajdhani(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ticket.qrCode != null
                  ? Image.memory(
                      base64Decode(ticket.qrCode!.split(',').last),
                      width: 160,
                      height: 160,
                    )
                  : const Icon(Icons.qr_code_2, size: 160, color: Colors.black),
            ),
            const SizedBox(height: 14),
            Text(
              ticket.ticketNumber,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontWeight: FontWeight.w600,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '// scan to verify entry',
              style: TextStyle(color: Color(0xFF444444), fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CLOSE',
              style: TextStyle(color: _accentColor, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final TicketStatus status;
  final bool isNFT;
  const _StatusBadge({required this.status, required this.isNFT});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case TicketStatus.VALID:
        color = isNFT ? const Color(0xFFCC88FF) : const Color(0xFF00FF66);
        label = 'VALID';
        break;
      case TicketStatus.USED:
        color = Colors.orange;
        label = 'USED';
        break;
      case TicketStatus.CANCELLED:
        color = Colors.red;
        label = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DASHED LINE PAINTER
// ─────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.5;
    double x = 0;
    const dashWidth = 6.0;
    const gapWidth = 5.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
