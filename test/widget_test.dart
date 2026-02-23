import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:waygo_app/screens/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen renders without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Wrap in MaterialApp because DashboardScreen needs a Scaffold/Theme context
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    // Verify that the "Create New Trip" button is present (it's in the new header)
    expect(find.text('Create New Trip'), findsOneWidget);
  });
}
