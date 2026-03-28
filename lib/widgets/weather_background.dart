import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

class WeatherBackground extends StatefulWidget {
  final int weatherCode;
  final bool isDay;
  final Widget child;

  const WeatherBackground({
    super.key,
    required this.weatherCode,
    required this.isDay,
    required this.child,
  });

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> get _gradientColors {
    final code = widget.weatherCode;
    final isDay = widget.isDay;

    // Rain / Storm
    if (code >= 51 && code <= 99) {
      return [
        const Color(0xFF0D1B2A),
        const Color(0xFF1B2B3A),
        RoBeeTheme.background,
      ];
    }

    // Foggy
    if (code >= 40 && code <= 49) {
      return [
        const Color(0xFF1A1A1A),
        const Color(0xFF2A2520),
        RoBeeTheme.background,
      ];
    }

    // Cloudy
    if (code >= 1 && code <= 39) {
      return [
        const Color(0xFF1A1814),
        const Color(0xFF221E1A),
        RoBeeTheme.background,
      ];
    }

    // Clear
    if (isDay) {
      return [
        const Color(0xFF2A1A08),
        const Color(0xFF1E1409),
        RoBeeTheme.background,
      ];
    } else {
      // Night
      return [
        const Color(0xFF060A18),
        const Color(0xFF0D0F1A),
        RoBeeTheme.background,
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRain = widget.weatherCode >= 51 && widget.weatherCode <= 99;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Animated gradient background
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _gradientColors,
                ),
              ),
            ),

            // Rain effect overlay
            if (isRain)
              Opacity(
                opacity: 0.15 + _shimmer.value * 0.1,
                child: CustomPaint(
                  painter: _RainPainter(phase: _shimmer.value),
                ),
              ),

            // Ambient glow for clear day
            if (widget.weatherCode == 0 && widget.isDay)
              Positioned(
                top: -50,
                left: -50,
                right: -50,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        RoBeeTheme.amber.withOpacity(0.08 + _shimmer.value * 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Content
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _RainPainter extends CustomPainter {
  final double phase;
  _RainPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const spacing = 20.0;
    final offset = phase * spacing;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = -spacing + offset * 2; y < size.height + spacing; y += spacing) {
        canvas.drawLine(
          Offset(x + y * 0.1, y),
          Offset(x + y * 0.1 + 4, y + 10),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.phase != phase;
}
