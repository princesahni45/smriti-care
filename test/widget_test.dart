// This is a basic Flutter widget test updated for SmritiCareApp.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smriti_care/app.dart';

void main() {
  testWidgets('App smoke test — SmritiCare launches',
      (WidgetTester tester) async {
    // Build app and trigger a frame
    await tester.pumpWidget(const SmritiCareApp());
    // App should load without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
