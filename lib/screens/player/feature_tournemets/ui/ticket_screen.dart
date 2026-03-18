import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/tournament_model.dart';
import 'package:arena_chain_flutter/core/models/feature_tournaments/ticket_model.dart';
import 'package:intl/intl.dart';

class TicketScreen extends StatelessWidget {
  final TournamentModel tournament;
  final int ticketCount;
  final List<TicketModel>? tickets;

  const TicketScreen({
    super.key,
    required this.tournament,
    required this.ticketCount,
    this.tickets,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    // Default location if none provided (e.g., Paris)
    final LatLng eventLocation = LatLng(
      tournament.latitude ?? 48.8566,
      tournament.longitude ?? 2.3522,
    );

    // Use the first ticket's QR code if available, otherwise fallback
    final String qrData = (tickets != null && tickets!.isNotEmpty)
        ? tickets!.first.qrCode
        : 'TICKET:${tournament.id}:COUNT:$ticketCount';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C08),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: const Text(
          'Your Ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Ticket Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Event Details
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          tournament.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateFormat.format(tournament.startDate),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // QR Code
                        if (qrData.startsWith('data:image'))
                           _buildBase64Image(qrData)
                        else
                          QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),

                        const SizedBox(height: 16),
                        Text(
                          '$ticketCount Entry Ticket${ticketCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (tickets != null && tickets!.isNotEmpty)
                           Padding(
                             padding: const EdgeInsets.only(top: 8.0),
                             child: Text(
                               'Type: ${tickets!.first.type}',
                               style: const TextStyle(
                                 color: Colors.grey,
                                 fontSize: 14,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ),
                      ],
                    ),
                  ),
                  
                  // Dashed Line
                  Row(
                    children: List.generate(
                      20 ~/ 0.6,
                      (index) => Expanded(
                        child: Container(
                          color: index % 2 == 0 ? Colors.transparent : Colors.grey[300],
                          height: 2,
                        ),
                      ),
                    ),
                  ),

                  // Location Map
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tournament.locationName ?? 'Location details not available',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: eventLocation,
                                initialZoom: 15.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.arena_chain_flutter',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: eventLocation,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
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
            ),
            
            const SizedBox(height: 24),
            
            // Download Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Todo: Implement save to gallery
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00FF00),
                  side: const BorderSide(color: Color(0xFF00FF00)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.download),
                label: const Text('Save to Gallery'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBase64Image(String base64String) {
    try {
      // Remove header if present (e.g., "data:image/png;base64,")
      final String pureBase64 = base64String.split(',').last;
      return Image.memory(
        base64Decode(pureBase64),
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
           return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
        },
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
    }
  }
}
