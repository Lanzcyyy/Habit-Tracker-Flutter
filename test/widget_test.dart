import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dart_project/app/app.dart';

void main() {
  testWidgets('shows sign in page on startup without session', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const HabitTrackerApp());

    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Need an account? Sign up'), findsOneWidget);
  });
}
