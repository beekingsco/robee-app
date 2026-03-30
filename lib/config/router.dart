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
import '../services/mock_data.dart';
import '../theme/robee_theme.dart';

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

      // ── Shell route wraps home, alerts, settings with bottom nav ────────
      ShellRoute(
        builder: (context, state, child) {
          return _AppShell(child: child, location: state.uri.toString());
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (ctx, state) => _fadePage(const HomeScreen()),
            routes: [
              GoRoute(
                path: 'camera',
                pageBuilder: (ctx, state) =>
                    _slidePage(const CameraScreen()),
              ),
              GoRoute(
                path: 'arm',
                pageBuilder: (ctx, state) =>
                    _slidePage(const ArmControlScreen()),
              ),
            ],
          ),
          GoRoute(
            path: '/alerts',
            pageBuilder: (ctx, state) => _fadePage(const AlertsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (ctx, state) => _fadePage(const SettingsScreen()),
          ),
        ],
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
            const Text(
              'Route not found',
              style: TextStyle(
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

// ── App Shell with Bottom Navigation Bar ─────────────────────────────────────
class _AppShell extends ConsumerWidget {
  final Widget child;
  final String location;

  const _AppShell({required this.child, required this.location});

  int _selectedIndex(String loc) {
    if (loc.startsWith('/alerts')) return 1;
    if (loc.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _selectedIndex(location);
    final unresolvedCount = MockData.unresolvedAlerts.length;

    return Scaffold(
      backgroundColor: RoBeeTheme.background,
      body: child,
      bottomNavigationBar: _RoBeeBottomNav(
        selectedIndex: idx,
        alertCount: unresolvedCount,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/alerts');
            case 2:
              context.go('/settings');
          }
        },
      ),
    );
  }
}

class _RoBeeBottomNav extends StatelessWidget {
  final int selectedIndex;
  final int alertCount;
  final ValueChanged<int> onTap;

  const _RoBeeBottomNav({
    required this.selectedIndex,
    required this.alertCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0A09),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.hive_rounded,
                label: 'Trailers',
                selected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.notifications_outlined,
                label: 'Alerts',
                selected: selectedIndex == 1,
                badgeCount: alertCount,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                selected: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? RoBeeTheme.amber : Colors.white.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: iconColor, size: 24),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: RoBeeTheme.healthRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            // Active: show label. Inactive: no label (Tesla bottom nav style)
            if (selected) ...[
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: RoBeeTheme.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
