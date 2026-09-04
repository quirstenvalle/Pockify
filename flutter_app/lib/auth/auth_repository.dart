import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_models.dart';

/// Local persistence for users and verification challenges.
/// Passwords and OTPs are stored as salted SHA-256 hashes only.
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  static const _usersKey = 'pockify_auth_users_v1';
  static const _challengeKey = 'pockify_email_challenges_v1';
  static const _sessionKey = 'pockify_auth_session_v1';
  static const _tokenKey = 'pockify_auth_token_v1';
  static const _demoMailboxKey = 'pockify_demo_mailbox_v1';
  static const _pendingSignupKey = 'pockify_pending_signup_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<AuthUser>> loadUsers() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((item) => AuthUser.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveUsers(List<AuthUser> users) async {
    final prefs = await _prefs;
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  Future<AuthUser?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final users = await loadUsers();
    for (final user in users) {
      if (user.email == normalized) return user;
    }
    return null;
  }

  Future<AuthUser> upsertUser(AuthUser user) async {
    final users = await loadUsers();
    final index = users.indexWhere((u) => u.email == user.email);
    if (index == -1) {
      users.add(user);
    } else {
      users[index] = user;
    }
    await saveUsers(users);
    return user;
  }

  Future<Map<String, EmailVerificationChallenge>> loadChallenges() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_challengeKey);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map(
      (key, value) => MapEntry(
        key,
        EmailVerificationChallenge.fromJson(
          Map<String, dynamic>.from(value as Map),
        ),
      ),
    );
  }

  Future<void> saveChallenge(EmailVerificationChallenge challenge) async {
    final challenges = await loadChallenges();
    challenges[challenge.email] = challenge;
    final prefs = await _prefs;
    await prefs.setString(
      _challengeKey,
      jsonEncode(
        challenges.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
  }

  Future<EmailVerificationChallenge?> getChallenge(String email) async {
    final challenges = await loadChallenges();
    return challenges[email.trim().toLowerCase()];
  }

  Future<void> clearChallenge(String email) async {
    final challenges = await loadChallenges();
    challenges.remove(email.trim().toLowerCase());
    final prefs = await _prefs;
    await prefs.setString(
      _challengeKey,
      jsonEncode(
        challenges.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
  }

  Future<void> setSessionEmail(String? email) async {
    final prefs = await _prefs;
    if (email == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, email.trim().toLowerCase());
    }
  }

  Future<String?> getSessionEmail() async {
    final prefs = await _prefs;
    return prefs.getString(_sessionKey);
  }

  Future<void> setAuthToken(String? token) async {
    final prefs = await _prefs;
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<String?> getAuthToken() async {
    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }

  Future<void> clearSession() async {
    await setAuthToken(null);
    await setSessionEmail(null);
  }

  /// Demo-only mailbox so local builds can test without SMTP keys.
  Future<void> setDemoMailboxCode(String email, String code) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_demoMailboxKey);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    map[email.trim().toLowerCase()] = code;
    await prefs.setString(_demoMailboxKey, jsonEncode(map));
  }

  Future<String?> getDemoMailboxCode(String email) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_demoMailboxKey);
    if (raw == null || raw.isEmpty) return null;
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return map[email.trim().toLowerCase()] as String?;
  }

  Future<void> clearDemoMailboxCode(String email) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_demoMailboxKey);
    if (raw == null || raw.isEmpty) return;
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    map.remove(email.trim().toLowerCase());
    await prefs.setString(_demoMailboxKey, jsonEncode(map));
  }

  Future<void> savePendingSignup(PendingSignup pending) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_pendingSignupKey);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    map[pending.email.trim().toLowerCase()] = pending.toJson();
    await prefs.setString(_pendingSignupKey, jsonEncode(map));
  }

  Future<PendingSignup?> getPendingSignup(String email) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_pendingSignupKey);
    if (raw == null || raw.isEmpty) return null;
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final row = map[email.trim().toLowerCase()];
    if (row is! Map) return null;
    return PendingSignup.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> clearPendingSignup(String email) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_pendingSignupKey);
    if (raw == null || raw.isEmpty) return;
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    map.remove(email.trim().toLowerCase());
    await prefs.setString(_pendingSignupKey, jsonEncode(map));
  }
}

class SecureHashing {
  static final _random = Random.secure();

  static String randomSalt([int length = 16]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  static String hash(String value, String salt) {
    final bytes = utf8.encode('$salt::$value');
    return sha256.convert(bytes).toString();
  }

  static bool matches(String value, String salt, String expectedHash) {
    return hash(value, salt) == expectedHash;
  }

  static String generateOtp({int length = 6}) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(_random.nextInt(10));
    }
    return buffer.toString();
  }
}
