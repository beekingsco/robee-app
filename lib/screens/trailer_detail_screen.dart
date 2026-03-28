import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/trailer.dart';
import '../models/hive.dart';
import '../services/mock_data.dart';
import '../services/supabase_service.dart';
import '../services/weather_service.dart';
import '../theme/robee_theme.dart';
import '../widgets/weather_background.dart';
import '../widgets/metrics_bar.dart';
import '../widgets/hive_card.dart';
import '../widgets/inspection_bay.dart';
import '../widgets/glass_card.dart';

class TrailerDetailScreen extends StatefulWidget {
  final String trailerId;

  const TrailerDetailScreen({super.key, required this.trailerId});

  @override
  State<TrailerDetailScreen> createState() => _TrailerDetailScreenState();
}

class _TrailerDetailScreenState extends State<TrailerDetailScreen> {
  Trailer? _trailer;
  List<Hive> _hives = [];
  WeatherData? _weather;
  Timer? _clockTimer;
  Timer? _inspectionTimer;
  DateTime _now = DateTime.now();

  // Inspection sim state
  int? _activeHiveIndex;
  int? _activeFrameIndex;
  String _activeBoxType = 'brood';
  bool _isInspecting = false;

  // Sequence: H1, H4, H2, H5, H3, H6 (0-indexed)
  static const _inspectionSequence = [0, 3, 1, 4, 2, 5];
  static const _secondsPerFrame = 14; // faster for demo

  @override
  void initState() {
    super.initState();
    _load();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _inspectionTimer =
        Timer.periodic(const Duration(seconds: _secondsPerFrame), (_) {
      _advanceInspection();
    });
    _checkInspectionWindow();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _inspectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    Trailer? t;
    List<Hive> h = [];
    try {
      final svc = SupabaseService();
      if (svc.isSignedIn) {
        final trailers = await svc.getTrailers();
        t = trailers.firstWhere(
          (x) => x.id == widget.trailerId,
          orElse: () => MockData.trailers.first,
        );
        h = await svc.getHives(widget.trailerId);
      }
    } catch (_) {}

    t ??= MockData.trailers.firstWhere(
      (x) => x.id == widget.trailerId,
      orElse: () => MockData.trailers.first,
    );
    if (h.isEmpty) h = MockData.hivesForTrailer(widget.trailerId);

    if (mounted) {
      setState(() {
        _trailer = t;
        _hives = h;
      });
    }

    final loc = t.currentLocation;
    if (loc != null) {
      final w = await WeatherService.getWeather(
        loc['lat'] ?? 34.0,
        loc['lng'] ?? -84.0,
      );
      if (mounted) setState(() => _weather = w);
    }
  }

  void _checkInspectionWindow() {
    final h = _now.hour;
    if (h >= 9 && h < 16) {
      if (!_isInspecting) {
        setState(() {
          _isInspecting = true;
          _activeHiveIndex = 0;
          _activeFrameIndex = 0;
          _activeBoxType = 'brood';
        });
      }
    } else {
      // For demo: always start inspecting
      setState(() {
        _isInspecting = true;
        _activeHiveIndex = 0;
        _activeFrameIndex = 0;
        _activeBoxType = 'brood';
      });
    }
  }

  void _advanceInspection() {
    if (!_isInspecting || !mounted) return;

    setState(() {
      final hivePos = _inspectionSequence.indexOf(_activeHiveIndex ?? 0);
      var nextFrame = (_activeFrameIndex ?? 0) + 1;

      if (_activeBoxType == 'brood' && nextFrame >= 9) {
        _activeBoxType = 'honey';
        _activeFrameIndex = 0;
      } else if (_activeBoxType == 'honey' && nextFrame >= 7) {
        final nextHivePos = (hivePos + 1) % _inspectionSequence.length;
        _activeHiveIndex = _inspectionSequence[nextHivePos];
        _activeBoxType = 'brood';
        _activeFrameIndex = 0;
      } else {
        _activeFrameIndex = nextFrame;
      }
    });
  }

  String _clockStr() {
    final h = _now.hour;
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m:$s $ampm';
  }

  int get _weatherCode => _weather?.conditionCode ?? 0;
  bool get _isDay => _weather?.isDay ?? true;

