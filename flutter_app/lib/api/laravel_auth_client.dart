import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_models.dart';
import 'api_config.dart';

class LaravelAuthClient {
  LaravelAuthClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
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
    return _send(
      'POST',
      '/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'currency': ?currency,
        'country': ?country,
        'employment_status': ?employmentStatus,
      },
      fallbackRequiresVerification: true,
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return _send(
      'POST',
      '/login',
      body: {'email': email, 'password': password},
    );
  }

  Future<AuthResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    return _send(
      'POST',
      '/email/verify',
      body: {'email': email, 'code': code},
      fallbackRequiresVerification: true,
    );
  }

  Future<AuthResult> resendCode({required String email}) async {
    return _send(
      'POST',
      '/email/resend',
      body: {'email': email},
      fallbackRequiresVerification: true,
    );
  }

  Future<AuthResult> changeEmail({
    required String currentEmail,
    required String newEmail,
  }) async {
    return _send(
      'POST',
      '/email/change',
      body: {
        'current_email': currentEmail,
        'new_email': newEmail,
      },
      fallbackRequiresVerification: true,
    );
  }

  Future<Duration?> remainingOtpTime(String email) async {
    try {
      final response = await _client
          .get(
            _uri('/email/status', {'email': email}),
            headers: {'Accept': 'application/json'},
          )
          .timeout(ApiConfig.timeout);
      final json = _decode(response);
      final seconds = json['remaining_seconds'];
      if (seconds is num) return Duration(seconds: seconds.toInt());
    } catch (_) {}
    return null;
  }

  Future<AuthResult> me(String token) async {
    try {
      final response = await _client
          .get(
            _uri('/user'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);
      final json = _decode(response);
      if (response.statusCode == 401 || response.statusCode == 403) {
        return AuthResult.failure(
          AuthFailureCode.invalidCredentials,
          'Session expired. Please sign in again.',
        );
      }
      return _mapResponse(json, response.statusCode);
    } catch (error) {
      return AuthResult.failure(
        AuthFailureCode.invalidCredentials,
        'Cannot reach Laravel API at ${ApiConfig.baseUrl}. ($error)',
      );
    }
  }

  Future<AuthResult> logout(String? token) async {
    if (token == null || token.isEmpty) {
      return AuthResult.success(
        AuthUser(
          id: '',
          name: '',
          email: '',
          passwordHash: '',
          passwordSalt: '',
          emailVerified: true,
          createdAt: DateTime.now(),
        ),
      );
    }
    try {
      await _client
          .post(
            _uri('/logout'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);
    } catch (_) {}
    return AuthResult.success(
      AuthUser(
        id: '',
        name: '',
        email: '',
        passwordHash: '',
        passwordSalt: '',
        emailVerified: true,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<AuthResult> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool fallbackRequiresVerification = false,
  }) async {
    try {
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      late http.Response response;
      final uri = _uri(path);
      if (method == 'POST') {
        response = await _client
            .post(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(ApiConfig.timeout);
      } else {
        response = await _client.get(uri, headers: headers).timeout(ApiConfig.timeout);
      }

      final json = _decode(response);
      return _mapResponse(json, response.statusCode);
    } catch (error) {
      return AuthResult.failure(
        AuthFailureCode.invalidCredentials,
        'Cannot reach Laravel API at ${ApiConfig.baseUrl}. '
        'Start it with: cd backend/api && php artisan serve. ($error)',
        requiresVerification: fallbackRequiresVerification,
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return Map<String, dynamic>.from(decoded as Map);
  }

  AuthResult _mapResponse(Map<String, dynamic> json, int status) {
    final userJson = json['user'];
    final user = userJson is Map
        ? AuthUser.fromApiJson(Map<String, dynamic>.from(userJson))
        : null;
    final token = json['token'] as String?;
    final demoCode = json['demo_code'] as String?;
    final message = _extractMessage(json);
    final requiresVerification =
        json['requires_verification'] == true ||
        json['code'] == 'email_unverified';
    final code = _mapCode(json['code'] as String?, status, requiresVerification);

    if (json['ok'] == true && user != null) {
      return AuthResult.success(user, token: token, demoCode: demoCode);
    }

    if (requiresVerification) {
      return AuthResult.failure(
        code ?? AuthFailureCode.emailUnverified,
        message ?? "We've sent a verification code to your email address.",
        requiresVerification: true,
        demoCode: demoCode,
        user: user,
        token: token,
      );
    }

    return AuthResult.failure(
      code ?? AuthFailureCode.invalidCredentials,
      message ?? 'Request failed.',
      user: user,
      token: token,
      demoCode: demoCode,
    );
  }

  String? _extractMessage(Map<String, dynamic> json) {
    if (json['message'] is String) return json['message'] as String;
    final errors = json['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
    return null;
  }

  AuthFailureCode? _mapCode(
    String? code,
    int status,
    bool requiresVerification,
  ) {
    switch (code) {
      case 'email_unverified':
        return AuthFailureCode.emailUnverified;
      case 'email_not_found':
        return AuthFailureCode.emailNotFound;
      case 'email_taken':
        return AuthFailureCode.emailTaken;
      case 'invalid_code':
        return AuthFailureCode.invalidCode;
      case 'expired_code':
        return AuthFailureCode.expiredCode;
      case 'too_many_attempts':
        return AuthFailureCode.tooManyAttempts;
      case 'resend_cooldown':
        return AuthFailureCode.resendCooldown;
    }
    if (status == 422 && requiresVerification) {
      return AuthFailureCode.invalidCode;
    }
    if (status == 403 && requiresVerification) {
      return AuthFailureCode.emailUnverified;
    }
    if (status == 429) return AuthFailureCode.resendCooldown;
    return null;
  }
}
