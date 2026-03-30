import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

class SignalBars extends StatelessWidget {
  final int value; // 0-100
  final double barWidth;
  final double maxHeight;

  const SignalBars({
    super.key,
    required this.value,
    this.barWidth = 5,
    this.maxHeight = 20,
  });

  @override
  Widget build(BuildContext context) {
    final activeBars = value >= 75
        ? 4
        : value >= 50
            ? 3
            : value >= 25
                ? 2
                : value > 0
                    ? 1
                    : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final isActive = i < activeBars;
        final barHeight = maxHeight * (0.35 + i * 0.22);
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Container(
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              color: isActive ? RoBeeTheme.signalPurple : RoBeeTheme.glassWhite20,
              borderRadius: BorderRadius.circular(2),

            ),
          ),
        );
      }),
    );
  }
}
