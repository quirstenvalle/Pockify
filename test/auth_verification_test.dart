import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/api/api_config.dart';
import 'package:flutter_app/auth/auth_models.dart';
import 'package:flutter_app/auth/auth_repository.dart';
import 'package:flutter_app/auth/auth_service.dart';
import 'package:flutter_app/auth/email_service.dart';

class _RecordingEmailService implements EmailService {
  final sent = <String>[];

  @override
  Future<void> sendVerificationCode({
    required String toEmail,
    required String toName,
    required String code,
    required Duration expiresIn,
  }) async {
    sent.add(code);
    await AuthRepository.instance.setDemoMailboxCode(toEmail, code);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService auth;
  late _RecordingEmailService mail;

  setUp(() async {
    ApiConfig.backend = AuthBackend.local;
    SharedPreferences.setMockInitialValues({});
    mail = _RecordingEmailService();
    auth = AuthService(emailService: mail);
  });

  tearDown(() {
    ApiConfig.backend = AuthBackend.supabase;
  });

  test('register requires verification and stores hashed otp', () async {
    final result = await auth.register(
      name: 'Mark Santos',
      email: 'mark@example.com',
      password: 'Password1!',
      currency: 'PHP (₱)',
      employmentStatus: 'Student',
    );

    expect(result.requiresVerification, isTrue);
    expect(result.demoCode, isNotNull);
    expect(result.demoCode!.length, 6);
    expect(mail.sent, isNotEmpty);

    final user = await AuthRepository.instance.findByEmail('mark@example.com');
    expect(user, isNotNull);
    expect(user!.emailVerified, isFalse);
    expect(user.passwordHash, isNot(equals('Password1!')));
  });

  test('unverified login is blocked and redirects to verification', () async {
    await auth.register(
      name: 'Mark Santos',
      email: 'mark@example.com',
      password: 'Password1!',
      currency: 'PHP (₱)',
      employmentStatus: 'Student',
    );

    final login = await auth.login(
      email: 'mark@example.com',
      password: 'Password1!',
    );

    expect(login.ok, isFalse);
    expect(login.failureCode, AuthFailureCode.emailUnverified);
    expect(login.requiresVerification, isTrue);
  });

  test('correct otp verifies email and allows login', () async {
    final registered = await auth.register(
      name: 'Mark Santos',
      email: 'mark@example.com',
      password: 'Password1!',
      currency: 'PHP (₱)',
      employmentStatus: 'Student',
    );

    final verified = await auth.verifyEmail(
      email: 'mark@example.com',
      code: registered.demoCode!,
    );
    expect(verified.ok, isTrue);
    expect(verified.user!.emailVerified, isTrue);

    final login = await auth.login(
      email: 'mark@example.com',
      password: 'Password1!',
    );
    expect(login.ok, isTrue);
  });

  test('incorrect otp returns error and limits attempts', () async {
    await auth.register(
      name: 'Mark Santos',
      email: 'mark@example.com',
      password: 'Password1!',
      currency: 'PHP (₱)',
      employmentStatus: 'Student',
    );

    for (var i = 0; i < AuthService.maxVerifyAttempts - 1; i++) {
      final wrong = await auth.verifyEmail(
        email: 'mark@example.com',
        code: '000000',
      );
      expect(wrong.failureCode, AuthFailureCode.invalidCode);
    }

    final locked = await auth.verifyEmail(
      email: 'mark@example.com',
      code: '000000',
    );
    expect(locked.failureCode, AuthFailureCode.tooManyAttempts);
  });

  test('already verified account can sign in', () async {
    final registered = await auth.register(
      name: 'Mark Santos',
      email: 'verified@example.com',
      password: 'Password1!',
      currency: 'PHP (₱)',
      employmentStatus: 'Student',
    );
    await auth.verifyEmail(
      email: 'verified@example.com',
      code: registered.demoCode!,
    );

    final login = await auth.login(
      email: 'verified@example.com',
      password: 'Password1!',
    );
    expect(login.ok, isTrue);
    expect(login.user!.emailVerified, isTrue);
  });

  test('expired otp is rejected', () async {
    final registered = await auth.register(
      name: 'Mark Santos',
      email: 'expired@example.com',
      password: 'Password1!',
      currency: 'PHP (₱)',
      employmentStatus: 'Student',
    );

    final challenge = await AuthRepository.instance.getChallenge(
      'expired@example.com',
    );
    await AuthRepository.instance.saveChallenge(
      challenge!.copyWith(
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );

    final result = await auth.verifyEmail(
      email: 'expired@example.com',
      code: registered.demoCode!,
    );
    expect(result.failureCode, AuthFailureCode.expiredCode);
  });
}
