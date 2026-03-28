import 'package:flutter/material.dart';
import 'widgets/live_chat_widget.dart';

class LiveStreamScreen extends StatelessWidget {
  const LiveStreamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Section: Video Stream (Flex 1 for smaller view, or fixed height)
            Flexible(
              flex: 4, // 40% of screen approx
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://cdn.midjourney.com/f7d39ccf-863a-4a6c-b4db-540292723652/0_1.png', // Modern gaming setup
                    fit: BoxFit.cover,
                  ),
                  // Overlay Controls
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Viewers alignment
                   Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('1.2K Watching', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 2. Bottom Section: Chat (Flex 5 for larger chat area)
            Flexible(
              flex: 5, 
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0E1A), // Dark background for chat
                  border: Border(
                    top: BorderSide(color: Colors.white12, width: 1),
                  ),
                ),
                child: const LiveChatWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
