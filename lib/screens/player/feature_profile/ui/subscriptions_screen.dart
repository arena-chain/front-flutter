import 'package:flutter/material.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('Subscriptions', style: TextStyle(color: Colors.white)),
        leading: BackButton(color: Colors.white),
      ),
      body: const Center(
        child: Text(
          'Subscriptions Content Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
