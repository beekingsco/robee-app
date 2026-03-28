import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/hive.dart';
import '../models/alert.dart';
import '../models/frame_snapshot.dart';
import '../services/mock_data.dart';
import '../services/supabase_service.dart';
import '../theme/robee_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/frame_visualizer.dart';
import '../widgets/audio_monitor.dart';
import '../widgets/telemetry_graph.dart';
import '../widgets/hive_actions_bar.dart';

class HiveDetailScreen extends StatefulWidget {
  final String hiveId;

  const HiveDetailScreen({super.key, required this.hiveId});

  @override
  State<HiveDetailScreen> createState() => _HiveDetailScreenState();
}

class _HiveDetailScreenState extends State<HiveDetailScreen> {
  Hive? _hive;
  List<RoBeeAlert> _alerts = [];
  List<FrameSnapshot> _snapshots = [];
  bool _healthExpanded = false;
  int? _selectedBroodFrame;
  int? _selectedHoneyFrame;
  bool _loading = true;
  // Simulate one hive always being scanned for demo
  bool get _isServicing => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Hive? hive;
    List<RoBeeAlert> alerts = [];
    List<FrameSnapshot> snapshots = [];

    try {
      final svc = SupabaseService();
      if (svc.isSignedIn) {
        final hives = await svc.getHives('');
        hive = hives.firstWhere(
          (h) => h.id == widget.hiveId,
          orElse: () => MockData.hives.first,
        );
        alerts = await svc.getAlerts();
        alerts = alerts.where((a) => a.hiveId == widget.hiveId).toList();
        snapshots = await svc.getFrameSnapshots(widget.hiveId);
      }
    } catch (_) {}

    hive ??= MockData.hives.firstWhere(
      (h) => h.id == widget.hiveId,
      orElse: () => MockData.hives.first,
    );
    if (alerts.isEmpty) {
      alerts = MockData.alertsForTrailer(hive.trailerId)
          .where((a) => a.hiveId == widget.hiveId)
          .toList();
    }
    if (snapshots.isEmpty) {
      snapshots = MockData.snapshotsForHive(widget.hiveId);
    }

