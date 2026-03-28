import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

class HiveDotCluster extends StatelessWidget {
  final List<String> hiveStatuses; // up to 6 health statuses

  const HiveDotCluster({
    super.key,
    required this.hiveStatuses,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = hiveStatuses.take(6).toList();
    while (statuses.length < 6) {
      statuses.add('unknown');
    }

    return SizedBox(
      width: 44,
      height: 28,
      child: CustomPaint(
        painter: _DotClusterPainter(statuses: statuses),
      ),
    );
  }
}

class _DotClusterPainter extends CustomPainter {
  final List<String> statuses;
  _DotClusterPainter({required this.statuses});

  Color _colorFor(String status) => RoBeeTheme.healthColor(status);

  @override
  void paint(Canvas canvas, Size size) {
    const dotRadius = 5.0;
    final cols = 2;
    final rows = 3;
    final colSpacing = size.width / (cols + 1);
    final rowSpacing = size.height / (rows + 1);

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final idx = row * cols + col;
        if (idx >= statuses.length) continue;

        final cx = colSpacing * (col + 1);
        final cy = rowSpacing * (row + 1);
        final color = _colorFor(statuses[idx]);

        // Glow
        final glowPaint = Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(cx, cy), dotRadius + 2, glowPaint);

        // Dot
        final dotPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotClusterPainter old) => old.statuses != statuses;
}
