import 'dart:async';

class PaymentResult {
  final bool success;
  final String transactionId;
  final String message;

  PaymentResult({required this.success, required this.transactionId, this.message = ''});
}

class PaymentService {
  /// Simulate processing a payment. When method == 'stripe' and the app is
  /// configured with Stripe publishable keys and a backend endpoint, replace
  /// this stub with an actual Stripe SDK flow.
  Future<PaymentResult> processPayment({required double amount, required String method}) async {
    // Simple routing by method string
    if (method.toLowerCase().contains('stripe')) {
      return await _processStripe(amount);
    }

    // Default stub behavior
    await Future.delayed(const Duration(seconds: 1));
    final txId = DateTime.now().millisecondsSinceEpoch.toString();
    return PaymentResult(success: true, transactionId: txId, message: 'Payment processed (stub)');
  }

  /// Placeholder for Stripe integration. Currently returns failure with a
  /// helpful message. To integrate:
  ///  - Add the flutter_stripe package to pubspec.yaml
  ///  - Initialize Stripe with the publishable key on app startup
  ///  - Create a PaymentIntent on a secure backend and confirm the payment
  ///    on the client using the PaymentIntent client_secret.
  Future<PaymentResult> _processStripe(double amount) async {
    // For security reasons do NOT store secret keys in the client app. A
    // server-side component is required to create PaymentIntents with a
    // Stripe secret key. This placeholder indicates where to wire the SDK.

    // Short delay to simulate attempt
    await Future.delayed(const Duration(milliseconds: 500));

    return PaymentResult(
      success: false,
      transactionId: '',
      message: 'Stripe integration not configured. Please add a backend PaymentIntent flow and initialize flutter_stripe.',
    );
  }
}
