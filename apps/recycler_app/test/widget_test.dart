// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recycler_app/main.dart';

void main() {
  testWidgets('Basic smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RecyclerApp());

    // Verify that our app shows the login screen (or loading screen).
    // Note: Since RecyclerApp uses Providers, you might need to wrap it in MultiProvider 
    // or provide mocks if this test fails due to missing providers.
    expect(find.text('Recycler Login'), findsOneWidget);
    expect(find.text('Welcome to GreenLoop Recycler'), findsOneWidget);
  });
}
