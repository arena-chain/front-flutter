import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/view_model/tournaments_view_model.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final TournamentModel tournament;

  const BookingScreen({super.key, required this.tournament});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _ticketCount = 1;
  TicketType? _selectedTicketType;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Select the first available ticket type by default
    if (widget.tournament.ticketTypes != null && widget.tournament.ticketTypes!.isNotEmpty) {
      _selectedTicketType = widget.tournament.ticketTypes!.first;
    }
  }

  void _incrementTickets() {
    if (_ticketCount < 3) {
      setState(() {
        _ticketCount++;
      });
    }
  }

  void _decrementTickets() {
    if (_ticketCount > 1) {
      setState(() {
        _ticketCount--;
      });
    }
  }

  Future<void> _handleBooking() async {
    if (_selectedTicketType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a ticket type')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final viewModel = context.read<TournamentsViewModel>();
      final tickets = await viewModel.bookTicket(
        tournamentId: widget.tournament.id,
        ticketType: _selectedTicketType!.name,
        quantity: _ticketCount,
      );

      if (!mounted) return;

      // Navigate to success screen with the first ticket (or all if needed)
      // Assuming TicketScreen can handle one ticket for now or we update it to handle multiple
      // For now passing the tournament and count as before, but ideally pass the TicketModel
      Navigator.pushReplacementNamed(
        context,
        '/tournaments/ticket',
        arguments: {
          'tournament': widget.tournament,
          'ticketCount': _ticketCount,
          'tickets': tickets, // Pass the actual booked tickets if TicketScreen supports it
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final hasTicketTypes = widget.tournament.ticketTypes != null && widget.tournament.ticketTypes!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C08),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Tickets',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Tournament Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F36),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF333B56)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tournament.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF7A86AC), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(widget.tournament.startDate),
                        style: const TextStyle(color: Color(0xFF7A86AC)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFF7A86AC), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        widget.tournament.locationName ?? 'Online',
                        style: const TextStyle(color: Color(0xFF7A86AC)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (hasTicketTypes) ...[
              const Text(
                'Select Ticket Type',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...widget.tournament.ticketTypes!.map((type) => _buildTicketTypeOption(type)),
              const SizedBox(height: 32),
            ] else
              // Fallback if no ticket types defined (e.g. legacy data)
              const Center(
                child: Text(
                  'Standard Ticket',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

            // Ticket Counter
            const Text(
              'Select Tickets',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1221),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00FF00).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCounterButton(Icons.remove, _decrementTickets),
                  Text(
                    '$_ticketCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildCounterButton(Icons.add, _incrementTickets),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Max 3 tickets per person',
              style: TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
            ),

            const Spacer(),

            // Price Summary
            if (_selectedTicketType != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    Text(
                      '\$${(_selectedTicketType!.price * _ticketCount).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/tournaments/ticket',
                    arguments: {
                      'tournament': widget.tournament,
                      'ticketCount': _ticketCount,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: const Color(0xFF1A1F36),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypeOption(TicketType type) {
    final isSelected = _selectedTicketType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTicketType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00FF00).withOpacity(0.1) : const Color(0xFF1A1F36),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00FF00) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${type.capacity - type.sold} left',
                  style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 12),
                ),
              ],
            ),
            Text(
              '\$${type.price.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
