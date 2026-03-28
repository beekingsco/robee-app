import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.onTap,
    this.borderRadius = 16,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RoBeeTheme.glassWhite5,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? RoBeeTheme.glassWhite10,
                width: 1,
              ),
              boxShadow: boxShadow,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
