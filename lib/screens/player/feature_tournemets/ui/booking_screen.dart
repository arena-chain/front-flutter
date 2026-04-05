import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final TournamentModel tournament;

  const BookingScreen({super.key, required this.tournament});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _ticketCount = 1;

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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

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
                ),
                child: const Text(
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
