// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:flutter_app/finance_app.dart';

void main() {
  testWidgets('Finance app loads dashboard content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FinanceApp());

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'mark@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'Password1!');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Current balance'), findsOneWidget);
  });
}
