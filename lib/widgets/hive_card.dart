import 'package:flutter/material.dart';
import '../models/hive.dart';
import '../theme/robee_theme.dart';
import 'glass_card.dart';

enum HiveCardMode { minimal, full }

class HiveCard extends StatelessWidget {
  final Hive hive;
  final bool isServicing;
  final HiveCardMode mode;
  final VoidCallback? onTap;
  final String tempUnit;
  final String weightUnit;

  const HiveCard({
    super.key,
    required this.hive,
    this.isServicing = false,
    this.mode = HiveCardMode.minimal,
    this.onTap,
    this.tempUnit = 'F',
    this.weightUnit = 'lbs',
  });

  Color get _healthColor => RoBeeTheme.healthColor(hive.healthStatus);

  double _tempDisplay() {
    final t = hive.currentTemp ?? 0;
    if (tempUnit == 'F') return t; // already in F from mock
    return (t - 32) * 5 / 9;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        borderColor: isServicing
            ? RoBeeTheme.amber.withOpacity(0.6)
            : RoBeeTheme.border,
        child: mode == HiveCardMode.minimal
            ? _MinimalContent(
                hive: hive,
                isServicing: isServicing,
                healthColor: _healthColor,
                tempDisplay: _tempDisplay(),
                tempUnit: tempUnit,
                weightUnit: weightUnit,
              )
            : _FullContent(
                hive: hive,
                isServicing: isServicing,
                healthColor: _healthColor,
                tempDisplay: _tempDisplay(),
                tempUnit: tempUnit,
                weightUnit: weightUnit,
              ),
    );
  }
}

class _MinimalContent extends StatelessWidget {
  final Hive hive;
  final bool isServicing;
  final Color healthColor;
  final double tempDisplay;
  final String tempUnit;
  final String weightUnit;

  const _MinimalContent({
    required this.hive,
    required this.isServicing,
    required this.healthColor,
    required this.tempDisplay,
    required this.tempUnit,
    required this.weightUnit,
  });

  String get _lastInspected {
    // Mock "last inspected" based on hive number for variety
    final minutes = 20 + (hive.hiveNumber * 14) % 120;
    if (minutes < 60) return '${minutes}m ago';
    return '${(minutes / 60).floor()}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: healthColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hive.name,
                    style: RoBeeTheme.headlineMedium.copyWith(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isServicing)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: RoBeeTheme.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: RoBeeTheme.amber.withOpacity(0.4)),
                    ),
                    child: Text(
                      'SCAN',
                      style: RoBeeTheme.labelSmall.copyWith(
                        color: RoBeeTheme.amber,
                        fontSize: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${tempDisplay.toStringAsFixed(1)}°$tempUnit',
              style: RoBeeTheme.monoLarge.copyWith(fontSize: 12),
            ),
            Text(
              '${hive.currentWeight?.toStringAsFixed(1) ?? '--'} $weightUnit',
              style: RoBeeTheme.monoSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Last: $_lastInspected',
              style: RoBeeTheme.labelSmall.copyWith(fontSize: 8),
            ),
      ],
    );
  }
}

class _FullContent extends StatelessWidget {
  final Hive hive;
  final bool isServicing;
  final Color healthColor;
  final double tempDisplay;
  final String tempUnit;
  final String weightUnit;

  const _FullContent({
    required this.hive,
    required this.isServicing,
    required this.healthColor,
    required this.tempDisplay,
    required this.tempUnit,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: healthColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(hive.name, style: RoBeeTheme.headlineMedium),
            ),
            if (isServicing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoBeeTheme.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: RoBeeTheme.amber.withOpacity(0.4)),
                ),
                child: Text(
                  'SCANNING',
                  style: RoBeeTheme.labelSmall.copyWith(color: RoBeeTheme.amber),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _StatRow(
          icon: Icons.thermostat_rounded,
          label: 'Temp',
          value: '${tempDisplay.toStringAsFixed(1)}°$tempUnit',
        ),
        const SizedBox(height: 4),
        _StatRow(
          icon: Icons.water_drop_outlined,
          label: 'Humidity',
          value: '${hive.currentHumidity?.round() ?? '--'}%',
        ),
        const SizedBox(height: 4),
        _StatRow(
          icon: Icons.monitor_weight_outlined,
          label: 'Weight',
          value: '${hive.currentWeight?.toStringAsFixed(1) ?? '--'} $weightUnit',
        ),
        const SizedBox(height: 4),
        _StatRow(
          icon: Icons.emoji_nature_rounded,
          label: 'Queen',
          value: hive.queenStatus.toUpperCase(),
          valueColor: hive.queenStatus == 'present'
              ? RoBeeTheme.healthGreen
              : hive.queenStatus == 'absent'
                  ? RoBeeTheme.healthRed
                  : RoBeeTheme.healthYellow,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: RoBeeTheme.glassWhite60),
        const SizedBox(width: 6),
        Text(label, style: RoBeeTheme.bodyMedium.copyWith(fontSize: 12)),
        const Spacer(),
        Text(
          value,
          style: RoBeeTheme.monoSmall.copyWith(
            color: valueColor ?? Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
