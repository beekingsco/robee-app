import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/arm_telemetry.dart';
import '../config/app_config.dart';

/// Connection state for the arm driver.
enum ArmConnectionState { disconnected, connecting, connected, error }

/// ArmDriverStub — communication layer between the app and the physical robot arm.
///
/// In mock mode (AppConfig.enableMockArm == true), it generates synthetic
/// telemetry locally at ~10 Hz so the UI can be developed without hardware.
///
/// In live mode it opens a WebSocket to the arm controller and exchanges
/// JSON-framed messages (same schema as arm_commands / device_telemetry).
class ArmDriverStub extends ChangeNotifier {
  static final _log = Logger(printer: SimplePrinter());
  static final _rng = math.Random();

  // ── State ────────────────────────────────────────────────────────────────────
  ArmConnectionState _state = ArmConnectionState.disconnected;
  ArmTelemetry? _latestTelemetry;
  String? _errorMessage;
  String _deviceId = 'robee-001';
  String? _sessionId;
  int _reconnectAttempts = 0;

  // ── Streams ──────────────────────────────────────────────────────────────────
  final _telemetryController = StreamController<ArmTelemetry>.broadcast();
  Stream<ArmTelemetry> get telemetryStream => _telemetryController.stream;

  // ── WebSocket (live mode) ────────────────────────────────────────────────────
  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;

  // ── Mock ticker (mock mode) ──────────────────────────────────────────────────
  Timer? _mockTimer;
  // Simulated joint angles drift slowly
  final _mockJoints = [0.0, -45.0, 90.0, 0.0, 45.0, 0.0];

  // ── Public getters ────────────────────────────────────────────────────────────
  ArmConnectionState get state => _state;
  ArmTelemetry? get latestTelemetry => _latestTelemetry;
  String? get errorMessage => _errorMessage;
  String get deviceId => _deviceId;
  bool get isConnected => _state == ArmConnectionState.connected;

  // ── Connect ──────────────────────────────────────────────────────────────────
  Future<void> connect({
    String? deviceId,
    String? wsUrl,
  }) async {
    _deviceId = deviceId ?? _deviceId;
    _sessionId = 'sess-${DateTime.now().millisecondsSinceEpoch}';
    _setState(ArmConnectionState.connecting);

    if (AppConfig.enableMockArm) {
      await _connectMock();
    } else {
      await _connectLive(wsUrl ?? AppConfig.defaultArmWsUrl);
    }
  }

