// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Stripe publishable key at runtime. Do NOT commit secret keys.
  // For local testing you can pass --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...
  const publishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');
  if (publishableKey.isNotEmpty) {
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  } else {
    // No publishable key provided — payments will fall back to the existing stub.
    // This is intentional for safety in CI / test environments.
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  // Access theme state from anywhere
  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaptopHarbor',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF00B4D8),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        cardColor: Colors.white,
        dividerColor: Colors.grey.shade300,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
          titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        useMaterial3: true,
      ),

      home: const WelcomeScreen(),
    );
  }
}