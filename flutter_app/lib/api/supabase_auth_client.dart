import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../auth/auth_models.dart' as pockify;
import 'api_config.dart';

/// Supabase Auth adapter mapped to Pockify [pockify.AuthResult].
class SupabaseAuthClient {
  SupabaseClient get _client => Supabase.instance.client;

  /// Web uses the current origin; mobile uses the app deep-link scheme.
  String get _authRedirectTo =>
      kIsWeb ? Uri.base.origin : ApiConfig.oauthRedirectUrl;

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
    final normalized = email.trim().toLowerCase();
    try {
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

      // Existing accounts are returned with an empty identities list.
      if (user.identities != null && user.identities!.isEmpty) {
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.emailTaken,
          'An account with this email already exists. Sign in instead.',
        );
      }

      if (response.session != null) {
        final mapped = (await _userWithProfile(user)).copyWith(
          emailVerified: true,
        );
        await _upsertProfile(mapped);
        return pockify.AuthResult.success(
          mapped,
          token: response.session!.accessToken,
        );
      }

      final signedIn = await login(
        email: normalized,
        password: password,
        resendIfUnverified: false,
      );
      if (signedIn.ok && signedIn.user != null) {
        return pockify.AuthResult.success(
          signedIn.user!.copyWith(emailVerified: true),
          token: signedIn.token,
        );
      }

      final mapped = _mapUser(user, profile: null).copyWith(
        emailVerified: true,
        currency: cleanCurrency,
        employmentStatus: cleanEmployment,
        birthDate: birthDate,
        monthlyIncome: monthlyIncome,
        monthlyBudgetGoal: monthlyBudgetGoal,
      );

      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.emailUnverified,
        'Account created, but sign-in is not ready yet. Try signing in.',
        requiresVerification: true,
        user: mapped,
        demoCode: null,
      );
    } on AuthException catch (error) {
      final mapped = _mapAuthException(
        error,
        fallbackRequiresVerification: true,
      );
      if (mapped.failureCode == pockify.AuthFailureCode.emailTaken) {
        return mapped;
      }
      return mapped;
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
    bool resendIfUnverified = true,
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
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.emailUnverified,
          'Email is not verified yet. Enter the 6-digit code previewed for this address.',
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
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.emailUnverified,
          'Email is not verified yet. Enter the 6-digit code previewed for this address.',
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

  Future<pockify.AuthResult> signInWithGoogle() async {
    try {
      if (!await _isGoogleProviderEnabled()) {
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.invalidCredentials,
          'Google sign-in is not enabled on this Supabase project. Enable Google under Authentication → Providers, then try again.',
        );
      }

      final launched = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _authRedirectTo,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        queryParams: const {'prompt': 'select_account'},
      );
      if (!launched) {
        return pockify.AuthResult.failure(
          pockify.AuthFailureCode.invalidCredentials,
          'Could not open Google sign-in. Allow popups, then try again.',
        );
      }
      return pockify.AuthResult.redirecting();
    } on AuthException catch (error) {
      return _mapAuthException(error);
    } catch (error) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.invalidCredentials,
        'Google sign-in failed. ($error)',
      );
    }
  }

  Future<bool> _isGoogleProviderEnabled() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.supabaseUrl}/auth/v1/settings'),
            headers: {
              'apikey': ApiConfig.supabasePublishableKey,
              'Authorization': 'Bearer ${ApiConfig.supabasePublishableKey}',
            },
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode != 200) return false;
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return false;
      final external = json['external'];
      if (external is! Map) return false;
      return external['google'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<pockify.AuthResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    final normalized = email.trim().toLowerCase();
    final token = code.trim();

    try {
      final response = await _verifyEmailOtp(email: normalized, token: token);

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
      await _resendEmailOtp(email.trim().toLowerCase());
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.emailUnverified,
        "We've sent a new 6-digit verification code to your email.",
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
        "We've sent a confirmation email to your new address. Click the link inside it.",
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

  StreamSubscription<AuthState> watchVerified(void Function() onVerified) {
    return _client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event != AuthChangeEvent.signedIn &&
          event != AuthChangeEvent.initialSession &&
          event != AuthChangeEvent.userUpdated) {
        return;
      }
      final user = data.session?.user;
      if (user == null) return;
      if (user.emailConfirmedAt != null ||
          user.identities?.any((identity) => identity.provider == 'google') ==
              true) {
        onVerified();
      }
    });
  }

  Future<AuthResponse> _verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    AuthException? lastError;
    for (final type in const [
      OtpType.signup,
      OtpType.email,
      OtpType.magiclink,
    ]) {
      try {
        return await _client.auth.verifyOTP(
          type: type,
          email: email,
          token: token,
        );
      } on AuthException catch (error) {
        lastError = error;
      }
    }
    throw lastError ??
        AuthException('This verification code is invalid or has expired.');
  }

  Future<void> _resendEmailOtp(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
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

      // Ensure Google (and other) sign-ins always have a profiles row.
      final mapped = await _ensureProfileStored(user);
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

  /// Loads profile and upserts into public.profiles (creates Google users too).
  Future<pockify.AuthUser> _ensureProfileStored(User user) async {
    final mapped = await _userWithProfile(user);
    await _upsertProfile(mapped);
    // Re-read so we pick up DB defaults / trigger values.
    return _userWithProfile(user);
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
        'avatar_url': user.avatarUrl,
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

    final profileAvatar = (profile?['avatar_url'] as String?)?.trim();
    final metaAvatar = (meta['avatar_url'] as String?)?.trim();
    final googlePicture = (meta['picture'] as String?)?.trim();
    final avatarUrl = (profileAvatar != null && profileAvatar.isNotEmpty)
        ? profileAvatar
        : (metaAvatar != null && metaAvatar.isNotEmpty)
            ? metaAvatar
            : (googlePicture != null && googlePicture.isNotEmpty)
                ? googlePicture
                : null;

    return pockify.AuthUser(
      id: user.id,
      name: name,
      email: (user.email ?? '').toLowerCase(),
      passwordHash: '',
      passwordSalt: '',
      emailVerified: user.emailConfirmedAt != null ||
          (user.identities?.any((identity) => identity.provider == 'google') ??
              false),
      currency: (profile?['currency'] as String?) ?? meta['currency'] as String?,
      employmentStatus: (profile?['employment_status'] as String?) ??
          meta['employment_status'] as String?,
      birthDate: birthDate,
      monthlyIncome: asDouble(profile?['monthly_income']) ??
          asDouble(meta['monthly_income']),
      monthlyBudgetGoal: asDouble(profile?['monthly_budget_goal']) ??
          asDouble(meta['monthly_budget_goal']),
      avatarUrl: avatarUrl,
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
    if (code == 'validation_failed' ||
        lower.contains('unsupported provider') ||
        lower.contains('provider is not enabled')) {
      return pockify.AuthResult.failure(
        pockify.AuthFailureCode.invalidCredentials,
        'Google sign-in is not enabled on this Supabase project. Enable Google under Authentication → Providers.',
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
        'That code is invalid or already used. Tap Resend Code and enter the newest 6-digit code, or continue with Google.',
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
