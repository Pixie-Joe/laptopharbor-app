// Centralized compile-time app configuration.
// Values are populated via --dart-define at build/run time.

class AppConfig {
  /// Example usage:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4242 --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...

  static const String apiBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:4242');
  static const String stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');
}
