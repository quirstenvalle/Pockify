import 'dart:typed_data';

import '../api/api_config.dart';
import '../api/laravel_auth_client.dart';
import '../api/profile_repository.dart';
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

  Future<void> completeWebAuthRedirect() async {
    if (_useSupabase) await _supabase.completeWebAuthRedirect();
  }

  void Function()? watchRemoteVerification(void Function() onVerified) {
    if (!_useSupabase) return null;
    var handled = false;
    final sub = _supabase.watchVerified(() async {
      if (handled) return;
      final result = await _supabase.me();
      if (!result.ok || result.user == null) return;
      handled = true;
      await _persistRemoteResult(result);
      onVerified();
    });
    return sub.cancel;
  }

  void Function()? watchPasswordRecovery(void Function() onRecovery) {
    if (!_useSupabase) return null;
    final sub = _supabase.watchPasswordRecovery(onRecovery);
    return sub.cancel;
  }

  Future<String?> updatePassword(String password) async {
    if (_useSupabase) return _supabase.updatePassword(password);
    return 'Password reset is only available when connected to Supabase.';
  }

  Future<AuthUser?> currentUser() async {
    final email = await _repository.getSessionEmail();
    if (email == null) return null;
    return _repository.findByEmail(email);
  }

  /// Restores a signed-in session after app restart.
  Future<AuthUser?> restoreSession() async {
    if (_useSupabase) {
      final result = await _supabase.me();
      if (result.ok && result.user != null) {
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
    String? country,
    String? employmentStatus,
    DateTime? birthDate,
    double? monthlyIncome,
    double? monthlyBudgetGoal,
  }) async {
    if (_useLaravel) {
      final result = await _laravel.register(
        name: name,
        email: email,
        password: password,
        currency: currency,
        country: country,
        employmentStatus: employmentStatus,
      );
      return _persistRemoteResult(result);
    }

    return _startEmailCodeSignup(
      name: name,
      email: email,
      password: password,
      currency: currency,
      country: country,
      employmentStatus: employmentStatus,
      birthDate: birthDate,
      monthlyIncome: monthlyIncome,
      monthlyBudgetGoal: monthlyBudgetGoal,
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
    bool resendIfUnverified = true,
  }) async {
    if (_useSupabase) {
      final result = await _supabase.login(
        email: email,
        password: password,
        resendIfUnverified: false,
      );
      if (result.requiresVerification ||
          result.failureCode == AuthFailureCode.emailUnverified) {
        await _repository.savePendingSignup(
          PendingSignup(
            name: result.user?.name ?? email.trim().split('@').first,
            email: email.trim().toLowerCase(),
            password: password,
            currency: result.user?.currency,
            country: result.user?.country,
            employmentStatus: result.user?.employmentStatus,
            birthDate: result.user?.birthDate,
            monthlyIncome: result.user?.monthlyIncome,
            monthlyBudgetGoal: result.user?.monthlyBudgetGoal,
          ),
        );
        final send = await _startEmailCodeSignup(
          name: result.user?.name ?? email.trim().split('@').first,
          email: email,
          password: password,
          currency: result.user?.currency,
          country: result.user?.country,
          employmentStatus: result.user?.employmentStatus,
          birthDate: result.user?.birthDate,
          monthlyIncome: result.user?.monthlyIncome,
          monthlyBudgetGoal: result.user?.monthlyBudgetGoal,
        );
        return AuthResult.failure(
          AuthFailureCode.emailUnverified,
          'Enter the 6-digit code previewed for this email to finish signing in.',
          requiresVerification: true,
          demoCode: send.demoCode,
        );
      }
      return _persistRemoteResult(result);
    }

    if (_useLaravel) {
      final result = await _laravel.login(email: email, password: password);
      return _persistRemoteResult(result);
    }

    final normalized = email.trim().toLowerCase();
    final user = await _repository.findByEmail(normalized);
    if (user == null ||
        !SecureHashing.matches(
          password,
          user.passwordSalt,
          user.passwordHash,
        )) {
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

  Future<String?> sendPasswordResetEmail(String email) async {
    if (_useSupabase) {
      return _supabase.sendPasswordResetEmail(email);
    }
    return 'Password reset email is only available when connected to Supabase.';
  }

  Future<AuthResult> signInWithGoogle() async {
    if (_useSupabase) {
      final result = await _supabase.signInWithGoogle();
      if (result.ok && result.user != null) {
        return _persistRemoteResult(result);
      }
      return result;
    }
    return AuthResult.failure(
      AuthFailureCode.invalidCredentials,
      'Google sign-in is available when the app is connected to Supabase.',
    );
  }

  Future<AuthResult> resendVerificationCode({
    required String email,
    String? name,
  }) async {
    if (_useSupabase) {
      return _resendAppCode(email: email, name: name);
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
      final wait =
          resendCooldown - DateTime.now().difference(existing!.lastSentAt!);
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
      return _updatePendingEmailLocally(
        currentEmail: currentEmail,
        newEmail: newEmail,
      );
    }

    if (_useLaravel) {
      final result = await _laravel.changeEmail(
        currentEmail: currentEmail,
        newEmail: newEmail,
      );
      return _persistRemoteResult(result);
    }

    return _updatePendingEmailLocally(
      currentEmail: currentEmail,
      newEmail: newEmail,
    );
  }

  Future<AuthResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    if (_useLaravel) {
      final result = await _laravel.verifyEmail(email: email, code: code);
      return _persistRemoteResult(result);
    }

    final matched = await _matchLocalOtp(email: email, code: code);
    if (!matched.ok) {
      return matched;
    }

    if (_useSupabase) {
      return _completeSupabaseAfterOtp(email.trim().toLowerCase());
    }

    return _consumeLocalOtp(email.trim().toLowerCase());
  }

  Future<Duration?> remainingOtpTime(String email) async {
    final challenge = await _repository.getChallenge(
      email.trim().toLowerCase(),
    );
    if (challenge != null) {
      if (challenge.isExpired) return Duration.zero;
      return challenge.remaining;
    }
    if (_useLaravel) {
      return _laravel.remainingOtpTime(email);
    }
    return null;
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
      await _repository.setDemoMailboxCode(
        result.user!.email,
        result.demoCode!,
      );
    }
    return result;
  }

  /// Updates profile fields and optional avatar image bytes.
  /// Avatar is uploaded to Storage when possible, and [profiles.avatar_url]
  /// is always written in the database.
  Future<AuthResult> updateProfile({
    required String name,
    String? currency,
    String? country,
    String? employmentStatus,
    DateTime? birthDate,
    double? monthlyIncome,
    double? monthlyBudgetGoal,
    Uint8List? avatarBytes,
    String avatarContentType = 'image/jpeg',
  }) async {
    // Prefer live Supabase user so id matches auth.uid() for RLS + Storage.
    AuthUser? current;
    if (_useSupabase) {
      final remote = await _supabase.me();
      if (remote.ok && remote.user != null) {
        current = remote.user;
        await _repository.upsertUser(current!);
      }
    }
    current ??= await currentUser();

    if (current == null) {
      return AuthResult.failure(
        AuthFailureCode.emailNotFound,
        'You need to sign in again to edit your profile.',
      );
    }

    try {
      final profiles = ProfileRepository();
      var avatarUrl = current.avatarUrl;
      if (avatarBytes != null && avatarBytes.isNotEmpty) {
        avatarUrl = await profiles.uploadAvatar(
          userId: current.id,
          bytes: avatarBytes,
          contentType: avatarContentType,
        );
      }

      final updated = await profiles.updateProfile(
        user: current,
        name: name,
        currency: currency,
        country: country,
        employmentStatus: employmentStatus,
        birthDate: birthDate,
        monthlyIncome: monthlyIncome,
        monthlyBudgetGoal: monthlyBudgetGoal,
        avatarUrl: avatarUrl,
      );

      await _repository.upsertUser(updated);
      await _repository.setSessionEmail(updated.email);
      return AuthResult.success(updated);
    } catch (error) {
      return AuthResult.failure(
        AuthFailureCode.invalidCredentials,
        'Could not save profile. $error',
      );
    }
  }

  Future<AuthResult> _startEmailCodeSignup({
    required String name,
    required String email,
    required String password,
    String? currency,
    String? country,
    String? employmentStatus,
    DateTime? birthDate,
    double? monthlyIncome,
    double? monthlyBudgetGoal,
  }) async {
    final normalized = email.trim().toLowerCase();
    final existing = await _repository.findByEmail(normalized);
    if (!_useSupabase && existing != null && existing.emailVerified) {
      return AuthResult.failure(
        AuthFailureCode.emailTaken,
        'An account with this email already exists. Sign in instead.',
      );
    }

    final salt = existing?.passwordSalt ?? SecureHashing.randomSalt();
    final user = AuthUser(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      email: normalized,
      passwordHash: SecureHashing.hash(password, salt),
      passwordSalt: salt,
      emailVerified: false,
      currency: currency,
      country: country,
      employmentStatus: employmentStatus,
      birthDate: birthDate,
      monthlyIncome: monthlyIncome,
      monthlyBudgetGoal: monthlyBudgetGoal,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    await _repository.upsertUser(user);
    await _repository.savePendingSignup(
      PendingSignup(
        name: user.name,
        email: normalized,
        password: password,
        currency: currency,
        country: country,
        employmentStatus: employmentStatus,
        birthDate: birthDate,
        monthlyIncome: monthlyIncome,
        monthlyBudgetGoal: monthlyBudgetGoal,
      ),
    );

    return _issueAndSendCode(user);
  }

  Future<AuthResult> _resendAppCode({
    required String email,
    String? name,
  }) async {
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
      final wait =
          resendCooldown - DateTime.now().difference(existing!.lastSentAt!);
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

  Future<AuthResult> _updatePendingEmailLocally({
    required String currentEmail,
    required String newEmail,
  }) async {
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

    final pending = await _repository.getPendingSignup(current);
    final updated = user.copyWith(email: next, emailVerified: false);
    await _repository.upsertUser(updated);
    await _repository.clearChallenge(current);
    await _repository.clearDemoMailboxCode(current);
    await _repository.clearPendingSignup(current);
    if (pending != null) {
      await _repository.savePendingSignup(pending.copyWith(email: next));
    }
    return _issueAndSendCode(updated);
  }

  Future<AuthResult> _matchLocalOtp({
    required String email,
    required String code,
  }) async {
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

    return AuthResult.success(user);
  }

  Future<AuthResult> _consumeLocalOtp(String email) async {
    final user = await _repository.findByEmail(email);
    if (user == null) {
      return AuthResult.failure(
        AuthFailureCode.emailNotFound,
        'No account found for that email.',
      );
    }
    final verified = user.copyWith(emailVerified: true);
    await _repository.upsertUser(verified);
    await _repository.clearChallenge(email);
    await _repository.clearDemoMailboxCode(email);
    await _repository.clearPendingSignup(email);
    await _repository.setSessionEmail(verified.email);
    return AuthResult.success(verified);
  }

  Future<AuthResult> _completeSupabaseAfterOtp(String email) async {
    final pending = await _repository.getPendingSignup(email);
    final local = await _repository.findByEmail(email);
    final password = pending?.password;
    if (password == null || password.isEmpty || local == null) {
      return AuthResult.failure(
        AuthFailureCode.invalidCode,
        'Sign up again so we can send a new code to this email.',
        requiresVerification: true,
      );
    }

    final result = await _supabase.register(
      name: pending?.name ?? local.name,
      email: email,
      password: password,
      currency: pending?.currency ?? local.currency,
      country: pending?.country ?? local.country,
      employmentStatus: pending?.employmentStatus ?? local.employmentStatus,
      birthDate: pending?.birthDate ?? local.birthDate,
      monthlyIncome: pending?.monthlyIncome ?? local.monthlyIncome,
      monthlyBudgetGoal: pending?.monthlyBudgetGoal ?? local.monthlyBudgetGoal,
    );

    if (result.ok && result.user != null) {
      await _repository.clearChallenge(email);
      await _repository.clearDemoMailboxCode(email);
      await _repository.clearPendingSignup(email);
      return _persistRemoteResult(
        AuthResult.success(
          result.user!.copyWith(emailVerified: true),
          token: result.token,
        ),
      );
    }

    if (result.failureCode == AuthFailureCode.emailTaken ||
        result.failureCode == AuthFailureCode.emailUnverified) {
      final login = await _supabase.login(
        email: email,
        password: password,
        resendIfUnverified: false,
      );
      if (login.ok && login.user != null) {
        await _repository.clearChallenge(email);
        await _repository.clearDemoMailboxCode(email);
        await _repository.clearPendingSignup(email);
        return _persistRemoteResult(
          AuthResult.success(
            login.user!.copyWith(emailVerified: true),
            token: login.token,
          ),
        );
      }
    }

    return AuthResult.failure(
      result.failureCode ?? AuthFailureCode.invalidCredentials,
      result.message ?? 'Could not finish signing up. Try again.',
      requiresVerification: true,
    );
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
    try {
      await _emailService.sendVerificationCode(
        toEmail: user.email,
        toName: user.name,
        code: code,
        expiresIn: otpTtl,
      );
    } catch (error) {
      final detail = '$error'.replaceFirst(RegExp(r'^Exception:\s*'), '');
      return AuthResult.failure(
        AuthFailureCode.invalidCredentials,
        'Could not email a 6-digit code to ${user.email}. $detail',
      );
    }

    return AuthResult.failure(
      AuthFailureCode.emailUnverified,
      'We emailed a 6-digit code to ${user.email}.',
      requiresVerification: true,
      demoCode: code,
    );
  }
}
