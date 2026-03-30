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

  static const _mockConcerns = [
    ('14:22', 'Elevated buzzing frequency detected'),
    ('11:47', 'Unusual activity near entrance'),
    ('09:15', 'Normal colony sounds'),
  ];

  @override
  void initState() {
    super.initState();
    // Continuous animation — shows the hive is alive
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
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
        color: RoBeeTheme.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RoBeeTheme.border),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

          // 7-bar waveform — continuous sin-wave animation
          SizedBox(
            height: 48,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BarWaveformPainter(
                    phase: _controller.value,
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

/// 7 bars with heights animated via sin waves, each offset by bar index.
/// Bars animate continuously to show the hive is alive.
class _BarWaveformPainter extends CustomPainter {
  final double phase; // 0.0 → 1.0 (looping)

  _BarWaveformPainter({required this.phase});

  static const int _barCount = 7;

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = _barCount;
    final totalSpacing = size.width * 0.12;
    final barWidth = (size.width - totalSpacing) / barCount;
    final gap = totalSpacing / (barCount - 1);
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      // Each bar gets a different phase offset so they animate independently
      final offset = i * (2 * math.pi / barCount);
      final t = phase * 2 * math.pi + offset;

      // Multiple sin components for organic feel
      final h1 = math.sin(t) * 0.35;
      final h2 = math.sin(t * 1.7 + 0.8) * 0.2;
      final h3 = math.sin(t * 0.5 + 1.2) * 0.15;
      final normalizedHeight = ((h1 + h2 + h3) + 0.85).clamp(0.15, 1.0);

      final barHeight = normalizedHeight * size.height * 0.85;
      final x = i * (barWidth + gap) + barWidth / 2;

      // Main bar
      final barPaint = Paint()
        ..color = RoBeeTheme.signalPurple.withOpacity(0.75)
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarWaveformPainter old) => old.phase != phase;
}
