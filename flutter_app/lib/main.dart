import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api/api_config.dart';
import 'finance_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (ApiConfig.useSupabase) {
    await Supabase.initialize(
      url: ApiConfig.supabaseUrl,
      publishableKey: ApiConfig.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: true,
      ),
    );
    await _completeWebAuthRedirect();
  }

  runApp(const FinanceApp());
}

/// Flutter web skips AppLinks for OAuth. Exchange ?code= on the current URL.
Future<void> _completeWebAuthRedirect() async {
  if (!kIsWeb) return;
  final uri = Uri.base;
  final fragment = Uri.splitQueryString(uri.fragment);
  final hasAuthCallback =
      uri.queryParameters.containsKey('code') ||
      uri.queryParameters.containsKey('access_token') ||
      fragment.containsKey('code') ||
      fragment.containsKey('access_token');
  if (!hasAuthCallback) return;
  try {
    await Supabase.instance.client.auth.getSessionFromUrl(uri);
  } catch (_) {}
}
