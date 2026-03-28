import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../theme/robee_theme.dart';
import 'glass_card.dart';
import 'battery_indicator.dart';

class MetricsBar extends StatelessWidget {
  final WeatherData? weather;
  final double batteryLevel;
  final String tempUnit;

  const MetricsBar({
    super.key,
    this.weather,
    required this.batteryLevel,
    this.tempUnit = 'F',
  });

  String _formatTime(String? isoStr) {
    if (isoStr == null) return '--';
    try {
      final dt = DateTime.parse(isoStr);
      final h = dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = h >= 12 ? 'PM' : 'AM';
      final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$hour12:$m $ampm';
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nectarFlow = WeatherService.getNectarFlow();
    final nectarColor = nectarFlow == 'High'
        ? RoBeeTheme.healthGreen
        : nectarFlow == 'Moderate'
            ? RoBeeTheme.healthYellow
            : RoBeeTheme.healthRed;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MetricItem(
            icon: Icons.wb_twilight_rounded,
            label: 'Sunrise',
            value: _formatTime(weather?.sunrise),
            color: RoBeeTheme.amber,
          ),
          _MetricItem(
            icon: Icons.nightlight_round,
            label: 'Sunset',
            value: _formatTime(weather?.sunset),
            color: const Color(0xFF7C3AED),
          ),
          _MetricItem(
            icon: Icons.local_florist_rounded,
            label: 'Pollen',
            value: nectarFlow,
            color: nectarColor,
          ),
          _MetricItem(
            icon: Icons.water_drop_rounded,
            label: 'Nectar',
            value: nectarFlow,
            color: nectarColor,
          ),
          // Battery
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BatteryIndicator(level: batteryLevel, showLabel: false),
              const SizedBox(height: 2),
              Text(
                '${batteryLevel.round()}%',
                style: RoBeeTheme.monoSmall.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: RoBeeTheme.monoSmall.copyWith(color: color, fontSize: 11),
        ),
        Text(label, style: RoBeeTheme.labelSmall.copyWith(fontSize: 9)),
      ],
    );
  }
}
