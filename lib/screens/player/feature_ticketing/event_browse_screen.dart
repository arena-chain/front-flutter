import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/api/feature_ticketing/ticketing_api.dart';
import 'package:arena_chain_flutter/core/models/feature_ticketing/ticketing_models.dart';
import 'package:arena_chain_flutter/screens/player/feature_ticketing/event_details_screen.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class EventBrowseScreen extends StatefulWidget {
  final String? leagueId;
  const EventBrowseScreen({super.key, this.leagueId});

  @override
  State<EventBrowseScreen> createState() => _EventBrowseScreenState();
}

class _EventBrowseScreenState extends State<EventBrowseScreen> {
  final _api = TicketingApi();
  List<EventModel> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final list = await _api.getEvents(widget.leagueId ?? '');
      if (mounted) setState(() => _events = list);
    } catch (e) {
      // Error handles
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060606),
      body: Stack(
        children: [
          // Hex Background
          Positioned.fill(
            child: CustomPaint(
              painter: _HexGridPainter(),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                
                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadEvents,
                    color: const Color(0xFF00FF87),
                    backgroundColor: const Color(0xFF111111),
                    child: _loading 
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)))
                      : _events.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                            itemCount: _events.length + 1, // +1 for the search bar
                            itemBuilder: (context, index) {
                              if (index == 0) return _buildSearchSection();
                              return _ProtocolEventCard(
                                event: _events[index - 1],
                                index: index - 1,
                              );
                            },
                          ),
                  ),
                ),

                // BOTTOM ACTION BAR
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('QUEUE STATUS', style: TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold)),
                            Text('PROCEED TO CHECKOUT', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF87),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shopping_cart, color: Colors.black, size: 18),
                        ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF87).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00FF87), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text('SYSTEM ONLINE: LIVE EVENTS', 
                  style: TextStyle(color: Color(0xFF00FF87), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'GET YOUR\nTICKETS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -2,
              height: 0.9,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Access the arena through decentralized protocol authentication. Your seat is waiting.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE OPERATIONS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'LIVE // GRID',
                style: TextStyle(
                  color: const Color(0xFF00FF87).withOpacity(0.5),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const TextField(
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            icon: Icon(Icons.search, color: Colors.white24, size: 18),
            hintText: 'ENCRYPTED SEARCH...',
            hintStyle: TextStyle(color: Colors.white10, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.terminal_outlined, size: 48, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          const Text(
            'NO PROTOCOLS DETECTED',
            style: TextStyle(color: Colors.white12, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  const _HeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Icon(icon, color: Colors.white38, size: 18),
    );
  }
}

class _ProtocolEventCard extends StatelessWidget {
  final EventModel event;
  final int index;
  const _ProtocolEventCard({required this.event, required this.index});

  @override
  Widget build(BuildContext context) {
    final accentColors = [const Color(0xFF00FF87), const Color(0xFF00EEFF), const Color(0xFFFF00FF)];
    final accent = accentColors[index % accentColors.length];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Area
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: event.imageUrl != null
                      ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                      : Container(color: Colors.white.withOpacity(0.05)),
                ),
                // Status Badge
                Positioned(
                  top: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('VALID', 
                      style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.location.toUpperCase()} // LIVE DATA',
                    style: TextStyle(
                      color: accent.withOpacity(0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // GRID Stats
                  Row(
                    children: [
                      _StatBox(label: 'GATE', value: 'A-0${index + 1}'),
                      const SizedBox(width: 12),
                      _StatBox(label: 'SECTION', value: 'ELITE-${index + 1}'),
                      const SizedBox(width: 12),
                      _StatBox(label: 'TIER', value: 'ULTRA'),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // BUY BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => EventDetailsScreen(event: event))
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ACQUIRE PASS',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white24, fontSize: 7, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 10, color: Colors.white12),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
      ..strokeWidth = 1.0;

    const hexRadius = 30.0;
    final hexWidth = hexRadius * math.sqrt(3);
    final hexHeight = hexRadius * 2;

    for (double y = 0; y < size.height + hexHeight; y += hexHeight * 0.75) {
      final bool isOdd = (y / (hexHeight * 0.75)).round() % 2 != 0;
      final double xOffset = isOdd ? hexWidth / 2 : 0;
      for (double x = -hexWidth; x < size.width + hexWidth; x += hexWidth) {
        _drawHex(canvas, Offset(x + xOffset, y), hexRadius, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = math.pi / 3 * i - math.pi / 6;
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
