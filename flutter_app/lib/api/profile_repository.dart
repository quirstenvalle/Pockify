import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_models.dart' as pockify;
import 'api_config.dart';

/// Profile updates + avatar uploads (Supabase storage + profiles.avatar_url).
class ProfileRepository {
  ProfileRepository({this._client});

  SupabaseClient? _client;
  SupabaseClient get client => _client ??= Supabase.instance.client;

  static const _bucket = 'avatars';

  /// Uploads to Storage when possible, otherwise stores a data URL.
  /// Always returns a string suitable for [profiles.avatar_url].
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    if (!ApiConfig.useSupabase) {
      return _dataUrl(bytes, contentType);
    }

    final sessionUserId = client.auth.currentUser?.id;
    final ownerId = (sessionUserId != null && sessionUserId.isNotEmpty)
        ? sessionUserId
        : userId;

    final ext = contentType.contains('png')
        ? 'png'
        : contentType.contains('webp')
            ? 'webp'
            : contentType.contains('gif')
                ? 'gif'
                : 'jpg';
    final path = '$ownerId/avatar.$ext';

    try {
      await client.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );
      final publicUrl = client.storage.from(_bucket).getPublicUrl(path);
      return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      // Fallback: keep the photo in the profiles row itself.
      return _dataUrl(bytes, contentType);
    }
  }

  String _dataUrl(Uint8List bytes, String contentType) {
    // Cap embedded DB avatars (~400KB encoded) so rows stay manageable.
    if (bytes.lengthInBytes > 300 * 1024) {
      throw StateError(
        'Could not upload avatar to storage, and the image is too large '
        'to store in the database. Try a smaller photo.',
      );
    }
    return 'data:$contentType;base64,${base64Encode(bytes)}';
  }

  Future<pockify.AuthUser> updateProfile({
    required pockify.AuthUser user,
    required String name,
    String? currency,
    String? country,
    String? employmentStatus,
    DateTime? birthDate,
    double? monthlyIncome,
    double? monthlyBudgetGoal,
    String? avatarUrl,
  }) async {
    final cleanedCurrency =
        (currency == null || currency == 'Select currency') ? null : currency;
    final cleanedCountry =
        (country == null || country.trim().isEmpty) ? null : country.trim();
    final cleanedEmployment =
        (employmentStatus == null || employmentStatus == 'Select status')
            ? null
            : employmentStatus;

    final sessionUserId = ApiConfig.useSupabase
        ? client.auth.currentUser?.id
        : null;
    final profileId = (sessionUserId != null && sessionUserId.isNotEmpty)
        ? sessionUserId
        : user.id;

    final updated = pockify.AuthUser(
      id: profileId,
      name: name.trim().isEmpty ? user.name : name.trim(),
      email: user.email,
      passwordHash: user.passwordHash,
      passwordSalt: user.passwordSalt,
      emailVerified: user.emailVerified,
      currency: cleanedCurrency,
      country: cleanedCountry ?? user.country,
      employmentStatus: cleanedEmployment,
      birthDate: birthDate,
      monthlyIncome: monthlyIncome,
      monthlyBudgetGoal: monthlyBudgetGoal,
      avatarUrl: avatarUrl ?? user.avatarUrl,
      onboardingCompleted: user.onboardingCompleted,
      incomeSource: user.incomeSource,
      incomeFrequency: user.incomeFrequency,
      incomeAmount: user.incomeAmount,
      budgetObjectives: user.budgetObjectives,
      createdAt: user.createdAt,
    );

    if (!ApiConfig.useSupabase) return updated;

    final birthDateIso = updated.birthDate == null
        ? null
        : '${updated.birthDate!.year.toString().padLeft(4, '0')}-'
            '${updated.birthDate!.month.toString().padLeft(2, '0')}-'
            '${updated.birthDate!.day.toString().padLeft(2, '0')}';

    // Persist all profile fields (including avatar_url) into public.profiles.
    await client.from('profiles').upsert({
      'id': updated.id,
      'full_name': updated.name,
      'email': updated.email,
      'currency': updated.currency,
      'country': updated.country,
      'employment_status': updated.employmentStatus,
      'birth_date': birthDateIso,
      'monthly_income': updated.monthlyIncome,
      'monthly_budget_goal': updated.monthlyBudgetGoal,
      'avatar_url': updated.avatarUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    try {
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': updated.name,
            'name': updated.name,
            if (updated.avatarUrl != null) 'avatar_url': updated.avatarUrl,
          },
        ),
      );
    } catch (_) {}

    return updated;
  }

  /// Persists the first-login financial onboarding answers and marks
  /// onboarding as complete so it is never shown again for this user.
  Future<pockify.AuthUser> completeOnboarding({
    required pockify.AuthUser user,
    required String incomeSource,
    required String incomeFrequency,
    required double incomeAmount,
    required List<String> budgetObjectives,
  }) async {
    final updated = user.copyWith(
      onboardingCompleted: true,
      incomeSource: incomeSource,
      incomeFrequency: incomeFrequency,
      incomeAmount: incomeAmount,
      budgetObjectives: budgetObjectives,
    );

    if (!ApiConfig.useSupabase) return updated;

    final sessionUserId = client.auth.currentUser?.id;
    final profileId = (sessionUserId != null && sessionUserId.isNotEmpty)
        ? sessionUserId
        : user.id;

    await client.from('profiles').upsert({
      'id': profileId,
      'onboarding_completed': true,
      'income_source': incomeSource,
      'income_frequency': incomeFrequency,
      'income_amount': incomeAmount,
      'budget_objectives': budgetObjectives,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    return updated;
  }
}
