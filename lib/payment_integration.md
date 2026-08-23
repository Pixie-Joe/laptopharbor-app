Stripe client integration guide (scaffolding)

This file contains safe, copy-paste-ready scaffolding and instructions to wire the Flutter client to the Stripe stub server (backend-server/).

1) Add dependency (already added to pubspec.yaml):
   dependencies:
     flutter_stripe: ^10.0.0
     http: ^0.13.6

2) Initialize Stripe in main.dart (provide your publishable key at runtime):

// import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe with publishable key -- DO NOT include secret keys in the app
  // Stripe.publishableKey should be set to your test publishable key
  // Example: Stripe.publishableKey = 'pk_test_...';
  // Obtain this from a secure config or environment at runtime.
  // Stripe.instance.applySettings(); // call if needed depending on package version

  runApp(const MyApp());
}

3) Client flow to charge via backend (example implementation outline):

// Example function (requires 'http' and 'flutter_stripe')
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';

Future<PaymentResult> processStripePayment(double amount) async {
  // 1. Ask your backend to create a PaymentIntent
  final resp = await http.post(Uri.parse('http://10.0.2.2:4242/create-payment-intent'),
      headers: {'Content-Type': 'application/json'}, body: jsonEncode({'amount': amount, 'currency': 'usd'}));

  if (resp.statusCode != 200) {
    return PaymentResult(success: false, transactionId: '', message: 'Failed to create PaymentIntent on backend');
  }

  final body = jsonDecode(resp.body) as Map<String, dynamic>;
  final clientSecret = body['clientSecret'] as String?;
  if (clientSecret == null) return PaymentResult(success: false, transactionId: '', message: 'No client secret received');

  try {
    // 2. Initialize payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'LaptopHarbor (Test)'
      ),
    );

    // 3. Present the payment sheet
    await Stripe.instance.presentPaymentSheet();

    // On success the sheet completes and you can return success.
    return PaymentResult(success: true, transactionId: clientSecret, message: 'Payment succeeded');
  } catch (e) {
    // Handle errors (user cancellation, network errors)
    return PaymentResult(success: false, transactionId: '', message: e.toString());
  }
}

4) Notes and device emulators
- If testing on Android emulator, use http://10.0.2.2:4242 as the backend URL to reach your host machine.
- For iOS simulator use http://localhost:4242.

5) Security
- Never put STRIPE_SECRET_KEY in the mobile app. Use server-side environment variables.
- Verify payments server-side and use webhooks to confirm final payment status before fulfilling orders.

6) Running the backend stub
- cd backend-server
- npm install
- Create .env with STRIPE_SECRET_KEY=sk_test_...
- npm start

If you want, I can add the client code directly into the app (imports and working code) now. This will add flutter_stripe imports — after that you'll need to run `flutter pub get` locally before building or testing.