  @override
  Widget build(BuildContext context) {
    if (_trailer == null) {
      return const Scaffold(
        backgroundColor: RoBeeTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: RoBeeTheme.amber),
        ),
      );
    }

    final t = _trailer!;
    final leftHives = _hives.where((h) => h.hiveNumber <= 3).toList();
    final rightHives = _hives.where((h) => h.hiveNumber >= 4).toList();
    final activeHiveNumber =
        _activeHiveIndex != null ? (_activeHiveIndex! + 1) : null;

    // Build the "MOVE H0X-F0X" label
    String moveLabel = '';
    if (_isInspecting && activeHiveNumber != null) {
      final frameNum = (_activeFrameIndex ?? 0) + 1;
      final boxShort = _activeBoxType == 'brood' ? 'B' : 'H';
      moveLabel = 'MOVE H${activeHiveNumber.toString().padLeft(2, '0')}-$boxShort${frameNum.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      backgroundColor: RoBeeTheme.background,
      body: WeatherBackground(
        weatherCode: _weatherCode,
        isDay: _isDay,
        child: SafeArea(
          child: Column(
            children: [
              // Compact header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back_ios_rounded,
                            size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: RoBeeTheme.headlineLarge
                                    .copyWith(fontSize: 17)),
                            if (t.trailerNumber != null)
                              Text(t.trailerNumber!,
                                  style: RoBeeTheme.monoSmall
                                      .copyWith(fontSize: 9)),
                          ],
                        ),
                      ),
                      // Right side: clock + weather
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _clockStr(),
                            style: RoBeeTheme.monoLarge.copyWith(fontSize: 12),
                          ),
                          if (_weather != null)
                            Text(
                              '${WeatherService.weatherEmoji(_weatherCode, _isDay)} ${(_weather!.temperature * 9 / 5 + 32).round()}°F',
                              style: RoBeeTheme.bodyMedium
                                  .copyWith(fontSize: 10),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () =>
                            context.push('/trailers/${t.id}/settings'),
                        child: const Icon(Icons.settings_outlined,
                            size: 18, color: RoBeeTheme.glassWhite60),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Metrics bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MetricsBar(
                  weather: _weather,
                  batteryLevel: t.batteryLevel ?? 0,
                  tempUnit: t.tempUnit,
                ),
              ),
              const SizedBox(height: 6),

              // Main 3-column layout
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left column: hives 1-3
                      Expanded(
                        flex: 3,
                        child: _HiveColumn(
                          hives: leftHives,
                          activeHiveNumber: activeHiveNumber,
                          isInspecting: _isInspecting,
                          trailerId: widget.trailerId,
                          tempUnit: t.tempUnit,
                          weightUnit: t.weightUnit,
                        ),
                      ),
                      const SizedBox(width: 5),

                      // Center: InspectionBay with move label
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: [
                              Expanded(
                                child: InspectionBay(
                                  activeHive: activeHiveNumber,
                                  activeFrame: _activeFrameIndex,
                                  isScanning: _isInspecting,
                                  boxType: _activeBoxType,
                                  moveLabel: moveLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),

                      // Right column: hives 4-6
                      Expanded(
                        flex: 3,
                        child: _HiveColumn(
                          hives: rightHives,
                          activeHiveNumber: activeHiveNumber,
                          isInspecting: _isInspecting,
                          trailerId: widget.trailerId,
                          tempUnit: t.tempUnit,
                          weightUnit: t.weightUnit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HiveColumn extends StatelessWidget {
  final List<Hive> hives;
  final int? activeHiveNumber;
  final bool isInspecting;
  final String trailerId;
  final String tempUnit;
  final String weightUnit;

  const _HiveColumn({
    required this.hives,
    required this.activeHiveNumber,
    required this.isInspecting,
    required this.trailerId,
    required this.tempUnit,
    required this.weightUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: hives.map((hive) {
        final isServicing =
            isInspecting && hive.hiveNumber == activeHiveNumber;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: HiveCard(
              hive: hive,
              isServicing: isServicing,
              mode: HiveCardMode.minimal,
              tempUnit: tempUnit,
              weightUnit: weightUnit,
              onTap: () => context.push('/hives/${hive.id}'),
            ),
          ),
        );
      }).toList(),
    );
  }
}
