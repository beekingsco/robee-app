import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

class HiveActionsBar extends StatelessWidget {
  final VoidCallback? onInspect;
  final VoidCallback? onOpenEntrance;
  final VoidCallback? onCloseEntrance;
  final VoidCallback? onFeed;
  final VoidCallback? onEmergencyStop;

  const HiveActionsBar({
    super.key,
    this.onInspect,
    this.onOpenEntrance,
    this.onCloseEntrance,
    this.onFeed,
    this.onEmergencyStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RoBeeTheme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RoBeeTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.search_rounded,
            label: 'Inspect',
            color: RoBeeTheme.amber,
            onTap: onInspect,
          ),
          _ActionButton(
            icon: Icons.login_rounded,
            label: 'Open',
            color: RoBeeTheme.healthGreen,
            onTap: onOpenEntrance,
          ),
          _ActionButton(
            icon: Icons.logout_rounded,
            label: 'Close',
            color: RoBeeTheme.glassWhite60,
            onTap: onCloseEntrance,
          ),
          _ActionButton(
            icon: Icons.water_drop_rounded,
            label: 'Feed',
            color: RoBeeTheme.signalPurple,
            onTap: onFeed,
          ),
          _ActionButton(
            icon: Icons.stop_circle_rounded,
            label: 'E-Stop',
            color: RoBeeTheme.healthRed,
            onTap: onEmergencyStop,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: RoBeeTheme.labelSmall.copyWith(
              color: color,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
