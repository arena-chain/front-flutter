import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:arena_chain_flutter/core/api/authenticated_client.dart';
import 'package:arena_chain_flutter/core/config/api_config.dart';

class PaymentService {
  final AuthenticatedClient _client = AuthenticatedClient();

  /// Create a PaymentIntent on the backend and return the clientSecret.
  Future<String?> createPaymentIntent(double amount, String currency) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/payment/create-intent');
      final response = await _client.post(
        url,
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['clientSecret'];
      } else {
        debugPrint('PaymentService: Failed to create payment intent: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('PaymentService: Error creating payment intent: $e');
      return null;
    }
  }

  /// Initialize and display the Stripe Payment Sheet.
  Future<bool> initPaymentSheet(String clientSecret, String customerName) async {
    if (kIsWeb) {
      debugPrint('PaymentService: Stripe PaymentSheet is not supported on Web. Bypassing for development.');
      // Simulating a short delay for payment processing
      await Future.delayed(const Duration(seconds: 1));
      return true; 
    }

    try {
      // 1. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Arena-Chain Esports',
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF00FF87),
              background: Color(0xFF111111),
              componentBackground: Color(0xFF222222),
              componentText: Colors.white,
              primaryText: Colors.white,
              secondaryText: Colors.white70,
              placeholderText: Colors.white24,
            ),
          ),
        ),
      );

      // 2. Display Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      return true;
    } on StripeException catch (e) {
      debugPrint('PaymentService: Stripe exception: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      debugPrint('PaymentService: Generic error: $e');
      return false;
    }
  }
}
