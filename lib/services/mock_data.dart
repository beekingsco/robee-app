import '../models/trailer.dart';
import '../models/hive.dart';
import '../models/alert.dart';
import '../models/frame_snapshot.dart';

/// MockData — demo data so the app looks great without a backend.
class MockData {
  MockData._();

  // ── Trailers ───────────────────────────────────────────────────────────────
  static final List<Trailer> trailers = [
    const Trailer(
      id: 'trailer-canton-001',
      name: 'Canton Demo',
      trailerNumber: 'RBEE-2024-001',
      status: 'online',
      address: '123 Honeybee Lane, Canton, GA 30114',
      timezone: 'America/New_York',
      batteryLevel: 87.0,
      storageUsage: 42.0,
      tempUnit: 'F',
      weightUnit: 'lbs',
      inspectionFrequency: 'daily',
      currentLocation: {'lat': 34.2365, 'lng': -84.4921},
      sharedWith: ['partner@example.com'],
      archived: false,
    ),
    const Trailer(
      id: 'trailer-auburn-002',
      name: 'Auburn Demo',
      trailerNumber: 'RBEE-2024-002',
      status: 'online',
      address: '456 Clover Field Rd, Auburn, AL 36830',
      timezone: 'America/Chicago',
      batteryLevel: 64.0,
      storageUsage: 28.0,
      tempUnit: 'F',
      weightUnit: 'lbs',
      inspectionFrequency: 'weekly',
      currentLocation: {'lat': 32.6099, 'lng': -85.4808},
      sharedWith: [],
      archived: false,
    ),
  ];

  // ── Hives ──────────────────────────────────────────────────────────────────
  static final List<Hive> hives = [
    // Canton hives
    Hive(
      id: 'hive-c1',
      name: 'Hive 1',
      trailerId: 'trailer-canton-001',
      hiveNumber: 1,
      currentTemp: 95.2,
      currentHumidity: 62.0,
      currentWeight: 84.6,
      queenStatus: 'present',
      entranceState: 'open',
      boxOrientation: 'brood_near_rail',
      healthStatus: 'healthy',
    ),
    Hive(
      id: 'hive-c2',
      name: 'Hive 2',
      trailerId: 'trailer-canton-001',
      hiveNumber: 2,
      currentTemp: 93.8,
      currentHumidity: 58.0,
      currentWeight: 76.2,
      queenStatus: 'present',
      entranceState: 'open',
      boxOrientation: 'brood_near_rail',
      healthStatus: 'healthy',
    ),
    Hive(
      id: 'hive-c3',
      name: 'Hive 3',
      trailerId: 'trailer-canton-001',
      hiveNumber: 3,
      currentTemp: 91.4,
      currentHumidity: 70.0,
      currentWeight: 69.8,
      queenStatus: 'unknown',
      entranceState: 'open',
      boxOrientation: 'brood_far_rail',
      healthStatus: 'warning',
    ),
    Hive(
      id: 'hive-c4',
      name: 'Hive 4',
      trailerId: 'trailer-canton-001',
      hiveNumber: 4,
      currentTemp: 96.1,
      currentHumidity: 60.0,
      currentWeight: 91.3,
      queenStatus: 'present',
      entranceState: 'open',
      boxOrientation: 'brood_near_rail',
      healthStatus: 'healthy',
    ),
    Hive(
      id: 'hive-c5',
      name: 'Hive 5',
      trailerId: 'trailer-canton-001',
      hiveNumber: 5,
      currentTemp: 88.7,
      currentHumidity: 75.0,
      currentWeight: 52.1,
      queenStatus: 'absent',
      entranceState: 'closed',
      boxOrientation: 'brood_near_rail',
      healthStatus: 'critical',
    ),
    Hive(
      id: 'hive-c6',
      name: 'Hive 6',
      trailerId: 'trailer-canton-001',
      hiveNumber: 6,
      currentTemp: 94.5,
      currentHumidity: 61.0,
      currentWeight: 79.4,
      queenStatus: 'present',
      entranceState: 'open',
      boxOrientation: 'brood_far_rail',
      healthStatus: 'healthy',
    ),
    // Auburn hives
    Hive(
      id: 'hive-a1',
      name: 'Hive 1',
      trailerId: 'trailer-auburn-002',
      hiveNumber: 1,
      currentTemp: 94.0,
      currentHumidity: 59.0,
      currentWeight: 88.2,
      queenStatus: 'present',
      entranceState: 'open',
      boxOrientation: 'brood_near_rail',
      healthStatus: 'healthy',
    ),
    Hive(
      id: 'hive-a2',
      name: 'Hive 2',
      trailerId: 'trailer-auburn-002',
      hiveNumber: 2,
      currentTemp: 92.3,
      currentHumidity: 63.0,
      currentWeight: 73.5,
      queenStatus: 'present',
      entranceState: 'open',
      boxOrientation: 'brood_near_rail',
      healthStatus: 'healthy',
    ),
    Hive(
      id: 'hive-a3',
      name: 'Hive 3',
      trailerId: 'trailer-auburn-002',
      hiveNumber: 3,
      currentTemp: 89.6,
      currentHumidity: 68.0,
      currentWeight: 61.7,
      queenStatus: 'unknown',
      entranceState: 'open',
      boxOrientation: 'brood_far_rail',
      healthStatus: 'warning',
    ),
    Hive(
      id: 'hive-a4',
      name: 'Hive 4',
      trailerId: 'trailer-auburn-002',
      hiveNumber: 4,
      currentTemp: 95.8,
      currentHumidity: 57.0,
      currentWeight: 95.1,
      queenStatus: 'present',
      entranceState: 'open',
      boxOrientation: 'brood_near_rail',
      healthStatus: 'healthy',
    ),
    Hive(
      id: 'hive-a5',
      name: 'Hive 5',
      trailerId: 'trailer-auburn-002',
      hiveNumber: 5,
      currentTemp: 93.2,
      currentHumidity: 61.0,
      currentWeight: 81.4,
      queenStatus: 'present',
      entranceState: 'open',
      boxOrientation: 'brood_near_rail',
      healthStatus: 'healthy',
    ),
    Hive(
      id: 'hive-a6',
      name: 'Hive 6',
      trailerId: 'trailer-auburn-002',
      hiveNumber: 6,
      currentTemp: 91.0,
      currentHumidity: 66.0,
      currentWeight: 68.9,
      queenStatus: 'present',
      entranceState: 'open',
      boxOrientation: 'brood_far_rail',
      healthStatus: 'healthy',
    ),
  ];

