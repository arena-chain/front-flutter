import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/models/feature_ticketing/ticketing_models.dart';
import 'package:arena_chain_flutter/core/api/feature_ticketing/ticketing_api.dart';
import 'package:arena_chain_flutter/core/services/payment_service.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final _api = TicketingApi();
  TournamentTicketType? _selectedTier;
  bool _purchasing = false;
  bool _loadingTiers = false;
  List<TournamentTicketType> _resolvedTiers = [];

  List<TournamentTicketType> get _tiers {
    if (_resolvedTiers.isNotEmpty) {
      return _resolvedTiers;
    }
    if (widget.event.ticketTypesList.isNotEmpty) {
      return widget.event.ticketTypesList;
    }
    // Fallback: build from prices map
    return widget.event.prices.entries.map((e) {
      return TournamentTicketType(
        name: e.key.backendName,
        price: e.value,
        capacity: 100,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _resolvedTiers = List<TournamentTicketType>.from(widget.event.ticketTypesList);
    if (_resolvedTiers.isNotEmpty) {
      _selectedTier = _resolvedTiers.first;
    }
    _loadLiveTiers();
  }

  Future<void> _loadLiveTiers() async {
    setState(() => _loadingTiers = true);
    try {
      final fromAvailable = await _api.getAvailableTickets(widget.event.id);
      final tournament = await _api.getTournamentById(widget.event.id);
      final fromTournament = <TournamentTicketType>[];
      final raw = tournament?['ticketTypes'];
      if (raw is List) {
        for (final entry in raw) {
          if (entry is Map<String, dynamic>) {
            fromTournament.add(TournamentTicketType.fromJson(entry));
          }
        }
      }

      final merged = <String, TournamentTicketType>{};
      for (final t in [...fromAvailable, ...fromTournament, ...widget.event.ticketTypesList]) {
        final key = t.name.trim().toUpperCase();
        if (key.isEmpty) continue;
        merged.putIfAbsent(key, () => t);
      }
      if (!mounted) return;
      setState(() {
        _resolvedTiers = merged.values.toList();
        if (_resolvedTiers.isNotEmpty &&
            (_selectedTier == null ||
                !_resolvedTiers.any((t) => t.name == _selectedTier!.name))) {
          _selectedTier = _resolvedTiers.first;
        }
      });
    } finally {
      if (mounted) setState(() => _loadingTiers = false);
    }
  }

  final _paymentService = PaymentService();

  void _onBuyTicket() async {
    if (_selectedTier == null) return;

    setState(() => _purchasing = true);
    try {
      // 1. Create Payment Intent
      final clientSecret = await _paymentService.createPaymentIntent(
        _selectedTier!.price, 
        'usd'
      );
      
      if (clientSecret == null) {
        throw Exception('FAILED TO INITIALIZE PAYMENT GATEWAY');
      }

      // 2. Present Payment Sheet
      final paymentSuccessful = await _paymentService.initPaymentSheet(
        clientSecret, 
        'Player' // Could be dynamic if user profile is available
      );

      if (!paymentSuccessful) {
        // User cancelled or payment failed
        return; 
      }
      
      final paymentIntentId = clientSecret.split('_secret_').first;

      // 3. If payment successful, finalize ticket on backend
      final tickets = await _api.buyTicket(
        widget.event.id, 
        _selectedTier!.name,
        paymentIntentId: paymentIntentId,
      );
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _ProtocolSuccessDialog(tierName: _selectedTier!.name),
        ).then((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'PROTOCOL INTERRUPTED: $e',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
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

          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 32),
                      _buildSpecsRow(),
                      const SizedBox(height: 32),
                      _buildAboutSection(),
                      const SizedBox(height: 40),
                      _buildTierSelection(),
                      const SizedBox(height: 120), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Buy Button
          _buildBottomAction(),

          if (_purchasing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00FF87)),
                    SizedBox(height: 24),
                    Text(
                      'ENCRYPTING TRANSACTION...',
                      style: TextStyle(
                          color: Color(0xFF00FF87),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 350,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.event.imageUrl != null)
              Image.network(widget.event.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF111111)))
            else
              Container(color: const Color(0xFF111111)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    const Color(0xFF060606),
                  ],
                ),
              ),
            ),
            // Floating Tag
            Positioned(
              bottom: 40,
              left: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF87),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'UPCOMING DEPLOYMENT',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.event.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -1.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'AUTHENTICATED EVENT PROTOCOL // GLOBAL LEDGER',
          style: TextStyle(
            color: Colors.white24,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecsRow() {
    final df = DateFormat('MMM dd, yyyy');
    return Row(
      children: [
        _SpecBox(
            icon: Icons.calendar_today,
            label: 'TIMESTAMP',
            value: df.format(widget.event.dateTime).toUpperCase()),
        const SizedBox(width: 12),
        _SpecBox(
            icon: Icons.location_on_outlined,
            label: 'GEOLOC',
            value: widget.event.location.toUpperCase()),
      ],
    );
  }

  Widget _buildAboutSection() {
    final desc = widget.event.description?.isNotEmpty == true
        ? widget.event.description!
        : 'Witness the ultimate tactical mastery at the heart of the circuit.';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DEPLOYMENT SUMMARY',
              style: TextStyle(
                  color: Color(0xFF00FF87),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text(
            desc,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.6,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildTierSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RESERVE CLEARANCE TIER',
            style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 20),
        if (_loadingTiers)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(color: Color(0xFF00FF87), minHeight: 2),
          ),
        ..._tiers.map((tier) => _TierCard(
              tier: tier,
              isSelected: _selectedTier?.name == tier.name,
              onTap: () => setState(() => _selectedTier = tier),
            )),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('TOTAL_ASSET_COST',
                      style: TextStyle(
                          color: Colors.white24,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                  Text(
                    _selectedTier != null
                        ? '\$${_selectedTier!.price.toStringAsFixed(0)}'
                        : '--',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _selectedTier == null || _purchasing ? null : _onBuyTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF87),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.white.withOpacity(0.05),
                  elevation: 0,
                ).copyWith(
                  shadowColor: WidgetStateProperty.all(
                      const Color(0xFF00FF87).withOpacity(0.4)),
                ),
                child: const Text('AUTHORIZE PROTOCOL',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SpecBox({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: const Color(0xFF00FF87)),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final TournamentTicketType tier;
  final bool isSelected;
  final VoidCallback onTap;

  const _TierCard(
      {required this.tier, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enumType = TicketTypeExtension.fromBackendName(tier.name);
    final isNFT = tier.name.toLowerCase().contains('nft');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00FF87).withOpacity(0.05)
                : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00FF87).withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${tier.name.toUpperCase()} PASS',
                          style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF00FF87)
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic),
                        ),
                        if (isNFT) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.diamond_outlined,
                              color: Colors.purpleAccent, size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SECURED_ACCESS_${tier.name.toUpperCase().replaceAll(' ', '_')}  •  ${tier.capacity} SPOTS',
                      style: const TextStyle(
                          color: Colors.white10,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${tier.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: enumType.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtocolSuccessDialog extends StatelessWidget {
  final String tierName;
  const _ProtocolSuccessDialog({required this.tierName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(32),
          border:
              Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_outlined,
                color: Color(0xFF00FF87), size: 64),
            const SizedBox(height: 24),
            const Text(
              'ACCESS AUTHORIZED',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Text(
              'YOUR ${tierName.toUpperCase()} TICKET HAS BEEN SECURED.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF87),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('CLOSE PROTOCOL',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HexGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
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
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
