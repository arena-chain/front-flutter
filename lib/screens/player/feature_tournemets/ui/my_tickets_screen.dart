import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/view_model/tournaments_view_model.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/ticket_model.dart';
import 'package:arena_chain_flutter/screens/player/feature_tournemets/ui/ticket_screen.dart';
import 'package:intl/intl.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch tickets on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentsViewModel>().fetchMyTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TournamentsViewModel>();
    final tickets = viewModel.myTickets;
    final isLoading = viewModel.isLoading;
    final error = viewModel.error;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C08),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Tickets',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(tickets, isLoading, error),
    );
  }

  Widget _buildBody(List<TicketModel> tickets, bool isLoading, String? error) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF00)),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading tickets',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error.replaceAll('Exception: ', ''),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<TournamentsViewModel>().fetchMyTickets();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF00),
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No tickets found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your purchased tickets will appear here.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<TournamentsViewModel>().fetchMyTickets();
      },
      color: const Color(0xFF00FF00),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return _buildTicketCard(ticket);
        },
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    
    return GestureDetector(
      onTap: () {
        // Navigate to ticket detail screen
        if (ticket.tournament != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketScreen(
                tournament: ticket.tournament!,
                ticketCount: 1,
                tickets: [ticket],
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F36),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ticket.status == 'VALID' 
                ? const Color(0xFF00FF00).withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ticket.tournament?.name ?? 'Tournament',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(ticket.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.confirmation_number, color: Color(0xFF7A86AC), size: 16),
                const SizedBox(width: 8),
                Text(
                  ticket.ticketNumber,
                  style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category, color: Color(0xFF7A86AC), size: 16),
                const SizedBox(width: 8),
                Text(
                  ticket.type,
                  style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 14),
                ),
              ],
            ),
            if (ticket.tournament != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF7A86AC), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(ticket.tournament!.startDate),
                    style: const TextStyle(color: Color(0xFF7A86AC), fontSize: 14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, color: Color(0xFF7A86AC), size: 16),
                const SizedBox(width: 8),
                Text(
                  '\$${ticket.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String displayText;

    switch (status.toUpperCase()) {
      case 'VALID':
        badgeColor = const Color(0xFF00FF00);
        displayText = 'Valid';
        break;
      case 'USED':
        badgeColor = Colors.orange;
        displayText = 'Used';
        break;
      case 'CANCELLED':
        badgeColor = Colors.red;
        displayText = 'Cancelled';
        break;
      case 'EXPIRED':
        badgeColor = Colors.grey;
        displayText = 'Expired';
        break;
      default:
        badgeColor = Colors.blue;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