  // ── Alerts ─────────────────────────────────────────────────────────────────
  static final List<RoBeeAlert> alerts = [
    RoBeeAlert(
      id: 'alert-001',
      title: 'Queen Absent — Hive 5',
      message:
          'No queen detected during last 3 inspections. Colony may be queenless. Immediate action recommended.',
      severity: 'critical',
      trailerId: 'trailer-canton-001',
      hiveId: 'hive-c5',
      isResolved: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    RoBeeAlert(
      id: 'alert-002',
      title: 'Low Weight — Hive 5',
      message:
          'Hive 5 weight dropped 12 lbs over the past 48 hours. Check food stores.',
      severity: 'warning',
      trailerId: 'trailer-canton-001',
      hiveId: 'hive-c5',
      isResolved: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    RoBeeAlert(
      id: 'alert-003',
      title: 'High Humidity — Hive 3',
      message:
          'Humidity reading 70% exceeds recommended 65%. Improve ventilation.',
      severity: 'warning',
      trailerId: 'trailer-canton-001',
      hiveId: 'hive-c3',
      isResolved: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    RoBeeAlert(
      id: 'alert-004',
      title: 'Inspection Complete — Canton',
      message: 'Daily inspection cycle completed. All frames scanned.',
      severity: 'info',
      trailerId: 'trailer-canton-001',
      isResolved: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      resolvedAt: DateTime.now().subtract(const Duration(hours: 22)),
    ),
    RoBeeAlert(
      id: 'alert-005',
      title: 'Low Trailer Battery',
      message:
          'Auburn Demo trailer battery at 64%. Consider charging within 48 hours.',
      severity: 'warning',
      trailerId: 'trailer-auburn-002',
      isResolved: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  // ── Frame Snapshots ────────────────────────────────────────────────────────
  static final List<FrameSnapshot> frameSnapshots = [
    FrameSnapshot(
      id: 'snap-001',
      hiveId: 'hive-c1',
      frameNumber: 1,
      boxType: 'brood',
      inspectionId: 'insp-canton-20240327',
      fullnessPercent: 82.0,
      hasQueen: false,
      sideAUrl: null,
      sideBUrl: null,
      notes: 'Good brood pattern. No issues detected.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    FrameSnapshot(
      id: 'snap-002',
      hiveId: 'hive-c1',
      frameNumber: 2,
      boxType: 'brood',
      inspectionId: 'insp-canton-20240327',
      fullnessPercent: 91.0,
      hasQueen: true,
      sideAUrl: null,
      sideBUrl: null,
      notes: 'Queen spotted. Healthy laying pattern.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 2)),
    ),
    FrameSnapshot(
      id: 'snap-003',
      hiveId: 'hive-c1',
      frameNumber: 1,
      boxType: 'honey',
      inspectionId: 'insp-canton-20240327',
      fullnessPercent: 67.0,
      hasQueen: false,
      sideAUrl: null,
      sideBUrl: null,
      notes: 'Capped honey cells 67% full.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
    ),
    FrameSnapshot(
      id: 'snap-004',
      hiveId: 'hive-c2',
      frameNumber: 3,
      boxType: 'brood',
      inspectionId: 'insp-canton-20240327',
      fullnessPercent: 75.0,
      hasQueen: false,
      sideAUrl: null,
      sideBUrl: null,
      notes: 'Normal pattern.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 40)),
    ),
    FrameSnapshot(
      id: 'snap-005',
      hiveId: 'hive-c5',
      frameNumber: 5,
      boxType: 'brood',
      inspectionId: 'insp-canton-20240327',
      fullnessPercent: 31.0,
      hasQueen: false,
      sideAUrl: null,
      sideBUrl: null,
      notes: 'Low brood coverage. Queen not seen. Emergency cells observed.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
    ),
  ];

  // ── Telemetry data (48h history for charts) ────────────────────────────────
  static List<Map<String, dynamic>> temperatureHistory(String hiveId) {
    final base = _hiveBaseTemp(hiveId);
    return List.generate(48, (i) {
      final hour = 47 - i;
      final noise = (hour % 7 - 3) * 0.4;
      return {
        'timestamp': DateTime.now().subtract(Duration(hours: hour)).toIso8601String(),
        'value': base + noise,
      };
    });
  }

  static List<Map<String, dynamic>> humidityHistory(String hiveId) {
    final base = _hiveBaseHumidity(hiveId);
    return List.generate(48, (i) {
      final hour = 47 - i;
      final noise = (hour % 5 - 2) * 0.8;
      return {
        'timestamp': DateTime.now().subtract(Duration(hours: hour)).toIso8601String(),
        'value': base + noise,
      };
    });
  }

  static List<Map<String, dynamic>> weightHistory(String hiveId) {
    final hive = hives.firstWhere(
      (h) => h.id == hiveId,
      orElse: () => Hive(
        id: hiveId,
        name: 'Unknown',
        trailerId: '',
        hiveNumber: 0,
        currentWeight: 75.0,
      ),
    );
    final base = hive.currentWeight ?? 75.0;
    return List.generate(14, (i) {
      final day = 13 - i;
      final drift = day * -0.15;
      return {
        'timestamp': DateTime.now().subtract(Duration(days: day)).toIso8601String(),
        'value': base + drift,
      };
    });
  }

  // Helper
  static double _hiveBaseTemp(String hiveId) {
    final hive = hives.firstWhere(
      (h) => h.id == hiveId,
      orElse: () => Hive(
        id: hiveId,
        name: 'Unknown',
        trailerId: '',
        hiveNumber: 0,
        currentTemp: 94.0,
      ),
    );
    return hive.currentTemp ?? 94.0;
  }

  static double _hiveBaseHumidity(String hiveId) {
    final hive = hives.firstWhere(
      (h) => h.id == hiveId,
      orElse: () => Hive(
        id: hiveId,
        name: 'Unknown',
        trailerId: '',
        hiveNumber: 0,
        currentHumidity: 62.0,
      ),
    );
    return hive.currentHumidity ?? 62.0;
  }

  // ── Convenience getters ────────────────────────────────────────────────────
  static List<Hive> hivesForTrailer(String trailerId) =>
      hives.where((h) => h.trailerId == trailerId).toList()
        ..sort((a, b) => a.hiveNumber.compareTo(b.hiveNumber));

  static List<RoBeeAlert> alertsForTrailer(String trailerId) =>
      alerts.where((a) => a.trailerId == trailerId).toList();

  static List<RoBeeAlert> get unresolvedAlerts =>
      alerts.where((a) => !a.isResolved).toList();

  static List<FrameSnapshot> snapshotsForHive(String hiveId) =>
      frameSnapshots.where((s) => s.hiveId == hiveId).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
}
