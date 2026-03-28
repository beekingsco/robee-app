import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

/// Dynamic weather background — full-bleed photo + overlay, changes by condition.
/// Matches the Base44 WeatherBackground behavior.
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

  /// Returns the Unsplash photo URL for the current weather condition.
  String get _backgroundImageUrl {
    final code = widget.weatherCode;
    final isDay = widget.isDay;

    // Thunderstorm (95-99)
    if (code >= 95) {
      return 'https://images.unsplash.com/photo-1605727216801-e27ce1d0cc28?q=80&w=2070'; // dramatic storm
    }

    // Heavy rain / showers (61-67, 80-82)
    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
      return 'https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?q=80&w=2070'; // rain on field
    }

    // Drizzle / light rain (51-59)
    if (code >= 51 && code <= 59) {
      return 'https://images.unsplash.com/photo-1428592953211-077101b2021b?q=80&w=2070'; // soft rainy day
    }

    // Snow (71-77, 85-86)
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return 'https://images.unsplash.com/photo-1491002052546-bf38f186af56?q=80&w=2070'; // snow field
    }

    // Fog / mist (45-48)
    if (code >= 40 && code <= 49) {
      return 'https://images.unsplash.com/photo-1482841628122-9080d44bb807?q=80&w=2070'; // misty morning field
    }

    // Overcast (3)
    if (code == 3) {
      return 'https://images.unsplash.com/photo-1499956827185-0d63ee78a910?q=80&w=2070'; // cloudy sky over fields
    }

    // Partly cloudy (1-2)
    if (code >= 1 && code <= 2) {
      if (isDay) {
        return 'https://images.unsplash.com/photo-1499678329028-101435549a4e?q=80&w=2070'; // partly cloudy golden field
      } else {
        return 'https://images.unsplash.com/photo-1532767153582-b1a0e5145009?q=80&w=2070'; // partly cloudy night
      }
    }

    // Clear sky (0)
    if (isDay) {
      return 'https://images.unsplash.com/photo-1504618223053-559bdef9ad5c?q=80&w=2070'; // sunny apiary/beekeeper
    } else {
      return 'https://images.unsplash.com/photo-1444703686981-a3abbc4d4fe3?q=80&w=2070'; // clear night sky stars
    }
  }

  /// Overlay gradient — darkens the photo and fades to app bg at bottom.
  List<Color> get _overlayColors {
    final code = widget.weatherCode;
    final isDay = widget.isDay;

    if (code >= 95) {
      // Storm — very dark blue-grey
      return [
        const Color(0xCC0D1218),
        const Color(0xDD0D1218),
        RoBeeTheme.background,
      ];
    }
    if (code >= 51) {
      // Rain — dark blue
      return [
        const Color(0xBB0D1B2A),
        const Color(0xCC1B2B3A),
        RoBeeTheme.background,
      ];
    }
    if (code >= 40) {
      // Fog — grey
      return [
        const Color(0xBB1A1A1A),
        const Color(0xCC1A1A1A),
        RoBeeTheme.background,
      ];
    }
    if (code >= 1) {
      // Cloudy
      return [
        const Color(0xAA1A1814),
        const Color(0xCC1A1814),
        RoBeeTheme.background,
      ];
    }
    if (isDay) {
      // Clear day — warm amber tint
      return [
        const Color(0x992A1A08),
        const Color(0xBB1E1409),
        RoBeeTheme.background,
      ];
    }
    // Night — deep dark blue
    return [
      const Color(0xCC060A18),
      const Color(0xDD0D0F1A),
      RoBeeTheme.background,
    ];
  }

  bool get _isRain =>
      widget.weatherCode >= 51 && widget.weatherCode <= 99;

  bool get _isClearDay =>
      widget.weatherCode == 0 && widget.isDay;

  bool get _isNight =>
      widget.weatherCode == 0 && !widget.isDay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed weather photo
            AnimatedSwitcher(
              duration: const Duration(seconds: 2),
              child: Image.network(
                _backgroundImageUrl,
                key: ValueKey(_backgroundImageUrl),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to gradient if image fails
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _overlayColors,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Dark gradient overlay — fades photo into app background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 1.0],
                  colors: _overlayColors,
                ),
              ),
            ),

            // Rain streak overlay
            if (_isRain)
              Opacity(
                opacity: 0.12 + _shimmer.value * 0.08,
                child: CustomPaint(
                  painter: _RainPainter(phase: _shimmer.value),
                  size: Size.infinite,
                ),
              ),

            // Amber sun glow for clear day
            if (_isClearDay)
              Positioned(
                top: -60,
                left: 0,
                right: 0,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        RoBeeTheme.amber.withOpacity(
                            0.12 + _shimmer.value * 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Star twinkle for clear night
            if (_isNight)
              Opacity(
                opacity: 0.3 + _shimmer.value * 0.2,
                child: CustomPaint(
                  painter: _StarPainter(phase: _shimmer.value),
                  size: Size.infinite,
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

// ── Rain Streaks ─────────────────────────────────────────────────────────────

class _RainPainter extends CustomPainter {
  final double phase;
  _RainPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x4D90CAF9)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    const spacing = 18.0;
    final offset = phase * spacing;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = -spacing + offset * 2; y < size.height + spacing;
          y += spacing) {
        canvas.drawLine(
          Offset(x + y * 0.08, y),
          Offset(x + y * 0.08 + 3, y + 9),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.phase != phase;
}

// ── Star Twinkle ─────────────────────────────────────────────────────────────

class _StarPainter extends CustomPainter {
  final double phase;
  _StarPainter({required this.phase});

  static const _stars = [
    Offset(0.1, 0.05), Offset(0.25, 0.12), Offset(0.42, 0.04),
    Offset(0.6, 0.09), Offset(0.78, 0.06), Offset(0.9, 0.14),
    Offset(0.15, 0.22), Offset(0.35, 0.18), Offset(0.55, 0.2),
    Offset(0.7, 0.25), Offset(0.85, 0.19), Offset(0.05, 0.3),
    Offset(0.48, 0.28), Offset(0.92, 0.3), Offset(0.3, 0.35),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      final twinkle = (phase + i * 0.15) % 1.0;
      final opacity = 0.4 + twinkle * 0.5;
      final radius = 1.0 + twinkle * 0.8;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.phase != phase;
}
