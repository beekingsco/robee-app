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
          // INSPECTION IN PROGRESS banner — full width, above SafeArea
          if (_isServicing)
            _TopInspectionBanner(hiveNumber: hive.hiveNumber),

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

  // Frame placeholder colors (flat panels — no photos)
  static const _placeholderColors = [
    Color(0xFF1A1510),
    Color(0xFF141210),
    Color(0xFF181410),
    Color(0xFF141210),
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
        final bgColor =
            _placeholderColors[imgIdx % _placeholderColors.length];
        imgIdx++;
        cards.add(_ScanCard(
          frameNumber: snap.frameNumber,
          boxType: snap.boxType,
          side: side,
          bgColor: bgColor,
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
  final Color bgColor;
  final String timeAgo;
  final bool hasQueen;

  const _ScanCard({
    required this.frameNumber,
    required this.boxType,
    required this.side,
    required this.bgColor,
    required this.timeAgo,
    required this.hasQueen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RoBeeTheme.border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Frame label tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: RoBeeTheme.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: RoBeeTheme.amber.withOpacity(0.3)),
            ),
            child: Text(
              '${boxType.toUpperCase()} F$frameNumber',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: RoBeeTheme.amber,
                letterSpacing: 0.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const Spacer(),
          // Scan placeholder — simple grid lines
          SizedBox(
            height: 40,
            child: CustomPaint(
              painter: _ScanPlaceholderPainter(),
              size: const Size(double.infinity, 40),
            ),
          ),
          const Spacer(),
          Text(
            side,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  timeAgo,
                  style: RoBeeTheme.monoSmall.copyWith(fontSize: 9),
                ),
              ),
              if (hasQueen)
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: RoBeeTheme.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('Q',
                        style: TextStyle(
                            fontSize: 8,
                            color: RoBeeTheme.amber,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = RoBeeTheme.glassWhite10
      ..strokeWidth = 0.5;
    // Horizontal grid lines
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical grid lines
    for (int i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Amber scan line in middle
    final scanPaint = Paint()
      ..color = RoBeeTheme.amber.withOpacity(0.4)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), scanPaint);
  }

  @override
  bool shouldRepaint(_ScanPlaceholderPainter _) => false;
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

/// Full-width amber bar above SafeArea — prominent inspection banner
class _TopInspectionBanner extends StatefulWidget {
  final int hiveNumber;
  const _TopInspectionBanner({required this.hiveNumber});

  @override
  State<_TopInspectionBanner> createState() => _TopInspectionBannerState();
}

class _TopInspectionBannerState extends State<_TopInspectionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.65, end: 1.0).animate(
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
    final topPadding = MediaQuery.of(context).padding.top;
    return AnimatedBuilder(
      animation: _opacity,
      builder: (ctx, child) {
        return Opacity(
          opacity: _opacity.value,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        color: RoBeeTheme.amber,
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 8),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🔍 RoBee is inspecting this hive',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
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
    final isCritical = hive.healthStatus.toLowerCase() == 'critical';
    final isWarning = hive.healthStatus.toLowerCase() == 'warning';

    // Critical → full red glass card. Healthy/warning → left border only.
    Widget container(Widget child) {
      if (isCritical) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: RoBeeTheme.healthRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RoBeeTheme.healthRed.withOpacity(0.4)),
          ),
          child: child,
        );
      }
      return GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: RoBeeTheme.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: isWarning
                    ? RoBeeTheme.healthYellow.withOpacity(0.7)
                    : RoBeeTheme.healthGreen.withOpacity(0.7),
                width: 3,
              ),
              top: BorderSide(color: RoBeeTheme.border),
              right: BorderSide(color: RoBeeTheme.border),
              bottom: BorderSide(color: RoBeeTheme.border),
            ),
          ),
          child: child,
        ),
      );
    }

    return container(Column(
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
            GestureDetector(
              onTap: onToggle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expanded ? 'Hide' : 'Details',
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
                color: RoBeeTheme.panel,
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
