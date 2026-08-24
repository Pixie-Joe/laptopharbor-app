// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:laptopharbor/main.dart';

void main() {
  testWidgets('App shows Get Started on welcome screen', (WidgetTester tester) async {
    // Build the app and wait for frames
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // The welcome screen should show a "Get Started" button
    expect(find.text('Get Started'), findsOneWidget);

    // Tapping it should navigate to onboarding (which contains 'Next' or 'Skip')
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
  });
}
