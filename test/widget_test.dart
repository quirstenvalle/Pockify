import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/api/api_config.dart';
import 'package:flutter_app/auth/auth_repository.dart';
import 'package:flutter_app/auth/auth_service.dart';
import 'package:flutter_app/auth/email_service.dart';
import 'package:flutter_app/finance_app.dart';
import 'package:flutter_app/screens/email_verification_screen.dart';

class _FastEmailService implements EmailService {
  @override
  Future<void> sendVerificationCode({
    required String toEmail,
    required String toName,
    required String code,
    required Duration expiresIn,
  }) async {
    await AuthRepository.instance.setDemoMailboxCode(toEmail, code);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    ApiConfig.backend = AuthBackend.local;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ApiConfig.backend = AuthBackend.supabase;
  });

  testWidgets('Finance app loads dashboard content', (
    WidgetTester tester,
  ) async {
    final auth = AuthService(emailService: _FastEmailService());
    final registered = await auth.register(
      name: 'Mark',
      email: 'mark@example.com',
      password: 'Password1!',
      currency: 'PHP (₱)',
      employmentStatus: 'Student',
    );
    await auth.verifyEmail(
      email: 'mark@example.com',
      code: registered.demoCode!,
    );
    await auth.logout();

    await tester.pumpWidget(const FinanceApp());

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'mark@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'Password1!');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Current balance'), findsOneWidget);
  });

  testWidgets('Email verification screen shows OTP UI and messages', (
    WidgetTester tester,
  ) async {
    var verified = false;

    await tester.pumpWidget(
      MaterialApp(
        home: EmailVerificationScreen(
          email: 'newuser@example.com',
          initialDemoCode: '123456',
          onVerified: () => verified = true,
          onBackToAuth: () {},
        ),
      ),
    );

    expect(find.text('Verify your email'), findsOneWidget);
    expect(
      find.textContaining("We've sent a verification code"),
      findsOneWidget,
    );
    expect(find.text('Verify Email'), findsOneWidget);
    expect(find.text('Resend Code'), findsOneWidget);
    expect(find.textContaining('Demo inbox'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(verified, isFalse);
  });
}
