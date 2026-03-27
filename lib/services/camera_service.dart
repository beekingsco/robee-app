import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// CameraService — wraps the `camera` package with lifecycle management.
/// Handles preview, photo capture, and video recording.
class CameraService extends ChangeNotifier {
  static final _log = Logger(printer: SimplePrinter());

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedIndex = 0;
  bool _isRecording = false;
  bool _isInitialised = false;
  String? _lastCapturePath;
  String? _lastVideoPath;
  CameraException? _lastError;

  // ── Public getters ──────────────────────────────────────────────────────────
  CameraController? get controller => _controller;
  bool get isInitialised => _isInitialised;
  bool get isRecording => _isRecording;
  String? get lastCapturePath => _lastCapturePath;
  String? get lastVideoPath => _lastVideoPath;
  CameraException? get lastError => _lastError;
  int get cameraCount => _cameras.length;
  bool get hasMultipleCameras => _cameras.length > 1;

  CameraLensDirection get currentLensDirection =>
      _cameras.isNotEmpty ? _cameras[_selectedIndex].lensDirection : CameraLensDirection.back;

  // ── Initialise ──────────────────────────────────────────────────────────────
  Future<void> init({ResolutionPreset resolution = ResolutionPreset.high}) async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _log.w('No cameras found on this device');
        return;
      }
      await _mountCamera(resolution);
    } on CameraException catch (e) {
      _lastError = e;
      _log.e('Camera init failed: $e');
      notifyListeners();
    }
  }

  Future<void> _mountCamera(ResolutionPreset resolution) async {
    await _controller?.dispose();
    _isInitialised = false;

    final desc = _cameras[_selectedIndex];
    _controller = CameraController(
      desc,
      resolution,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      _isInitialised = true;
      _lastError = null;
      _log.i('Camera mounted: ${desc.name} (${desc.lensDirection.name})');
    } on CameraException catch (e) {
      _lastError = e;
      _log.e('Camera mount failed: $e');
    }
    notifyListeners();
  }

  // ── Switch camera (front ↔ back) ────────────────────────────────────────────
  Future<void> toggleCamera() async {
    if (_cameras.length < 2) return;
    _selectedIndex = (_selectedIndex + 1) % _cameras.length;
    final res = _controller?.value.previewSize != null
        ? ResolutionPreset.high
        : ResolutionPreset.medium;
    await _mountCamera(res);
  }

  // ── Flash ───────────────────────────────────────────────────────────────────
  Future<void> setFlash(FlashMode mode) async {
    if (!_isInitialised) return;
    try {
      await _controller!.setFlashMode(mode);
      notifyListeners();
    } on CameraException catch (e) {
      _log.w('Flash mode error: $e');
    }
  }

  // ── Still capture ───────────────────────────────────────────────────────────
  Future<File?> takePicture() async {
    if (!_isInitialised || _isRecording) return null;
    try {
      final xFile = await _controller!.takePicture();
      _lastCapturePath = xFile.path;
      _log.i('Picture saved: ${xFile.path}');
      notifyListeners();
      return File(xFile.path);
    } on CameraException catch (e) {
      _lastError = e;
      _log.e('takePicture failed: $e');
      notifyListeners();
      return null;
    }
  }

  // ── Video recording ─────────────────────────────────────────────────────────
  Future<void> startRecording() async {
    if (!_isInitialised || _isRecording) return;
    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      _log.i('Recording started');
      notifyListeners();
    } on CameraException catch (e) {
      _lastError = e;
      _log.e('startRecording failed: $e');
      notifyListeners();
    }
  }

  Future<File?> stopRecording() async {
    if (!_isRecording) return null;
    try {
      final xFile = await _controller!.stopVideoRecording();
      _isRecording = false;
      _lastVideoPath = xFile.path;
      _log.i('Recording saved: ${xFile.path}');
      notifyListeners();
      return File(xFile.path);
    } on CameraException catch (e) {
      _lastError = e;
      _isRecording = false;
      _log.e('stopRecording failed: $e');
      notifyListeners();
      return null;
    }
  }

  // ── Zoom ────────────────────────────────────────────────────────────────────
  Future<void> setZoom(double zoom) async {
    if (!_isInitialised) return;
    final min = await _controller!.getMinZoomLevel();
    final max = await _controller!.getMaxZoomLevel();
    await _controller!.setZoomLevel(zoom.clamp(min, max));
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
