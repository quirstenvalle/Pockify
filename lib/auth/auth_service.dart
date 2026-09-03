import '../api/api_config.dart';
import '../api/laravel_auth_client.dart';
import '../api/supabase_auth_client.dart';
import 'auth_models.dart';
import 'auth_repository.dart';
import 'email_service.dart';

class AuthService {
  AuthService({
    AuthRepository? repository,
    EmailService? emailService,
    LaravelAuthClient? laravelClient,
    SupabaseAuthClient? supabaseClient,
  }) : _repository = repository ?? AuthRepository.instance,
       _emailService = emailService ?? DemoEmailService(),
       _laravel = laravelClient ?? LaravelAuthClient(),
       _supabase = supabaseClient ?? SupabaseAuthClient();

  static final AuthService instance = AuthService();

  final AuthRepository _repository;
  final EmailService _emailService;
  final LaravelAuthClient _laravel;
  final SupabaseAuthClient _supabase;

  static const otpLength = 6;
  static const otpTtl = Duration(minutes: 10);
  static const maxVerifyAttempts = 5;
  static const resendCooldown = Duration(seconds: 30);

  bool get _useSupabase => ApiConfig.useSupabase;
  bool get _useLaravel => ApiConfig.useLaravel;

  Future<AuthUser?> currentUser() async {
    final email = await _repository.getSessionEmail();
    if (email == null) return null;
    return _repository.findByEmail(email);
  }

  /// Restores a signed-in session after app restart.
  Future<AuthUser?> restoreSession() async {
    if (_useSupabase) {
      final result = await _supabase.me();
      if (result.ok && result.user != null && result.user!.emailVerified) {
        await _persistRemoteResult(result);
        return result.user;
      }
      await _repository.clearSession();
      return null;
    }

    if (_useLaravel) {
      final token = await _repository.getAuthToken();
      if (token == null || token.isEmpty) {
        await _repository.clearSession();
        return null;
      }

      final result = await _laravel.me(token);
      if (result.ok && result.user != null && result.user!.emailVerified) {
        await _persistRemoteResult(result);
        return result.user;
      }

      await _repository.clearSession();
      return null;
    }

    final user = await currentUser();
    if (user == null || !user.emailVerified) {
      await _repository.clearSession();
      return null;
    }
    return user;
  }

