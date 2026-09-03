/// Backend + Supabase connection settings for Pockify.
class ApiConfig {
  /// Active auth backend. Prefer [AuthBackend.supabase] in production.
  /// Tests may temporarily set this to [AuthBackend.local].
  static AuthBackend backend = AuthBackend.supabase;

  static bool get useSupabase => backend == AuthBackend.supabase;
  static bool get useLaravel => backend == AuthBackend.laravel;

  /// Laravel API (only when [backend] is laravel).
  static const String baseUrl = String.fromEnvironment(
    'POCKIFY_API_BASE',
    defaultValue: 'http://127.0.0.1:8000/api',
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
}

enum AuthBackend {
  /// Local SharedPreferences demo auth (no network).
  local,

  /// Laravel + Sanctum + MySQL/phpMyAdmin.
  laravel,

  /// Supabase Auth + Postgres.
  supabase,
}
