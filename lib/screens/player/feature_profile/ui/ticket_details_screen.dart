import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:arena_chain_flutter/core/models/ticket_model.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketDetailsScreen extends StatelessWidget {
  final TicketModel ticket;

  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isNFT = ticket.category == TicketCategory.NFT;
    final accentColor = isNFT ? const Color(0xFFA020F0) : const Color(0xFF00FF00);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ticket Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildMainCard(context, accentColor, isNFT),
            const SizedBox(height: 24),
            _buildDownloadButton(accentColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, Color accentColor, bool isNFT) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Left Accent Bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: accentColor),
            ),
            
            // Background Icon
            Positioned(
              right: -20,
              top: 40,
              child: Opacity(
                opacity: 0.03,
                child: Icon(
                  Icons.videogame_asset,
                  size: 200,
                  color: Colors.white,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Status & ID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(accentColor),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'TICKET ID',
                            style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '#${ticket.ticketNumber.toUpperCase()}',
                            style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Subtitle
                  Text(
                    'CHAMPIONSHIP SERIES',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  
                  // Title
                  Text(
                    ticket.league?.name ?? ticket.tournament?.name ?? 'Arena Event',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Info Grid
                  Row(
                    children: [
                      Expanded(child: _buildInfoItem('DATE & TIME', DateFormat('MMM dd, yyyy\nHH:mm UTC').format(ticket.purchaseDate))),
                      Expanded(child: _buildInfoItem('VENUE', 'Virtual Arena\nOnline Access')),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 24),
                  
                  _buildInfoItem('ACCESS LEVEL', 'General Admission', valueColor: accentColor),
                  
                  const SizedBox(height: 40),
                  
                  // QR Code Section
                  Center(
                    child: Column(
                      children: [
                        _buildQRCode(accentColor),
                        const SizedBox(height: 16),
                        const Text(
                          'Present this for entry',
                          style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
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

  Widget _buildStatusBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            ticket.status.name,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(color: valueColor ?? Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildQRCode(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: QrImageView(
          data: ticket.ticketNumber,
          version: QrVersions.auto,
          size: 160.0,
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        ),
      ),
    );
  }

  Widget _buildDownloadButton(Color accentColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.download, color: Colors.black),
        label: const Text(
          'Download Ticket',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}