  Future<void> logout() async {
    if (_useSupabase) {
      await _supabase.logout();
    } else if (_useLaravel) {
      final token = await _repository.getAuthToken();
      await _laravel.logout(token);
    }
    await _repository.clearSession();
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? currency,
    String? employmentStatus,
    DateTime? birthDate,
    double? monthlyIncome,
    double? monthlyBudgetGoal,
  }) async {
    if (_useSupabase) {
      final result = await _supabase.register(
        name: name,
        email: email,
        password: password,
        currency: currency,
        employmentStatus: employmentStatus,
        birthDate: birthDate,
        monthlyIncome: monthlyIncome,
        monthlyBudgetGoal: monthlyBudgetGoal,
      );
      return _persistRemoteResult(result);
    }

    if (_useLaravel) {
      final result = await _laravel.register(
        name: name,
        email: email,
        password: password,
        currency: currency,
        employmentStatus: employmentStatus,
      );
      return _persistRemoteResult(result);
    }

    final normalized = email.trim().toLowerCase();
    final existing = await _repository.findByEmail(normalized);
    if (existing != null) {
      return AuthResult.failure(
        AuthFailureCode.emailTaken,
        'An account with this email already exists. Sign in instead.',
      );
    }

    final salt = SecureHashing.randomSalt();
    final user = AuthUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      email: normalized,
      passwordHash: SecureHashing.hash(password, salt),
      passwordSalt: salt,
      emailVerified: false,
      currency: currency,
      employmentStatus: employmentStatus,
      birthDate: birthDate,
      monthlyIncome: monthlyIncome,
      monthlyBudgetGoal: monthlyBudgetGoal,
      createdAt: DateTime.now(),
    );

    await _repository.upsertUser(user);
    final send = await _issueAndSendCode(user);
    return AuthResult.failure(
      AuthFailureCode.emailUnverified,
      'Account created. Please verify your email to continue.',
      requiresVerification: true,
      demoCode: send.demoCode,
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (_useSupabase) {
      final result = await _supabase.login(email: email, password: password);
      return _persistRemoteResult(result);
    }

    if (_useLaravel) {
      final result = await _laravel.login(email: email, password: password);
      return _persistRemoteResult(result);
    }

    final normalized = email.trim().toLowerCase();
    final user = await _repository.findByEmail(normalized);
    if (user == null ||
        !SecureHashing.matches(password, user.passwordSalt, user.passwordHash)) {
      return AuthResult.failure(
        AuthFailureCode.invalidCredentials,
        'Incorrect email or password.',
      );
    }

    if (!user.emailVerified) {
      final send = await resendVerificationCode(email: normalized);
      return AuthResult.failure(
        AuthFailureCode.emailUnverified,
        'Your email is not verified yet. We sent a new verification code.',
        requiresVerification: true,
        demoCode: send.demoCode,
      );
    }

    await _repository.setSessionEmail(user.email);
    return AuthResult.success(user);
  }

  Future<AuthResult> resendVerificationCode({
    required String email,
    String? name,
  }) async {
    if (_useSupabase) {
      final result = await _supabase.resendCode(email: email);
      return _persistRemoteResult(result);
    }

    if (_useLaravel) {
      final result = await _laravel.resendCode(email: email);
      return _persistRemoteResult(result);
    }

    final normalized = email.trim().toLowerCase();
    final user = await _repository.findByEmail(normalized);
    if (user == null) {
      return AuthResult.failure(
        AuthFailureCode.emailNotFound,
        'No account found for that email.',
      );
    }
    if (user.emailVerified) {
      return AuthResult.success(user);
    }

    final existing = await _repository.getChallenge(normalized);
    if (existing?.lastSentAt != null) {
      final wait = resendCooldown - DateTime.now().difference(existing!.lastSentAt!);
      if (wait > Duration.zero) {
        return AuthResult.failure(
          AuthFailureCode.resendCooldown,
          'Please wait ${wait.inSeconds}s before requesting another code.',
          requiresVerification: true,
        );
      }
    }

    return _issueAndSendCode(user.copyWith(name: name ?? user.name));
  }

  Future<AuthResult> updatePendingEmail({
    required String currentEmail,
    required String newEmail,
  }) async {
    if (_useSupabase) {
      final result = await _supabase.changeEmail(
        currentEmail: currentEmail,
        newEmail: newEmail,
      );
      return _persistRemoteResult(result);
    }

    if (_useLaravel) {
      final result = await _laravel.changeEmail(
        currentEmail: currentEmail,
        newEmail: newEmail,
      );
      return _persistRemoteResult(result);
    }

    final current = currentEmail.trim().toLowerCase();
    final next = newEmail.trim().toLowerCase();
    if (current == next) {
      return resendVerificationCode(email: current);
    }

    final user = await _repository.findByEmail(current);
    if (user == null) {
      return AuthResult.failure(
        AuthFailureCode.emailNotFound,
        'No account found for that email.',
      );
    }

    final taken = await _repository.findByEmail(next);
    if (taken != null) {
      return AuthResult.failure(
        AuthFailureCode.emailTaken,
        'That email is already in use.',
      );
    }

    final updated = user.copyWith(email: next, emailVerified: false);
    await _repository.upsertUser(updated);
    await _repository.clearChallenge(current);
    await _repository.clearDemoMailboxCode(current);
    return _issueAndSendCode(updated);
  }

  Future<AuthResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    if (_useSupabase) {
      final result = await _supabase.verifyEmail(email: email, code: code);
      return _persistRemoteResult(result);
    }

    if (_useLaravel) {
      final result = await _laravel.verifyEmail(email: email, code: code);
      return _persistRemoteResult(result);
    }

    final normalized = email.trim().toLowerCase();
    final user = await _repository.findByEmail(normalized);
    if (user == null) {
      return AuthResult.failure(
        AuthFailureCode.emailNotFound,
        'No account found for that email.',
      );
    }

    if (user.emailVerified) {
      await _repository.setSessionEmail(user.email);
      return AuthResult.success(user);
    }

    final challenge = await _repository.getChallenge(normalized);
    if (challenge == null) {
      return AuthResult.failure(
        AuthFailureCode.expiredCode,
        'No active verification code. Please request a new one.',
        requiresVerification: true,
      );
    }

    if (challenge.attempts >= maxVerifyAttempts) {
      return AuthResult.failure(
        AuthFailureCode.tooManyAttempts,
        'Too many incorrect attempts. Request a new verification code.',
        requiresVerification: true,
      );
    }

    if (challenge.isExpired) {
      return AuthResult.failure(
        AuthFailureCode.expiredCode,
        'This verification code has expired. Request a new one.',
        requiresVerification: true,
      );
    }

    final trimmedCode = code.trim();
    if (trimmedCode.length != otpLength ||
        !RegExp(r'^\d+$').hasMatch(trimmedCode) ||
        !SecureHashing.matches(
          trimmedCode,
          challenge.salt,
          challenge.codeHash,
        )) {
      final updated = challenge.copyWith(attempts: challenge.attempts + 1);
      await _repository.saveChallenge(updated);
      final remaining = maxVerifyAttempts - updated.attempts;
      if (remaining <= 0) {
        return AuthResult.failure(
          AuthFailureCode.tooManyAttempts,
          'Too many incorrect attempts. Request a new verification code.',
          requiresVerification: true,
        );
      }
      return AuthResult.failure(
        AuthFailureCode.invalidCode,
        'Incorrect verification code. $remaining attempt${remaining == 1 ? '' : 's'} left.',
        requiresVerification: true,
      );
    }

    final verified = user.copyWith(emailVerified: true);
    await _repository.upsertUser(verified);
    await _repository.clearChallenge(normalized);
    await _repository.clearDemoMailboxCode(normalized);
    await _repository.setSessionEmail(verified.email);
    return AuthResult.success(verified);
  }

  Future<Duration?> remainingOtpTime(String email) async {
    if (_useSupabase) {
      return _supabase.remainingOtpTime(email);
    }
    if (_useLaravel) {
      return _laravel.remainingOtpTime(email);
    }
    final challenge = await _repository.getChallenge(email);
    if (challenge == null) return null;
    if (challenge.isExpired) return Duration.zero;
    return challenge.remaining;
  }

  Future<String?> peekDemoCode(String email) =>
      _repository.getDemoMailboxCode(email);

  Future<AuthResult> _persistRemoteResult(AuthResult result) async {
    if (result.user != null) {
      await _repository.upsertUser(result.user!);
      if (result.ok || result.user!.emailVerified) {
        await _repository.setSessionEmail(result.user!.email);
      }
    }
    if (result.token != null) {
      await _repository.setAuthToken(result.token);
    }
    if (result.demoCode != null && result.user != null) {
      await _repository.setDemoMailboxCode(result.user!.email, result.demoCode!);
    }
    return result;
  }

  Future<AuthResult> _issueAndSendCode(AuthUser user) async {
    final code = SecureHashing.generateOtp(length: otpLength);
    final salt = SecureHashing.randomSalt();
    final now = DateTime.now();
    final challenge = EmailVerificationChallenge(
      email: user.email,
      codeHash: SecureHashing.hash(code, salt),
      salt: salt,
      expiresAt: now.add(otpTtl),
      createdAt: now,
      attempts: 0,
      lastSentAt: now,
    );

    await _repository.saveChallenge(challenge);
    await _emailService.sendVerificationCode(
      toEmail: user.email,
      toName: user.name,
      code: code,
      expiresIn: otpTtl,
    );

    return AuthResult.failure(
      AuthFailureCode.emailUnverified,
      'We\'ve sent a verification code to your email address.',
      requiresVerification: true,
      demoCode: code,
    );
  }
}
