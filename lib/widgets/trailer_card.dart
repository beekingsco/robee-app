import 'package:flutter/material.dart';
import '../models/trailer.dart';
import '../models/alert.dart';
import '../models/hive.dart';
import '../services/mock_data.dart';
import '../theme/robee_theme.dart';
import 'battery_indicator.dart';
import 'signal_bars.dart';

class TrailerCard extends StatefulWidget {
  final Trailer trailer;
  final List<RoBeeAlert> alerts;
  final VoidCallback? onTap;
  final VoidCallback? onSettingsTap;

  const TrailerCard({
    super.key,
    required this.trailer,
    required this.alerts,
    this.onTap,
    this.onSettingsTap,
  });

  @override
  State<TrailerCard> createState() => _TrailerCardState();
}

class _TrailerCardState extends State<TrailerCard> {
  bool _pressed = false;

  Color _healthColor(String status) => RoBeeTheme.healthColor(status);

  @override
  Widget build(BuildContext context) {
    final trailer = widget.trailer;
    final hives = MockData.hivesForTrailer(trailer.id);
    final hasCritical = widget.alerts.any((a) => a.severity == 'critical');
    final hasWarning = widget.alerts.any((a) => a.severity == 'warning');
    final unhealthyCount = hives
        .where((h) => h.healthStatus != 'healthy')
        .length;
    final healthySummary = unhealthyCount == 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: RoBeeTheme.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _pressed ? RoBeeTheme.amber.withOpacity(0.5) : RoBeeTheme.border,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Weather photo background — top portion of card
              Positioned(
                top: 0, left: 0, right: 0,
                height: 100,
                child: Image.network(
                  _weatherImageUrl(trailer),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: RoBeeTheme.panel),
                ),
              ),
              // Gradient overlay — photo fades into panel color
              Positioned(
                top: 0, left: 0, right: 0,
                height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.70),
                        RoBeeTheme.panel,
                      ],
                    ),
                  ),
                ),
              ),
              // Card content on top
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Name + gear + hive dots ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trailer.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (trailer.address != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 11, color: RoBeeTheme.glassWhite60),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                trailer.address!.split(',').first,
                                style: RoBeeTheme.bodyMedium.copyWith(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Settings gear
                GestureDetector(
                  onTap: widget.onSettingsTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: RoBeeTheme.panel,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RoBeeTheme.border),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 14,
                      color: RoBeeTheme.glassWhite60,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _HiveDotGrid(hives: hives),
              ],
            ),
            const SizedBox(height: 12),

            // ── Row 2: Health summary ────────────────────────────────────
            Text(
              healthySummary
                  ? 'All systems healthy'
                  : '$unhealthyCount hive${unhealthyCount > 1 ? 's' : ''} need attention',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: healthySummary
                    ? RoBeeTheme.healthGreen
                    : RoBeeTheme.healthYellow,
              ),
            ),
            const SizedBox(height: 12),

            // ── Footer: weather | signal | battery ───────────────────────
            Row(
              children: [
                _WeatherChip(trailer: trailer),
                const Spacer(),
                SignalBars(value: trailer.status == 'online' ? 85 : 15),
                const SizedBox(width: 12),
                BatteryIndicator(level: trailer.batteryLevel ?? 0),
              ],
            ),

            // ── Alert strip ───────────────────────────────────────────────
            if (widget.alerts.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (hasCritical ? RoBeeTheme.healthRed : RoBeeTheme.healthYellow)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (hasCritical
                            ? RoBeeTheme.healthRed
                            : RoBeeTheme.healthYellow)
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasCritical ? Icons.warning_rounded : Icons.info_outline,
                      size: 12,
                      color: hasCritical
                          ? RoBeeTheme.healthRed
                          : RoBeeTheme.healthYellow,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${widget.alerts.length} alert${widget.alerts.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: hasCritical
                            ? RoBeeTheme.healthRed
                            : RoBeeTheme.healthYellow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the weather photo URL based on trailer location/name.
  /// Uses live weather data from the trailer's coordinates when available,
  /// falls back to a sensible default.
  String _weatherImageUrl(Trailer trailer) {
    // In production this would use the live weather code from WeatherService.
    // For now, use trailer name to pick a default condition (demo).
    final name = trailer.name.toLowerCase();
    if (name.contains('canton')) {
      // Canton GA — often cloudy/overcast
      return 'https://images.unsplash.com/photo-1534088568595-a066f410bcda?q=80&w=800&auto=format&fit=crop';
    }
    // Default — clear sky apiary
    return 'https://images.unsplash.com/photo-1601297183305-6df142704ea2?q=80&w=800&auto=format&fit=crop';
  }
}

class _HiveDotGrid extends StatelessWidget {
  final List<Hive> hives;

  const _HiveDotGrid({required this.hives});

  Color _color(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return RoBeeTheme.healthGreen;
      case 'warning':
        return RoBeeTheme.healthYellow;
      case 'critical':
        return RoBeeTheme.healthRed;
      default:
        return RoBeeTheme.glassWhite60;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2 rows × 3 cols
    final padded = List<Hive?>.from(hives);
    while (padded.length < 6) padded.add(null);

    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: padded.sublist(0, 3).map((h) {
              return Padding(
                padding: const EdgeInsets.only(left: 5),
                child: _Dot(color: h != null ? _color(h.healthStatus) : Colors.transparent),
              );
            }).toList(),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: padded.sublist(3, 6).map((h) {
              return Padding(
                padding: const EdgeInsets.only(left: 5),
                child: _Dot(color: h != null ? _color(h.healthStatus) : Colors.transparent),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  final Trailer trailer;

  const _WeatherChip({required this.trailer});

  @override
  Widget build(BuildContext context) {
    // Mock weather based on location name
    final isNorth = trailer.name.toLowerCase().contains('canton') ||
        trailer.name.toLowerCase().contains('north');
    final temp = isNorth ? '68°F' : '74°F';
    final condition = isNorth ? 'Cloudy' : 'Clear';
    final humidity = isNorth ? '58%' : '63%';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(condition, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(width: 5),
        Text(
          '$temp · $humidity',
          style: RoBeeTheme.monoSmall.copyWith(
            color: RoBeeTheme.amber,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