  Future<void> _connectMock() async {
    _log.i('[ArmDriver] Starting mock mode for device $_deviceId');
    // Simulate handshake delay
    await Future.delayed(const Duration(milliseconds: 400));
    _setState(ArmConnectionState.connected);
    _reconnectAttempts = 0;

    _mockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _tickMock();
    });
  }

  void _tickMock() {
    // Gently drift each joint ±0.5°
    for (var i = 0; i < _mockJoints.length; i++) {
      _mockJoints[i] += (_rng.nextDouble() - 0.5) * 1.0;
      _mockJoints[i] = _mockJoints[i].clamp(-180.0, 180.0);
    }

    final t = ArmTelemetry(
      deviceId: _deviceId,
      sessionId: _sessionId,
      joint1: _mockJoints[0],
      joint2: _mockJoints[1],
      joint3: _mockJoints[2],
      joint4: _mockJoints[3],
      joint5: _mockJoints[4],
      joint6: _mockJoints[5],
      posX: 150.0 + _rng.nextDouble() * 2,
      posY: _rng.nextDouble() * 2,
      posZ: 200.0 + _rng.nextDouble() * 2,
      rotRoll: 0.0,
      rotPitch: 0.0,
      rotYaw: 0.0,
      gripperOpen: 50.0,
      toolState: 'idle',
      voltage: 24.0 + _rng.nextDouble() * 0.4,
      currentMa: 820.0 + _rng.nextDouble() * 60,
      tempC: 32.0 + _rng.nextDouble() * 1.0,
      errorFlags: 0,
      deviceTs: DateTime.now(),
    );

    _latestTelemetry = t;
    _telemetryController.add(t);
    notifyListeners();
  }

  Future<void> _connectLive(String url) async {
    try {
      _log.i('[ArmDriver] Connecting to $url');
      _ws = WebSocketChannel.connect(Uri.parse(url));
      await _ws!.ready;
      _setState(ArmConnectionState.connected);
      _reconnectAttempts = 0;

      _wsSub = _ws!.stream.listen(
        _onWsMessage,
        onError: _onWsError,
        onDone: _onWsDone,
        cancelOnError: false,
      );
    } catch (e) {
      _log.e('[ArmDriver] Connection failed: $e');
      _errorMessage = e.toString();
      _setState(ArmConnectionState.error);
      _scheduleReconnect(url);
    }
  }

  void _onWsMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final t = ArmTelemetry.fromJson(json);
      _latestTelemetry = t;
      _telemetryController.add(t);
      notifyListeners();
    } catch (e) {
      _log.w('[ArmDriver] Bad message: $e  raw=$data');
    }
  }

  void _onWsError(Object error) {
    _log.e('[ArmDriver] WebSocket error: $error');
    _errorMessage = error.toString();
    _setState(ArmConnectionState.error);
  }

  void _onWsDone() {
    _log.w('[ArmDriver] WebSocket closed');
    if (_state == ArmConnectionState.connected) {
      _setState(ArmConnectionState.disconnected);
      _scheduleReconnect(AppConfig.defaultArmWsUrl);
    }
  }

  void _scheduleReconnect(String url) {
    if (_reconnectAttempts >= AppConfig.wsMaxReconnectAttempts) {
      _log.e('[ArmDriver] Max reconnect attempts reached');
      return;
    }
    _reconnectAttempts++;
    _log.i('[ArmDriver] Reconnecting in ${AppConfig.wsReconnectDelayMs}ms (attempt $_reconnectAttempts)');
    Future.delayed(Duration(milliseconds: AppConfig.wsReconnectDelayMs), () {
      _connectLive(url);
    });
  }

  // ── Send command ─────────────────────────────────────────────────────────────
  Future<bool> sendCommand(ArmCommand cmd) async {
    if (!isConnected) {
      _log.w('[ArmDriver] Cannot send — not connected');
      return false;
    }

    final payload = jsonEncode(cmd.toJson());
    _log.i('[ArmDriver] CMD → ${cmd.commandType.value}  payload=$payload');

    if (AppConfig.enableMockArm) {
      _handleMockCommand(cmd);
      return true;
    }

    try {
      _ws!.sink.add(payload);
      return true;
    } catch (e) {
      _log.e('[ArmDriver] Send failed: $e');
      return false;
    }
  }

  void _handleMockCommand(ArmCommand cmd) {
    switch (cmd.commandType) {
      case ArmCommandType.home:
        for (var i = 0; i < _mockJoints.length; i++) {
          _mockJoints[i] = [0.0, -45.0, 90.0, 0.0, 45.0, 0.0][i];
        }
        break;
      case ArmCommandType.stop:
        _log.i('[ArmDriver MOCK] E-STOP');
        break;
      case ArmCommandType.move:
        if (cmd.payload['joints'] is List) {
          final j = (cmd.payload['joints'] as List).cast<double>();
          for (var i = 0; i < math.min(j.length, _mockJoints.length); i++) {
            _mockJoints[i] = j[i];
          }
        }
        break;
      default:
        break;
    }
  }

  // ── Convenience shortcuts ────────────────────────────────────────────────────
  Future<bool> home() => sendCommand(ArmCommand.home(_deviceId));
  Future<bool> stop() => sendCommand(ArmCommand.stop(_deviceId));
  Future<bool> setGripper(double pct) => sendCommand(ArmCommand.gripper(_deviceId, pct));

  // ── Disconnect ───────────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    _mockTimer?.cancel();
    _mockTimer = null;
    await _wsSub?.cancel();
    await _ws?.sink.close();
    _ws = null;
    _setState(ArmConnectionState.disconnected);
    _log.i('[ArmDriver] Disconnected');
  }

  void _setState(ArmConnectionState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _telemetryController.close();
    super.dispose();
  }
}
