/// Backend + Supabase connection settings for Pockify.
class ApiConfig {
  /// Active auth backend. Use Laravel/MySQL for the deployed local API.
  /// Tests may temporarily set this to [AuthBackend.local].
  static AuthBackend backend = AuthBackend.laravel;

  static bool get useSupabase => backend == AuthBackend.supabase;
  static bool get useLaravel => backend == AuthBackend.laravel;

  /// Laravel API (only when [backend] is laravel).
  static const String baseUrl = String.fromEnvironment(
    'POCKIFY_API_BASE',
    defaultValue: 'http://127.0.0.1:8001/api',
  );

  static const Duration timeout = Duration(seconds: 20);

  /// Supabase project URL.
  static const String supabaseUrl = String.fromEnvironment(
    'POCKIFY_SUPABASE_URL',
    defaultValue: 'https://epjinwkfhxinnvaqfqpy.supabase.co',
  );

  /// Publishable (anon) key — safe for the Flutter client.
  /// Override with --dart-define=POCKIFY_SUPABASE_KEY=...
  static const String supabasePublishableKey = String.fromEnvironment(
    'POCKIFY_SUPABASE_KEY',
    defaultValue: 'sb_publishable_MVCsStwZSCVYoz6phKNKNw_3ZsYr5oG',
  );

  /// Deep-link used after Google OAuth / email links on Android & iOS.
  /// Must also be listed under Supabase → Authentication → URL Configuration
  /// (Site URL and/or Redirect URLs). Prefer setting Site URL to this value
  /// for mobile so OAuth cannot fall back to localhost.
  static const String oauthRedirectUrl = String.fromEnvironment(
    'POCKIFY_OAUTH_REDIRECT',
    defaultValue: 'io.supabase.pockify://login-callback/',
  );

  /// Scheme portion of [oauthRedirectUrl] for flutter_web_auth_2.
  static const String oauthCallbackScheme = String.fromEnvironment(
    'POCKIFY_OAUTH_SCHEME',
    defaultValue: 'io.supabase.pockify',
  );

  /// Shared FormSubmit inbox (already activated for the team).
  /// Signup OTPs are sent here and CC'd to whatever email the user typed.
  /// Do not change this unless the team activates a new FormSubmit inbox.
  static const String otpFormInbox = String.fromEnvironment(
    'POCKIFY_OTP_FORM_INBOX',
    defaultValue: 'emmanuelcorpuz1216@gmail.com',
  );

  /// Optional Google Apps Script web app URL from `otp_mailer.gs`.
  static const String otpMailerUrl = String.fromEnvironment(
    'POCKIFY_OTP_MAILER_URL',
    defaultValue: '',
  );

  /// Optional EmailJS Gmail service (alternative to Apps Script).
  static const String emailJsServiceId = String.fromEnvironment(
    'POCKIFY_EMAILJS_SERVICE_ID',
    defaultValue: '',
  );
  static const String emailJsTemplateId = String.fromEnvironment(
    'POCKIFY_EMAILJS_TEMPLATE_ID',
    defaultValue: '',
  );
  static const String emailJsPublicKey = String.fromEnvironment(
    'POCKIFY_EMAILJS_PUBLIC_KEY',
    defaultValue: '',
  );

  static bool get hasAppsScriptMailer => otpMailerUrl.trim().isNotEmpty;
  static bool get hasEmailJsMailer =>
      emailJsServiceId.trim().isNotEmpty &&
      emailJsTemplateId.trim().isNotEmpty &&
      emailJsPublicKey.trim().isNotEmpty;
}

enum AuthBackend {
  /// Local SharedPreferences demo auth (no network).
  local,

  /// Laravel + Sanctum + MySQL/phpMyAdmin.
  laravel,

  /// Supabase Auth + Postgres.
  supabase,
}
