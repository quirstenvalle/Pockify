import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api/api_config.dart';
import 'auth_repository.dart';

/// Sends the 6-digit signup code to the address the user typed.
abstract class EmailService {
  Future<void> sendVerificationCode({
    required String toEmail,
    required String toName,
    required String code,
    required Duration expiresIn,
  });
}

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
    await _repository.setDemoMailboxCode(toEmail, code);
    await _deliverToInbox(
      toEmail: toEmail,
      toName: toName,
      code: code,
      expiresIn: expiresIn,
    );
  }

  Future<void> _deliverToInbox({
    required String toEmail,
    required String toName,
    required String code,
    required Duration expiresIn,
  }) async {
    final minutes = expiresIn.inMinutes.clamp(1, 60);
    final greeting = toName.trim().isEmpty ? 'there' : toName.trim();
    final message =
        'Hi $greeting,\n\n'
        'Your Pockify verification code is:\n\n'
        '$code\n\n'
        'Type this 6-digit code in the app to finish signing up. '
        'It expires in $minutes minutes.\n\n'
        'If you did not create a Pockify account, ignore this email.';

    if (ApiConfig.hasAppsScriptMailer) {
      await _sendViaAppsScript(
        toEmail: toEmail,
        toName: toName,
        code: code,
        expiresInMinutes: minutes,
      );
      return;
    }

    if (ApiConfig.hasEmailJsMailer) {
      await _sendViaEmailJs(
        toEmail: toEmail,
        toName: toName,
        code: code,
        expiresInMinutes: minutes,
      );
      return;
    }

    await _sendViaFormSubmit(
      toEmail: toEmail,
      message: message,
      code: code,
    );
  }

  Future<void> _sendViaAppsScript({
    required String toEmail,
    required String toName,
    required String code,
    required int expiresInMinutes,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.otpMailerUrl.trim()),
          headers: const {'Content-Type': 'text/plain;charset=utf-8'},
          body: jsonEncode({
            'toEmail': toEmail,
            'toName': toName,
            'code': code,
            'expiresInMinutes': expiresInMinutes,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode >= 400) {
      throw Exception('Email delivery failed (${response.statusCode}).');
    }
  }

  Future<void> _sendViaEmailJs({
    required String toEmail,
    required String toName,
    required String code,
    required int expiresInMinutes,
  }) async {
    final response = await http
        .post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {
            'Content-Type': 'application/json',
            'origin': kIsWeb ? Uri.base.origin : 'http://localhost',
          },
          body: jsonEncode({
            'service_id': ApiConfig.emailJsServiceId,
            'template_id': ApiConfig.emailJsTemplateId,
            'user_id': ApiConfig.emailJsPublicKey,
            'template_params': {
              'to_email': toEmail,
              'to_name': toName,
              'code': code,
              'expires_in': '$expiresInMinutes minutes',
            },
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Email delivery failed (${response.statusCode}).');
    }
  }

  Future<void> _sendViaFormSubmit({
    required String toEmail,
    required String message,
    required String code,
  }) async {
    final recipient = toEmail.trim().toLowerCase();
    final owner = ApiConfig.otpFormInbox.trim().toLowerCase();
    final inbox = owner.isEmpty ? recipient : owner;

    final fields = <String, String>{
      'name': 'Pockify',
      '_subject': 'Your Pockify verification code: $code',
      '_template': 'box',
      '_captcha': 'false',
      'email': recipient,
      '_replyto': recipient,
      'signup_email': recipient,
      'code': code,
      'message': message,
    };
    if (recipient.isNotEmpty && recipient != inbox) {
      fields['_cc'] = recipient;
    }

    await _postFormSubmit(inbox: inbox, fields: fields);
  }

  Future<void> _postFormSubmit({
    required String inbox,
    required Map<String, String> fields,
  }) async {
    final uri = Uri.parse(
      'https://formsubmit.co/ajax/${Uri.encodeComponent(inbox)}',
    );
    // FormSubmit rejects requests without a real https Origin (mobile/APK
    // otherwise get: "open this page through a web server").
    final origin = Uri.parse(ApiConfig.supabaseUrl).origin;
    final response = await http
        .post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Origin': origin,
            'Referer': '$origin/',
          },
          body: fields,
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode >= 400) {
      throw Exception('Email delivery failed (${response.statusCode}).');
    }

    final body = response.body.trim();
    if (body.isEmpty) return;
    try {
      final json = jsonDecode(body);
      if (json is Map &&
          (json['success'] == 'false' || json['success'] == false)) {
        final detail = '${json['message'] ?? ''}'.trim();
        final lower = detail.toLowerCase();
        // First-time inbox activation: FormSubmit still accepted the request.
        if (lower.contains('activation') || lower.contains('activate form')) {
          return;
        }
        throw Exception(detail.isEmpty ? 'Email delivery failed.' : detail);
      }
    } on FormatException {
      // HTML success pages still mean the provider accepted the message.
    }
  }
}
