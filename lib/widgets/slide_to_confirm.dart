import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

class SlideToConfirm extends StatefulWidget {
  final String label;
  final VoidCallback onConfirm;
  final Color? color;

  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirm,
    this.color,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _confirmed = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  static const double _thumbSize = 48;
  static const double _confirmThreshold = 0.8;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetAnimation = CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxOffset) {
    if (_confirmed) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, maxOffset);
    });
  }

  void _onHorizontalDragEnd(double maxOffset) {
    if (_confirmed) return;
    final ratio = _dragOffset / maxOffset;
    if (ratio >= _confirmThreshold) {
      setState(() => _confirmed = true);
      widget.onConfirm();
    } else {
      // Reset
      final startOffset = _dragOffset;
      _resetAnimation.addListener(() {
        if (mounted) {
          setState(() {
            _dragOffset = startOffset * (1 - _resetAnimation.value);
          });
        }
      });
      _resetController.forward(from: 0).then((_) {
        if (mounted) setState(() => _confirmed = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? RoBeeTheme.healthRed;

    return LayoutBuilder(builder: (context, constraints) {
      final trackWidth = constraints.maxWidth;
      final maxOffset = trackWidth - _thumbSize;

      return Container(
        height: _thumbSize,
        width: trackWidth,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            // Label
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: (1 - (_dragOffset / maxOffset).clamp(0.0, 1.0)),
                  child: Text(
                    _confirmed ? 'CONFIRMED' : widget.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            // Thumb
            AnimatedPositioned(
              duration: Duration.zero,
              left: _dragOffset,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) =>
                    _onHorizontalDragUpdate(d, maxOffset),
                onHorizontalDragEnd: (_) => _onHorizontalDragEnd(maxOffset),
                child: Container(
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: _confirmed ? color : color.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _confirmed ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
