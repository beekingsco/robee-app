import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/robee_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
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
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        context.go('/home');
      } else {
        context.go('/home'); // demo mode: go straight to home
      }
    } catch (_) {
      context.go('/home'); // demo mode
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
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse ring
                    Container(
                      width: 120 * _pulseAnim.value,
                      height: 120 * _pulseAnim.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: RoBeeTheme.amber.withOpacity(_fadeAnim.value * 0.6),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // Inner pulse ring
                    Container(
                      width: 100 * _pulseAnim.value,
                      height: 100 * _pulseAnim.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: RoBeeTheme.amber.withOpacity(_fadeAnim.value * 0.4),
                          width: 1,
                        ),
                      ),
                    ),
                    // Logo hex container
                    child!,
                  ],
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
                child: const Center(
                  child: _HexLogo(),
                ),
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
              'Robotic Hive Assistant',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 0.5,
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

    // Bee dot inside
    final dotPaint = Paint()
      ..color = RoBeeTheme.amber
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 4, dotPaint);
  }

  @override
  bool shouldRepaint(_HexPainter _) => false;
}
