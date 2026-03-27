import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';

/// Full-screen camera preview with capture / record / flip controls.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  late final CameraService _camera;
  FlashMode _flash = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _camera = CameraService();
    _camera.addListener(_onCameraUpdate);
    _camera.init();
  }

  void _onCameraUpdate() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_camera.isInitialised) return;
    if (state == AppLifecycleState.inactive) {
      _camera.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _camera.init();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera.removeListener(_onCameraUpdate);
    _camera.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final file = await _camera.takePicture();
    if (file != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: ${file.path.split('/').last}')),
      );
    }
  }

  Future<void> _toggleRecord() async {
    if (_camera.isRecording) {
      final file = await _camera.stopRecording();
      if (file != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video: ${file.path.split('/').last}')),
        );
      }
    } else {
      await _camera.startRecording();
    }
  }

  void _cycleFlash() {
    final modes = [FlashMode.auto, FlashMode.always, FlashMode.off, FlashMode.torch];
    final next = modes[(modes.indexOf(_flash) + 1) % modes.length];
    setState(() => _flash = next);
    _camera.setFlash(next);
  }

  IconData get _flashIcon {
    switch (_flash) {
      case FlashMode.always: return Icons.flash_on;
      case FlashMode.off: return Icons.flash_off;
      case FlashMode.torch: return Icons.highlight;
      default: return Icons.flash_auto;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_camera.isInitialised && _camera.controller != null)
            _CameraPreviewWidget(controller: _camera.controller!)
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Initialising camera…', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

          // Top controls
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _ControlButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    _ControlButton(icon: _flashIcon, onTap: _cycleFlash),
                    const SizedBox(width: 8),
                    if (_camera.hasMultipleCameras)
                      _ControlButton(
                        icon: Icons.flip_camera_ios,
                        onTap: _camera.toggleCamera,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Thumbnail of last capture (placeholder)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.photo_library_outlined,
                          color: Colors.white),
                    ),

                    // Shutter
                    GestureDetector(
                      onTap: _capture,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(Icons.camera, color: Colors.white, size: 36),
                      ),
                    ),

                    // Record toggle
                    GestureDetector(
                      onTap: _toggleRecord,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _camera.isRecording
                              ? Colors.red
                              : Colors.white24,
                        ),
                        child: Icon(
                          _camera.isRecording
                              ? Icons.stop_rounded
                              : Icons.fiber_manual_record,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recording indicator
          if (_camera.isRecording)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                        SizedBox(width: 6),
                        Text('REC', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  const _CameraPreviewWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return OverflowBox(
      maxWidth: size.width,
      maxHeight: size.height,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.width * controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
