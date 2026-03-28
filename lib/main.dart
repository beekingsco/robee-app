import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'services/supabase_service.dart';
import 'config/app_config.dart';
import 'config/router.dart' show routerProvider, demoModeProvider;
import 'theme/robee_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase — graceful fallback to demo mode if credentials not configured
  bool demoMode = false;
  if (AppConfig.supabaseUrl == 'https://your-project.supabase.co' ||
      AppConfig.supabaseUrl.isEmpty ||
      AppConfig.supabaseAnonKey == 'your-anon-key' ||
      AppConfig.supabaseAnonKey.isEmpty) {
    demoMode = true;
  } else {
    try {
      await SupabaseService.initialize();
    } catch (e) {
      demoMode = true;
    }
  }

  // Stripe — graceful fallback if key not configured
  if (AppConfig.stripePublishableKey != 'pk_test_placeholder' &&
      AppConfig.stripePublishableKey.isNotEmpty) {
    try {
      Stripe.publishableKey = AppConfig.stripePublishableKey;
      await Stripe.instance.applySettings();
    } catch (_) {}
  }

  runApp(ProviderScope(
    overrides: [
      demoModeProvider.overrideWith((ref) => demoMode),
    ],
    child: RoBeeApp(demoMode: demoMode),
  ));
}

class RoBeeApp extends ConsumerWidget {
  final bool demoMode;
  const RoBeeApp({super.key, this.demoMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: RoBeeTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (demoMode)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    color: const Color(0xFFF4A025).withValues(alpha: 0.9),
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    child: const SafeArea(
                      bottom: false,
                      child: Text(
                        '⚡ DEMO MODE — no backend connected',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
