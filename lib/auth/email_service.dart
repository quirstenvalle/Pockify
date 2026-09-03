import 'auth_repository.dart';

/// Abstraction for sending verification emails.
/// Swap [DemoEmailService] for a Laravel/SMTP/Supabase implementation later
/// without changing auth UI or verification logic.
abstract class EmailService {
  Future<void> sendVerificationCode({
    required String toEmail,
    required String toName,
    required String code,
    required Duration expiresIn,
  });
}

/// Local/demo email delivery — no API keys in the client.
/// Stores the latest code in a demo mailbox for testing only.
class DemoEmailService implements EmailService {
  DemoEmailService({AuthRepository? repository})
    : _repository = repository ?? AuthRepository.instance;

  final AuthRepository _repository;

  @override
  Future<void> sendVerificationCode({
    required String toEmail,
    required String toName,
    required String code,
    required Duration expiresIn,
  }) async {
    // Simulate network latency for loading states.
    await Future<void>.delayed(const Duration(milliseconds: 650));
    await _repository.setDemoMailboxCode(toEmail, code);
    // In production this would call a backend endpoint that sends email
    // with SMTP / Resend / Supabase — never with keys in the Flutter app.
  }
}
