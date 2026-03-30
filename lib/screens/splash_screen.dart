import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/router.dart' show demoModeProvider;
import '../theme/robee_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _redirect();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Check demo mode state
    final isDemo = ref.read(demoModeProvider);
    if (isDemo) {
      context.go('/home');
      return;
    }

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    } catch (_) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoBeeTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hex logo with amber pulse
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse ring
                      Container(
                        width: 130 * _pulseScale.value,
                        height: 130 * _pulseScale.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: RoBeeTheme.amber
                                .withOpacity(_pulseOpacity.value * 0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
                      // Inner pulse ring
                      Container(
                        width: 108 * _pulseScale.value,
                        height: 108 * _pulseScale.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: RoBeeTheme.amber
                                .withOpacity(_pulseOpacity.value * 0.35),
                            width: 1,
                          ),
                        ),
                      ),
                      // Logo container
                      child!,
                    ],
                  ),
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: RoBeeTheme.amber.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: RoBeeTheme.amber.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: RoBeeTheme.amber.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(child: _HexLogo()),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'RoBee',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The Future of Apiary Management',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: RoBeeTheme.amber.withOpacity(0.7),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HexLogo extends StatelessWidget {
  const _HexLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _HexPainter(),
    );
  }
}

class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RoBeeTheme.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 6;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Bee emoji inside hex
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'R',
        style: TextStyle(fontSize: 18),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_HexPainter _) => false;
}
