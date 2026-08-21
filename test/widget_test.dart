import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_mind/main.dart';

void main() {
  testWidgets('LocalMind app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LocalMindApp());

    // Wait for splash screen to complete (3 seconds delay + transition)
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify that the title "LocalMind" is displayed in the AppBar.
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('LocalMind')), findsOneWidget);

    // Verify that 3 bottom navigation items (Models, CHAT, Settings) are present.
    expect(find.text('Models'), findsOneWidget);
    expect(find.text('CHAT'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
