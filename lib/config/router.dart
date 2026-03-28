import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/arm_control_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/reserve/reserve_screen.dart';
import '../screens/reserve/deposit_screen.dart';
import '../screens/trailer_detail_screen.dart';
import '../screens/trailer_settings_screen.dart';
import '../screens/hive_detail_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/register_trailer_screen.dart';

final demoModeProvider = StateProvider<bool>((ref) => false);

/// Slide-from-right page transition
Page<T> _slidePage<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        )),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
  );
}

/// Fade page transition (for root/splash)
Page<T> _fadePage<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (ctx, state) => _fadePage(const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, state) => _slidePage(const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (ctx, state) => _slidePage(const RegisterScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (ctx, state) => _fadePage(const HomeScreen()),
        routes: [
          GoRoute(
            path: 'camera',
            pageBuilder: (ctx, state) => _slidePage(const CameraScreen()),
          ),
          GoRoute(
            path: 'arm',
            pageBuilder: (ctx, state) => _slidePage(const ArmControlScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (ctx, state) => _slidePage(const SettingsScreen()),
      ),
      GoRoute(
        path: '/reserve',
        pageBuilder: (ctx, state) => _slidePage(const ReserveScreen()),
        routes: [
          GoRoute(
            path: 'deposit',
            pageBuilder: (ctx, state) => _slidePage(const DepositScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/trailers/:id',
        pageBuilder: (ctx, state) => _slidePage(
          TrailerDetailScreen(trailerId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/trailers/:id/settings',
        pageBuilder: (ctx, state) => _slidePage(
          TrailerSettingsScreen(trailerId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/hives/:id',
        pageBuilder: (ctx, state) => _slidePage(
          HiveDetailScreen(hiveId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/alerts',
        pageBuilder: (ctx, state) => _slidePage(const AlertsScreen()),
      ),
      GoRoute(
        path: '/register-trailer',
        pageBuilder: (ctx, state) => _slidePage(const RegisterTrailerScreen()),
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      backgroundColor: const Color(0xFF0C0A09),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text(
              'Route not found',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.uri}',
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
});
