import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

/// Dynamic weather background — matches Base44's atmospheric gradient style.
/// Deep, mood-based gradients with subtle particle effects. No stock photos.
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
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _WeatherStyle get _style => _getStyle(widget.weatherCode, widget.isDay);

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Base atmospheric gradient
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                  colors: style.gradientColors,
                ),
              ),
            ),

            // Subtle secondary radial glow (top center)
            Positioned(
              top: -80,
              left: -60,
              right: -60,
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                height: 300,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      style.glowColor.withOpacity(
                          style.glowOpacity + _anim.value * 0.06),
                      Colors.transparent,
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),

            // Weather-specific particle effect
            if (style.showStars)
              Opacity(
                opacity: 0.7 + _anim.value * 0.3,
                child: CustomPaint(
                  painter: _StarPainter(phase: _anim.value),
                  size: Size.infinite,
                ),
              ),

            if (style.showRain)
              Opacity(
                opacity: 0.18 + _anim.value * 0.08,
                child: CustomPaint(
                  painter: _RainPainter(phase: _anim.value),
                  size: Size.infinite,
                ),
              ),

            if (style.showClouds)
              Opacity(
                opacity: 0.12 + _anim.value * 0.06,
                child: CustomPaint(
                  painter: _CloudPainter(phase: _anim.value),
                  size: Size.infinite,
                ),
              ),

            // Bottom fade to app background
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      RoBeeTheme.background,
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

// ── Weather Style Definitions ─────────────────────────────────────────────────

class _WeatherStyle {
  final List<Color> gradientColors;
  final Color glowColor;
  final double glowOpacity;
  final bool showStars;
  final bool showRain;
  final bool showClouds;

  const _WeatherStyle({
    required this.gradientColors,
    required this.glowColor,
    this.glowOpacity = 0.0,
    this.showStars = false,
    this.showRain = false,
    this.showClouds = false,
  });
}

_WeatherStyle _getStyle(int code, bool isDay) {
  // Thunderstorm (95–99)
  if (code >= 95) {
    return const _WeatherStyle(
      gradientColors: [
        Color(0xFF0A0D14),
        Color(0xFF111827),
        Color(0xFF0C0A09),
      ],
      glowColor: Color(0xFF6366F1),
      glowOpacity: 0.12,
      showRain: true,
    );
  }

  // Heavy rain / showers (61–82)
  if (code >= 61 && code <= 82) {
    return const _WeatherStyle(
      gradientColors: [
        Color(0xFF0D1520),
        Color(0xFF152030),
        Color(0xFF0C0A09),
      ],
      glowColor: Color(0xFF3B82F6),
      glowOpacity: 0.08,
      showRain: true,
    );
  }

  // Drizzle (51–59)
  if (code >= 51 && code <= 59) {
    return const _WeatherStyle(
      gradientColors: [
        Color(0xFF111820),
        Color(0xFF1A2530),
        Color(0xFF0C0A09),
      ],
      glowColor: Color(0xFF60A5FA),
      glowOpacity: 0.07,
      showRain: true,
    );
  }

  // Snow (71–77, 85–86)
  if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
    return const _WeatherStyle(
      gradientColors: [
        Color(0xFF1A1F2E),
        Color(0xFF1E2535),
        Color(0xFF0C0A09),
      ],
      glowColor: Color(0xFFE0E7FF),
      glowOpacity: 0.10,
      showClouds: true,
    );
  }

  // Fog (40–49)
  if (code >= 40 && code <= 49) {
    return const _WeatherStyle(
      gradientColors: [
        Color(0xFF18191A),
        Color(0xFF202224),
        Color(0xFF0C0A09),
      ],
      glowColor: Color(0xFF9CA3AF),
      glowOpacity: 0.10,
      showClouds: true,
    );
  }

  // Overcast (3)
  if (code == 3) {
    return const _WeatherStyle(
      gradientColors: [
        Color(0xFF16181C),
        Color(0xFF1E2025),
        Color(0xFF0C0A09),
      ],
      glowColor: Color(0xFF6B7280),
      glowOpacity: 0.08,
      showClouds: true,
    );
  }

  // Partly cloudy (1–2)
  if (code >= 1 && code <= 2) {
    if (isDay) {
      return const _WeatherStyle(
        gradientColors: [
          Color(0xFF1A1508),
          Color(0xFF201A0C),
          Color(0xFF0C0A09),
        ],
        glowColor: Color(0xFFD98639),
        glowOpacity: 0.14,
        showClouds: true,
      );
    } else {
      return const _WeatherStyle(
        gradientColors: [
          Color(0xFF0C1020),
          Color(0xFF141828),
          Color(0xFF0C0A09),
        ],
        glowColor: Color(0xFF818CF8),
        glowOpacity: 0.10,
        showStars: true,
        showClouds: true,
      );
    }
  }

  // Clear sky (0)
  if (isDay) {
    // Warm amber/golden — sunny apiary day
    return const _WeatherStyle(
      gradientColors: [
        Color(0xFF221508),
        Color(0xFF1C1108),
        Color(0xFF0C0A09),
      ],
      glowColor: Color(0xFFD98639),
      glowOpacity: 0.20,
    );
  } else {
    // Deep purple/indigo night sky — exactly like Base44
    return const _WeatherStyle(
      gradientColors: [
        Color(0xFF0D0A1F),
        Color(0xFF12102A),
        Color(0xFF0C0A09),
      ],
      glowColor: Color(0xFF7C3AED),
      glowOpacity: 0.15,
      showStars: true,
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _StarPainter extends CustomPainter {
  final double phase;
  _StarPainter({required this.phase});

  static final _rng = Random(42);
  static final List<Offset> _positions = List.generate(
    60,
    (_) => Offset(_rng.nextDouble(), _rng.nextDouble() * 0.6),
  );
  static final List<double> _sizes = List.generate(
    60,
    (_) => 0.8 + _rng.nextDouble() * 1.4,
  );
  static final List<double> _phases = List.generate(
    60,
    (_) => _rng.nextDouble(),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < _positions.length; i++) {
      final twinkle = (phase + _phases[i]) % 1.0;
      final opacity = 0.3 + twinkle * 0.6;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(_positions[i].dx * size.width, _positions[i].dy * size.height),
        _sizes[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.phase != phase;
}

class _RainPainter extends CustomPainter {
  final double phase;
  _RainPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x3590CAF9)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    const spacing = 20.0;
    final offset = phase * spacing * 2;

    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing * 2 + offset; y < size.height + spacing;
          y += spacing) {
        canvas.drawLine(
          Offset(x + y * 0.1, y),
          Offset(x + y * 0.1 + 4, y + 12),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.phase != phase;
}

class _CloudPainter extends CustomPainter {
  final double phase;
  _CloudPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    // Two slow-drifting cloud shapes
    final drift1 = phase * size.width * 0.08;
    final drift2 = (1 - phase) * size.width * 0.06;

    _drawCloud(canvas, paint, size.width * 0.2 + drift1, size.height * 0.12,
        size.width * 0.35);
    _drawCloud(canvas, paint, size.width * 0.6 + drift2, size.height * 0.08,
        size.width * 0.28);
  }

  void _drawCloud(
      Canvas canvas, Paint paint, double cx, double cy, double w) {
    final h = w * 0.4;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      Radius.circular(h / 2),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.phase != phase;
}
