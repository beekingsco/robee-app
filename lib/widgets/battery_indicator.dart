import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

class BatteryIndicator extends StatelessWidget {
  final double level; // 0-100
  final double width;
  final double height;
  final bool showLabel;

  const BatteryIndicator({
    super.key,
    required this.level,
    this.width = 32,
    this.height = 16,
    this.showLabel = true,
  });

  Color get _fillColor {
    if (level >= 50) return RoBeeTheme.healthGreen;
    if (level >= 20) return RoBeeTheme.healthYellow;
    return RoBeeTheme.healthRed;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(width, height),
          painter: _BatteryPainter(level: level.clamp(0, 100), fillColor: _fillColor),
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            '${level.round()}%',
            style: RoBeeTheme.monoSmall.copyWith(
              color: _fillColor,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final double level;
  final Color fillColor;

  _BatteryPainter({required this.level, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyWidth = size.width - 3;
    final bodyHeight = size.height;
    final radius = Radius.circular(bodyHeight * 0.2);

    // Outline
    final outlinePaint = Paint()
      ..color = RoBeeTheme.glassWhite20
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, bodyWidth, bodyHeight),
        radius,
      ),
      outlinePaint,
    );

    // Battery tip
    final tipPaint = Paint()
      ..color = RoBeeTheme.glassWhite20
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyWidth + 1, bodyHeight * 0.3, 2, bodyHeight * 0.4),
        const Radius.circular(1),
      ),
      tipPaint,
    );

    // Fill
    final fillWidth = (bodyWidth - 3) * (level / 100);
    if (fillWidth > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1.5, 1.5, fillWidth, bodyHeight - 3),
          Radius.circular(bodyHeight * 0.15),
        ),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BatteryPainter old) =>
      old.level != level || old.fillColor != fillColor;
}
