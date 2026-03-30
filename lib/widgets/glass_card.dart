import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

/// Flat dark panel — Tesla aesthetic.
/// No blur, no shadow, no gradients. Just a flat Color(0xFF141210) card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double borderRadius;
  // boxShadow kept in signature for call-site compat but ignored (Tesla: no shadow)
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.onTap,
    this.borderRadius = 12,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RoBeeTheme.panel,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ?? RoBeeTheme.border,
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
