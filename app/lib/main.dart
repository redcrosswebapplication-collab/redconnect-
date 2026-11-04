import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'screens/gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validateSupabaseConfig();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(ChangeNotifierProvider(
      create: (_) => AppState()..init(), child: const RedCrossApp()));
}

class RedCrossApp extends StatelessWidget {
  const RedCrossApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'RedCross Connect+',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: buildTheme(),
        home: const Gate(),
      );
}
