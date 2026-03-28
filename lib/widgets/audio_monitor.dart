import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

class AudioMonitor extends StatefulWidget {
  final String hiveId;

  const AudioMonitor({super.key, required this.hiveId});

  @override
  State<AudioMonitor> createState() => _AudioMonitorState();
}

class _AudioMonitorState extends State<AudioMonitor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random(42);

  static const _mockConcerns = [
    ('14:22', 'Elevated buzzing frequency detected'),
    ('11:47', 'Unusual activity near entrance'),
    ('09:15', 'Normal colony sounds'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RoBeeTheme.glassWhite5,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RoBeeTheme.glassWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq_rounded,
                  color: RoBeeTheme.signalPurple, size: 18),
              const SizedBox(width: 8),
              Text(
                'AUDIO MONITOR',
                style: RoBeeTheme.labelLarge.copyWith(color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoBeeTheme.signalPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: RoBeeTheme.signalPurple.withOpacity(0.3)),
                ),
                child: Text(
                  'LIVE',
                  style: RoBeeTheme.labelSmall.copyWith(
                    color: RoBeeTheme.signalPurple,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Waveform
          SizedBox(
            height: 40,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WaveformPainter(
                    phase: _controller.value,
                    random: _random,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'MOMENTS OF CONCERN',
            style: RoBeeTheme.labelSmall.copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),

          // Concern list
          ..._mockConcerns.map((concern) {
            final (time, msg) = concern;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: RoBeeTheme.monoSmall.copyWith(
                      color: RoBeeTheme.amber,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      msg,
                      style: RoBeeTheme.bodyMedium.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double phase;
  final math.Random random;

  _WaveformPainter({required this.phase, required this.random});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RoBeeTheme.signalPurple.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final barWidth = 3.0;
    final barSpacing = 2.0;
    final totalWidth = barWidth + barSpacing;
    final barCount = (size.width / totalWidth).floor();
    final centerY = size.height / 2;

    final seed = math.Random(42);
    final heights = List.generate(barCount, (i) {
      final base = seed.nextDouble() * 0.7 + 0.1;
      final wave = math.sin(i * 0.5 + phase * math.pi * 2) * 0.3;
      return (base + wave).clamp(0.05, 1.0) * size.height * 0.9;
    });

    for (int i = 0; i < barCount; i++) {
      final x = i * totalWidth + barWidth / 2;
      final h = heights[i];

      // Active bars glow
      if (i % 4 == 0) {
        final glowPaint = Paint()
          ..color = RoBeeTheme.signalPurple.withOpacity(0.2)
          ..strokeWidth = barWidth + 2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawLine(Offset(x, centerY - h / 2), Offset(x, centerY + h / 2),
            glowPaint);
      }

      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.phase != phase;
}
