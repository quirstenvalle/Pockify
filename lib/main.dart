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
    );
  }

  runApp(const FinanceApp());
}
