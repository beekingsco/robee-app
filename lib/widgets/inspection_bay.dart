import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

class InspectionBay extends StatefulWidget {
  final int? activeHive;
  final int? activeFrame;
  final bool isScanning;
  final String boxType; // 'brood' | 'honey'
  final String moveLabel; // e.g. "MOVE H01-B03"

  const InspectionBay({
    super.key,
    this.activeHive,
    this.activeFrame,
    this.isScanning = false,
    this.boxType = 'brood',
    this.moveLabel = '',
  });

  @override
  State<InspectionBay> createState() => _InspectionBayState();
}

class _InspectionBayState extends State<InspectionBay>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    if (widget.isScanning) {
      _scanController.repeat();
    }
  }

  @override
  void didUpdateWidget(InspectionBay old) {
    super.didUpdateWidget(old);
    if (widget.isScanning && !_scanController.isAnimating) {
      _scanController.repeat();
    } else if (!widget.isScanning && _scanController.isAnimating) {
      _scanController.stop();
      _scanController.reset();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RoBeeTheme.glassWhite5,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isScanning
              ? RoBeeTheme.amber.withOpacity(0.4)
              : RoBeeTheme.glassWhite10,
        ),
        boxShadow: widget.isScanning ? RoBeeTheme.amberGlowSubtle : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          // Status label
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: widget.isScanning ? _pulseAnimation.value : 0.5,
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isScanning)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: RoBeeTheme.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  widget.isScanning ? 'INSPECTING' : 'STANDBY',
                  style: RoBeeTheme.labelSmall.copyWith(
                    color: widget.isScanning
                        ? RoBeeTheme.amber
                        : RoBeeTheme.glassWhite60,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Move label
          if (widget.moveLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (ctx, _) => Opacity(
                  opacity: _pulseAnimation.value,
                  child: Text(
                    widget.moveLabel,
                    style: RoBeeTheme.monoSmall.copyWith(
                      color: RoBeeTheme.amber,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),

          // Gantry viz
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _GantryPainter(
                      isScanning: widget.isScanning,
                      scanPos: _scanAnimation.value,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Info row
          if (widget.activeHive != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InfoPill(label: 'HIVE', value: '${widget.activeHive}'),
                  _InfoPill(
                    label: 'FRAME',
                    value: widget.activeFrame != null
                        ? '${widget.activeFrame! + 1}'
                        : '--',
                  ),
                  _InfoPill(
                    label: 'BOX',
                    value: widget.boxType == 'brood' ? 'BROOD' : 'HONEY',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _GantryPainter extends CustomPainter {
  final bool isScanning;
  final double scanPos;

  _GantryPainter({required this.isScanning, required this.scanPos});

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = RoBeeTheme.glassWhite10
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final gantryPaint = Paint()
      ..color = RoBeeTheme.glassWhite20
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final trackY1 = size.height * 0.18;
    final trackY2 = size.height * 0.82;

    // Track rails
    canvas.drawLine(
        Offset(0, trackY1), Offset(size.width, trackY1), trackPaint);
    canvas.drawLine(
        Offset(0, trackY2), Offset(size.width, trackY2), trackPaint);

    // Gantry carriage body
    final gantryX = size.width * 0.1 +
        (isScanning ? scanPos * (size.width * 0.8) : size.width * 0.4);

    // Gantry arm (vertical)
    canvas.drawLine(
      Offset(gantryX, trackY1),
      Offset(gantryX, trackY2),
      gantryPaint,
    );

    // Gantry rails attach points
    final attachPaint = Paint()
      ..color = RoBeeTheme.glassWhite20
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(gantryX, trackY1), 4, attachPaint);
    canvas.drawCircle(Offset(gantryX, trackY2), 4, attachPaint);

    // Camera/scanner head in middle
    if (isScanning) {
      final midY = (trackY1 + trackY2) / 2;

      // Glow
      final glowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            RoBeeTheme.amber.withOpacity(0.5),
            Colors.transparent,
          ],
        ).createShader(
            Rect.fromLTWH(gantryX - 3, trackY1, 6, trackY2 - trackY1))
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(gantryX, trackY1 + 6),
        Offset(gantryX, trackY2 - 6),
        glowPaint,
      );

      // Camera head (amber dot)
      final headPaint = Paint()
        ..color = RoBeeTheme.amber
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(gantryX, midY), 5.5, headPaint);

      // Camera lens ring
      final lensPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(gantryX, midY), 8, lensPaint);
    } else {
      final midY = (trackY1 + trackY2) / 2;
      final headPaint = Paint()
        ..color = RoBeeTheme.glassWhite20
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(gantryX, midY), 4, headPaint);
    }

    // Frame slot markers at bottom
    final framePaint = Paint()
      ..color = RoBeeTheme.glassWhite10
      ..strokeWidth = 1;
    for (int i = 1; i <= 9; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(
        Offset(x, trackY2 + 2),
        Offset(x, trackY2 + 8),
        framePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GantryPainter old) =>
      old.isScanning != isScanning || old.scanPos != scanPos;
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: RoBeeTheme.labelSmall),
        Text(
          value,
          style: RoBeeTheme.monoLarge.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