    if (mounted) {
      setState(() {
        _hive = hive;
        _alerts = alerts;
        _snapshots = snapshots;
        _loading = false;
      });
    }
  }

  void _showAction(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — mock mode')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _hive == null) {
      return const Scaffold(
        backgroundColor: RoBeeTheme.background,
        body: Center(child: CircularProgressIndicator(color: RoBeeTheme.amber)),
      );
    }

    final hive = _hive!;
    final healthColor = RoBeeTheme.healthColor(hive.healthStatus);

    // Find trailer name
    final trailer = MockData.trailers.firstWhere(
      (t) => t.id == hive.trailerId,
      orElse: () => MockData.trailers.first,
    );

    final tempData = MockData.temperatureHistory(hive.id);
    final humData = MockData.humidityHistory(hive.id);
    final weightData = MockData.weightHistory(hive.id);

    return Scaffold(
      backgroundColor: RoBeeTheme.background,
      body: Stack(
        children: [
          // Full-bleed background with gradient
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  RoBeeTheme.background.withOpacity(0.7),
                  RoBeeTheme.background,
                ],
                stops: const [0.0, 0.35, 0.65],
              ).createShader(bounds),
              blendMode: BlendMode.darken,
              child: Image.network(
                'https://images.unsplash.com/photo-1587593810167-a84920ea0781?q=80&w=2070',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.2,
                      colors: [
                        healthColor.withOpacity(0.15),
                        RoBeeTheme.background,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Health color tint overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    healthColor.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Back row + buttons
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_back_ios_rounded,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                            const Spacer(),
                            _ChipButton(
                              icon: Icons.bar_chart_rounded,
                              label: 'Activity',
                              onTap: () {},
                            ),
                            const SizedBox(width: 8),
                            _ChipButton(
                              icon: Icons.notifications_outlined,
                              label: _alerts.isNotEmpty
                                  ? 'Alerts (${_alerts.length})'
                                  : 'Alerts',
                              onTap: () => context.push('/alerts'),
                              color: _alerts.isNotEmpty
                                  ? RoBeeTheme.healthRed
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Hive name header — large, bold
                        Text(
                          hive.name,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '@${trailer.name}',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: healthColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: healthColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                hive.healthStatus.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: healthColor,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // INSPECTION IN PROGRESS banner (shown when isServicing)
                        if (_isServicing)
                          _InspectionBanner(hiveNumber: hive.hiveNumber),
                        if (_isServicing) const SizedBox(height: 12),

                        // Health status banner
                        _HealthBanner(
                          hive: hive,
                          expanded: _healthExpanded,
                          onToggle: () => setState(
                              () => _healthExpanded = !_healthExpanded),
                        ),
                        const SizedBox(height: 20),

                        // Frame Visualizer
                        Text(
                          'FRAME MAP',
                          style: RoBeeTheme.labelLarge.copyWith(letterSpacing: 2),
                        ),
                        const SizedBox(height: 10),
                        GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: FrameVisualizer(
                            selectedBroodFrame: _selectedBroodFrame,
                            selectedHoneyFrame: _selectedHoneyFrame,
                            activeBroodFrame: _isServicing ? 2 : null,
                            onBroodFrameSelect: (i) =>
                                setState(() => _selectedBroodFrame = i),
                            onHoneyFrameSelect: (i) =>
                                setState(() => _selectedHoneyFrame = i),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Frame Scan Gallery
                        Text(
                          'RECENT SCANS',
                          style: RoBeeTheme.labelLarge.copyWith(letterSpacing: 2),
                        ),
                        const SizedBox(height: 10),
                        _FrameScanGallery(
                          snapshots: _snapshots,
                          hiveId: hive.id,
                        ),
                        const SizedBox(height: 20),

                        // Audio Monitor
                        AudioMonitor(hiveId: hive.id),
                        const SizedBox(height: 20),

                        // Telemetry charts row
                        Text(
                          'TELEMETRY',
                          style: RoBeeTheme.labelLarge.copyWith(letterSpacing: 2),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: Row(
                            children: [
                              Expanded(
                                child: TelemetryGraph(
                                  data: weightData,
                                  type: 'weight',
                                  color: RoBeeTheme.healthGreen,
                                  title: 'Weight',
                                  unit: 'lbs',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TelemetryGraph(
                                  data: tempData,
                                  type: 'temperature',
                                  color: RoBeeTheme.amber,
                                  title: 'Temp',
                                  unit: '°F',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TelemetryGraph(
                                  data: humData,
                                  type: 'humidity',
                                  color: RoBeeTheme.signalPurple,
                                  title: 'Humidity',
                                  unit: '%',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Alert cards
                        if (_alerts.isNotEmpty) ...[
                          Text(
                            'ALERTS',
                            style: RoBeeTheme.labelLarge.copyWith(letterSpacing: 2),
                          ),
                          const SizedBox(height: 10),
                          ..._alerts.map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _AlertCard(alert: a),
                              )),
                          const SizedBox(height: 12),
                        ],

                        // Actions bar
                        HiveActionsBar(
                          onInspect: () => _showAction('Inspect Now'),
                          onOpenEntrance: () => _showAction('Open Entrance'),
                          onCloseEntrance: () => _showAction('Close Entrance'),
                          onFeed: () => _showAction('Feed'),
                          onEmergencyStop: () => _showAction('Emergency Stop'),
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Frame Scan Gallery ────────────────────────────────────────────────────────
class _FrameScanGallery extends StatelessWidget {
  final List<FrameSnapshot> snapshots;
  final String hiveId;

  const _FrameScanGallery({required this.snapshots, required this.hiveId});

  // Unsplash hive placeholder images
  static const _placeholders = [
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?q=80&w=400',
    'https://images.unsplash.com/photo-1573601127946-c37b79b28dac?q=80&w=400',
    'https://images.unsplash.com/photo-1587593810167-a84920ea0781?q=80&w=400',
    'https://images.unsplash.com/photo-1568254183919-78a4f43a2877?q=80&w=400',
  ];

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    // Build scan cards: at least 4 (Side A + Side B for 2 frames)
    final cards = <Widget>[];

    // Use snapshots or generate mock ones
    final frames = snapshots.isNotEmpty
        ? snapshots.take(2).toList()
        : [
            FrameSnapshot(
              id: 'mock-1',
              hiveId: hiveId,
              frameNumber: 2,
              boxType: 'brood',
              inspectionId: 'mock',
              fullnessPercent: 82,
              hasQueen: true,
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            ),
            FrameSnapshot(
              id: 'mock-2',
              hiveId: hiveId,
              frameNumber: 4,
              boxType: 'brood',
              inspectionId: 'mock',
              fullnessPercent: 65,
              hasQueen: false,
              timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
            ),
          ];

    int imgIdx = 0;
    for (final snap in frames) {
      for (final side in ['Side A', 'Side B']) {
        final url = _placeholders[imgIdx % _placeholders.length];
        imgIdx++;
        cards.add(_ScanCard(
          frameNumber: snap.frameNumber,
          boxType: snap.boxType,
          side: side,
          imageUrl: url,
          timeAgo: _timeAgo(snap.timestamp),
          hasQueen: side == 'Side A' && (snap.hasQueen ?? false),
        ));
      }
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final int frameNumber;
  final String boxType;
  final String side;
  final String imageUrl;
  final String timeAgo;
  final bool hasQueen;

  const _ScanCard({
    required this.frameNumber,
    required this.boxType,
    required this.side,
    required this.imageUrl,
    required this.timeAgo,
    required this.hasQueen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RoBeeTheme.glassWhite10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Image
          Positioned.fill(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1A1208),
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      color: RoBeeTheme.glassWhite60),
                ),
              ),
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC0C0A09)],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
          ),
          // Labels
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: RoBeeTheme.amber.withOpacity(0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${boxType.toUpperCase()} F$frameNumber',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          if (hasQueen)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.star_rounded, color: RoBeeTheme.amber, size: 14),
            ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  side,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? RoBeeTheme.glassWhite60;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: RoBeeTheme.labelSmall.copyWith(color: c, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _InspectionBanner extends StatefulWidget {
  final int hiveNumber;
  const _InspectionBanner({required this.hiveNumber});

  @override
  State<_InspectionBanner> createState() => _InspectionBannerState();
}

class _InspectionBannerState extends State<_InspectionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (ctx, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: RoBeeTheme.amber.withOpacity(0.08 + 0.04 * _pulse.value),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: RoBeeTheme.amber.withOpacity(0.3 + 0.2 * _pulse.value),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: RoBeeTheme.amber.withOpacity(_pulse.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: RoBeeTheme.amber.withOpacity(_pulse.value * 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSPECTION IN PROGRESS',
                      style: TextStyle(
                        color: RoBeeTheme.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'RoBee is currently inspecting this hive',
                      style: RoBeeTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HealthBanner extends StatelessWidget {
  final Hive hive;
  final bool expanded;
  final VoidCallback onToggle;

  const _HealthBanner({
    required this.hive,
    required this.expanded,
    required this.onToggle,
  });

  String get _statusText {
    switch (hive.healthStatus.toLowerCase()) {
      case 'healthy':
        return 'Colony Healthy';
      case 'warning':
        return 'Attention Required';
      case 'critical':
        return 'CRITICAL';
      default:
        return hive.healthStatus.toUpperCase();
    }
  }

  IconData get _statusIcon {
    switch (hive.healthStatus.toLowerCase()) {
      case 'healthy':
        return Icons.check_circle_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'critical':
        return Icons.error_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RoBeeTheme.healthColor(hive.healthStatus);
    return GlassCard(
      onTap: onToggle,
      borderColor: c.withOpacity(0.4),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_statusIcon, color: c, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _statusText,
                  style: TextStyle(
                    color: c,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onToggle,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      expanded ? 'Hide' : 'Show Advanced Data',
                      style: TextStyle(
                        color: RoBeeTheme.glassWhite60,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: RoBeeTheme.glassWhite60,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            const Divider(color: RoBeeTheme.glassWhite10),
            const SizedBox(height: 10),
            // Brood temp
            _AdvancedRow(
              label: 'Brood Temp',
              value: '${hive.currentTemp?.toStringAsFixed(1) ?? "--"}°F',
              target: 'Target: 93–97°F',
              color: hive.currentTemp != null &&
                      hive.currentTemp! >= 93 &&
                      hive.currentTemp! <= 97
                  ? RoBeeTheme.healthGreen
                  : RoBeeTheme.healthYellow,
            ),
            const SizedBox(height: 8),
            // Humidity
            _AdvancedRow(
              label: 'Humidity',
              value: '${hive.currentHumidity?.round() ?? "--"}%',
              target: 'Target: 50–65%',
              color: hive.currentHumidity != null &&
                      hive.currentHumidity! >= 50 &&
                      hive.currentHumidity! <= 65
                  ? RoBeeTheme.healthGreen
                  : RoBeeTheme.healthYellow,
            ),
            const SizedBox(height: 8),
            // Weight
            _AdvancedRow(
              label: 'Colony Weight',
              value: '${hive.currentWeight?.toStringAsFixed(1) ?? "--"} lbs',
              target: 'Baseline: 80+ lbs',
              color: hive.currentWeight != null && hive.currentWeight! >= 80
                  ? RoBeeTheme.healthGreen
                  : RoBeeTheme.healthYellow,
            ),
            const SizedBox(height: 8),
            _AdvancedRow(
              label: 'Queen Status',
              value: hive.queenStatus.toUpperCase(),
              target: hive.queenStatus == 'present'
                  ? 'Queen confirmed'
                  : 'Requires inspection',
              color: RoBeeTheme.healthColor(
                  hive.queenStatus == 'present' ? 'healthy' : 'critical'),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: RoBeeTheme.glassWhite5,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hive.healthStatus == 'healthy'
                    ? 'Colony is thriving. Brood pattern is solid and population is strong. No intervention needed at this time.'
                    : hive.healthStatus == 'warning'
                        ? 'Some metrics outside optimal range. Monitor closely. Consider a manual inspection within 48 hours.'
                        : 'Immediate attention required. Queen may be absent or the colony is under stress. Inspect ASAP.',
                style: RoBeeTheme.bodyMedium.copyWith(fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdvancedRow extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final Color color;

  const _AdvancedRow({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: RoBeeTheme.bodyMedium.copyWith(fontSize: 12)),
              Text(target,
                  style: RoBeeTheme.labelSmall.copyWith(fontSize: 9)),
            ],
          ),
        ),
        Text(
          value,
          style: RoBeeTheme.monoSmall.copyWith(color: color, fontSize: 12),
        ),
        const SizedBox(width: 6),
        Icon(Icons.circle, size: 8, color: color),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final RoBeeAlert alert;
  const _AlertCard({required this.alert});

  Color get _severityColor {
    switch (alert.severity) {
      case 'critical':
        return RoBeeTheme.healthRed;
      case 'warning':
        return RoBeeTheme.healthYellow;
      default:
        return RoBeeTheme.glassWhite60;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final c = _severityColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                alert.severity == 'critical'
                    ? Icons.error_rounded
                    : alert.severity == 'warning'
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded,
                color: c,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(alert.title,
                    style: RoBeeTheme.headlineMedium
                        .copyWith(color: c, fontSize: 13)),
              ),
              Text(
                _timeAgo(alert.createdAt),
                style: RoBeeTheme.labelSmall.copyWith(fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(alert.message,
              style: RoBeeTheme.bodyMedium.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
