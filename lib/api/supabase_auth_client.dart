import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../auth/auth_models.dart' as pockify;
import 'api_config.dart';

/// Supabase Auth adapter mapped to Pockify [pockify.AuthResult].
class SupabaseAuthClient {
  SupabaseClient get _client => Supabase.instance.client;

  Future<pockify.AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? currency,
    String? employmentStatus,
    DateTime? birthDate,
    double? monthlyIncome,
    double? monthlyBudgetGoal,
  }) async {
    try {
      final normalized = email.trim().toLowerCase();
      final cleanCurrency =
          (currency == null || currency == 'Select currency') ? null : currency;
      final cleanEmployment =
          (employmentStatus == null || employmentStatus == 'Select status')
          ? null
          : employmentStatus;
      final birthDateIso = birthDate == null
          ? null
          : '${birthDate.year.toString().padLeft(4, '0')}-'
              '${birthDate.month.toString().padLeft(2, '0')}-'
              '${birthDate.day.toString().padLeft(2, '0')}';

      final response = await _client.auth.signUp(
        email: normalized,
        password: password,
        data: {
          'full_name': name.trim(),
          'name': name.trim(),
          if (cleanCurrency != null) 'currency': cleanCurrency,
          if (cleanEmployment != null) 'employment_status': cleanEmployment,
          if (birthDateIso != null) 'birth_date': birthDateIso,
          if (monthlyIncome != null) 'monthly_income': monthlyIncome.toString(),
          if (monthlyBudgetGoal != null)
            'monthly_budget_goal': monthlyBudgetGoal.toString(),
        },
      );

      final user = response.user;
      if (user == null) {
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.invalidCredentials,
          'Sign up failed. Please try again.',
        );
      }

      // Never keep a session before email OTP verification completes.
      await _client.auth.signOut();

      try {
        await _client.auth.resend(
          type: OtpType.signup,
          email: normalized,
        );
      } catch (_) {
        // Signup already triggers the first email when Confirm email is on.
      }

      final mapped = _mapUser(user, profile: null).copyWith(
        emailVerified: false,
        currency: cleanCurrency,
        employmentStatus: cleanEmployment,
        birthDate: birthDate,
        monthlyIncome: monthlyIncome,
        monthlyBudgetGoal: monthlyBudgetGoal,
      );

      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.emailUnverified,
        'Account created. Enter the verification code we sent to your email.',
        requiresVerification: true,
        user: mapped,
        demoCode: null,
      );
    } on AuthException catch (error) {
      return _mapAuthException(error, fallbackRequiresVerification: true);
    } catch (error) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.invalidCredentials,
        'Cannot reach Supabase at ${ApiConfig.supabaseUrl}. ($error)',
        requiresVerification: true,
      );
    }
  }

  Future<pockify.AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = response.user;
      if (user == null || response.session == null) {
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.invalidCredentials,
          'Incorrect email or password.',
        );
      }

      final mapped = await _userWithProfile(user);
      if (!mapped.emailVerified) {
        await _client.auth.signOut();
        await resendCode(email: email);
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.emailUnverified,
          'Verify your email before signing in. We sent a new code.',
          requiresVerification: true,
          user: mapped,
        );
      }

      return pockify.AuthResult.success(
        mapped,
        token: response.session!.accessToken,
      );
    } on AuthException catch (error) {
      final mapped = _mapAuthException(error);
      if (mapped.failureCode == pockify.AuthFailureCode.emailUnverified) {
        await resendCode(email: email);
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.emailUnverified,
          'Verify your email before signing in. We sent a new code.',
          requiresVerification: true,
        );
      }
      return mapped;
    } catch (error) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.invalidCredentials,
        'Cannot reach Supabase at ${ApiConfig.supabaseUrl}. ($error)',
      );
    }
  }

  Future<pockify.AuthResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    final normalized = email.trim().toLowerCase();
    final token = code.trim();

    try {
      AuthResponse response;
      try {
        response = await _client.auth.verifyOTP(
          type: OtpType.signup,
          email: normalized,
          token: token,
        );
      } on AuthException {
        response = await _client.auth.verifyOTP(
          type: OtpType.email,
          email: normalized,
          token: token,
        );
      }

      final user = response.user;
      if (user == null || response.session == null) {
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.invalidCode,
          'Incorrect verification code.',
          requiresVerification: true,
        );
      }

      final mapped = (await _userWithProfile(user)).copyWith(
        emailVerified: true,
      );
      await _upsertProfile(mapped);
      return pockify.AuthResult.success(
        mapped,
        token: response.session!.accessToken,
      );
    } on AuthException catch (error) {
      return _mapAuthException(error, fallbackRequiresVerification: true);
    } catch (error) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.invalidCode,
        'Verification failed. ($error)',
        requiresVerification: true,
      );
    }
  }

  Future<pockify.AuthResult> resendCode({required String email}) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
      );
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.emailUnverified,
        "We've sent a new verification code to your email.",
        requiresVerification: true,
      );
    } on AuthException catch (error) {
      return _mapAuthException(error, fallbackRequiresVerification: true);
    } catch (error) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.resendCooldown,
        'Could not resend code. ($error)',
        requiresVerification: true,
      );
    }
  }

  Future<pockify.AuthResult> changeEmail({
    required String currentEmail,
    required String newEmail,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.invalidEmail,
        'Sign in is required to change email, or register again with the new address.',
        requiresVerification: true,
      );
    }

    try {
      final response = await _client.auth.updateUser(
        UserAttributes(email: newEmail.trim().toLowerCase()),
      );
      final user = response.user;
      if (user == null) {
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.invalidEmail,
          'Could not update email.',
          requiresVerification: true,
        );
      }
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.emailUnverified,
        "We've sent a verification code to your new email address.",
        requiresVerification: true,
        user: await _userWithProfile(user),
      );
    } on AuthException catch (error) {
      return _mapAuthException(error, fallbackRequiresVerification: true);
    }
  }

  Future<Duration?> remainingOtpTime(String email) async {
    return const Duration(minutes: 10);
  }

  Future<pockify.AuthResult> me() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.invalidCredentials,
          'Session expired. Please sign in again.',
        );
      }

      final response = await _client.auth.getUser();
      final user = response.user;
      if (user == null) {
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.invalidCredentials,
          'Session expired. Please sign in again.',
        );
      }

      final mapped = await _userWithProfile(user);
      if (!mapped.emailVerified) {
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.emailUnverified,
          'Email is not verified yet.',
          requiresVerification: true,
          user: mapped,
        );
      }

      return pockify.AuthResult.success(mapped, token: session.accessToken);
    } on AuthException catch (error) {
      return _mapAuthException(error);
    } catch (error) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.invalidCredentials,
        'Cannot validate session. ($error)',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  Future<pockify.AuthUser> _userWithProfile(User user) async {
    Map<String, dynamic>? profile;
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) profile = Map<String, dynamic>.from(row);
    } catch (_) {}
    return _mapUser(user, profile: profile);
  }

  Future<void> _upsertProfile(pockify.AuthUser user) async {
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': user.name,
        'email': user.email,
        'currency': user.currency,
        'employment_status': user.employmentStatus,
        'birth_date': user.birthDate == null
            ? null
            : '${user.birthDate!.year.toString().padLeft(4, '0')}-'
                '${user.birthDate!.month.toString().padLeft(2, '0')}-'
                '${user.birthDate!.day.toString().padLeft(2, '0')}',
        'monthly_income': user.monthlyIncome,
        'monthly_budget_goal': user.monthlyBudgetGoal,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  pockify.AuthUser _mapUser(User user, {Map<String, dynamic>? profile}) {
    final meta = user.userMetadata ?? {};
    final name = (profile?['full_name'] as String?)?.trim().isNotEmpty == true
        ? profile!['full_name'] as String
        : (meta['full_name'] as String?) ??
            (meta['name'] as String?) ??
            (user.email?.split('@').first ?? 'User');

    DateTime? birthDate;
    final birthRaw = profile?['birth_date'] ?? meta['birth_date'];
    if (birthRaw != null) {
      birthDate = DateTime.tryParse('$birthRaw');
    }

    double? asDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse('$value');
    }

    return pockify.AuthUser(
      id: user.id,
      name: name,
      email: (user.email ?? '').toLowerCase(),
      passwordHash: '',
      passwordSalt: '',
      emailVerified: user.emailConfirmedAt != null,
      currency: (profile?['currency'] as String?) ?? meta['currency'] as String?,
      employmentStatus: (profile?['employment_status'] as String?) ??
          meta['employment_status'] as String?,
      birthDate: birthDate,
      monthlyIncome: asDouble(profile?['monthly_income']) ??
          asDouble(meta['monthly_income']),
      monthlyBudgetGoal: asDouble(profile?['monthly_budget_goal']) ??
          asDouble(meta['monthly_budget_goal']),
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  pockify.AuthResult _mapAuthException(
    AuthException error, {
    bool fallbackRequiresVerification = false,
  }) {
    final message = error.message;
    final lower = message.toLowerCase();
    final code = (error.code ?? '').toLowerCase();

    if (code == 'email_not_confirmed' ||
        lower.contains('email not confirmed') ||
        lower.contains('not confirmed')) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.emailUnverified,
        'Your email is not verified yet. Enter the code we sent to your inbox.',
        requiresVerification: true,
      );
    }
    if (code == 'user_already_registered' ||
        lower.contains('already registered') ||
        lower.contains('user already')) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.emailTaken,
        'An account with this email already exists. Sign in instead.',
      );
    }
    if (code == 'invalid_credentials' ||
        lower.contains('invalid login') ||
        lower.contains('invalid credentials') ||
        lower.contains('invalid email or password')) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.invalidCredentials,
        'Incorrect email or password. If you just signed up, confirm your email first or try again.',
      );
    }
    if (lower.contains('token') ||
        lower.contains('otp') ||
        code.contains('otp') ||
        lower.contains('expired')) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.invalidCode,
        message,
        requiresVerification: true,
      );
    }
    if (lower.contains('rate') || lower.contains('security')) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.resendCooldown,
        message,
        requiresVerification: true,
      );
    }

    return pockify.AuthResult.failure(
      pockify.AuthFailureCode.invalidCredentials,
      message.isEmpty ? 'Authentication failed.' : message,
      requiresVerification: fallbackRequiresVerification,
    );
  }
}
