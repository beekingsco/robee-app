import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/trailer.dart';
import '../models/hive.dart';
import '../services/mock_data.dart';
import '../services/supabase_service.dart';
import '../theme/robee_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/amber_button.dart';

class RegisterTrailerScreen extends StatefulWidget {
  const RegisterTrailerScreen({super.key});

  @override
  State<RegisterTrailerScreen> createState() => _RegisterTrailerScreenState();
}

class _RegisterTrailerScreenState extends State<RegisterTrailerScreen> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _idValid = false;
  bool _idInvalid = false;

  static final _idPattern = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');

  @override
  void initState() {
    super.initState();
    _idController.addListener(_validateId);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _validateId() {
    final raw = _idController.text.toUpperCase();
    setState(() {
      _idValid = _idPattern.hasMatch(raw);
      _idInvalid = raw.isNotEmpty &&
          raw.replaceAll('-', '').length >= 12 &&
          !_idValid;
    });
  }

  void _formatId(String value) {
    final clean = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    String formatted = '';
    for (int i = 0; i < clean.length && i < 12; i++) {
      if (i == 4 || i == 8) formatted += '-';
      formatted += clean[i];
    }
    if (formatted != _idController.text) {
      _idController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _openQRScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => const _QRScanFullScreen(),
      ),
    );
    if (result != null) {
      _idController.text = result;
      _validateId();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final id = _idController.text.trim();
      final name = _nameController.text.trim();

      // Create trailer
      Trailer? trailer;
      try {
        final svc = SupabaseService();
        if (svc.isSignedIn) {
          trailer = await svc.createTrailer(
            trailerId: id,
            name: name,
          );
        }
      } catch (_) {}

      // Fall back to mock
      trailer ??= Trailer(
        id: id.toLowerCase().replaceAll('-', '-'),
        name: name,
        trailerNumber: id,
        status: 'online',
        batteryLevel: 100,
        storageUsage: 0,
        tempUnit: 'F',
        weightUnit: 'lbs',
        inspectionFrequency: 'daily',
      );

      // Create 6 hives
      for (int i = 1; i <= 6; i++) {
        try {
          final svc = SupabaseService();
          if (svc.isSignedIn) {
            await svc.createHive(
              trailerId: trailer.id,
              hiveNumber: i,
              name: 'Hive $i',
            );
          }
        } catch (_) {}
      }

      if (mounted) {
        context.go('/trailers/${trailer.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoBeeTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text('Back', style: RoBeeTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Register Trailer', style: RoBeeTheme.displayMedium),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your 12-digit trailer ID or scan the QR code.',
                    style: RoBeeTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),

                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Trailer ID field
                          const Text('TRAILER ID',
                              style: RoBeeTheme.labelLarge),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _idController,
                                  style: RoBeeTheme.monoLarge.copyWith(
                                    color: _idValid
                                        ? RoBeeTheme.healthGreen
                                        : _idInvalid
                                            ? RoBeeTheme.healthRed
                                            : Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'XXXX-XXXX-XXXX',
                                    hintStyle: RoBeeTheme.monoSmall,
                                    suffixIcon: _idValid
                                        ? const Icon(Icons.check_circle_rounded,
                                            color: RoBeeTheme.healthGreen,
                                            size: 18)
                                        : _idInvalid
                                            ? const Icon(Icons.cancel_rounded,
                                                color: RoBeeTheme.healthRed,
                                                size: 18)
                                            : null,
                                  ),
                                  inputFormatters: [
                                    TextInputFormatter.withFunction(
                                        (old, newVal) {
                                      final clean = newVal.text
                                          .toUpperCase()
                                          .replaceAll(
                                              RegExp(r'[^A-Z0-9-]'), '');
                                      return newVal.copyWith(text: clean);
                                    }),
                                    LengthLimitingTextInputFormatter(14),
                                  ],
                                  onChanged: _formatId,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Trailer ID is required';
                                    }
                                    if (!_idPattern.hasMatch(v)) {
                                      return 'Format: XXXX-XXXX-XXXX';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _openQRScanner,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: RoBeeTheme.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: RoBeeTheme.amber.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Icon(Icons.qr_code_scanner_rounded,
                                      color: RoBeeTheme.amber, size: 22),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Trailer name
                          const Text('TRAILER NAME',
                              style: RoBeeTheme.labelLarge),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'e.g. Home Apiary, North Field',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Trailer name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          AmberButton(
                            label: 'Register Trailer',
                            loading: _loading,
                            icon: Icons.add_rounded,
                            onPressed: _idValid ? _submit : null,
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen QR scanner overlay
class _QRScanFullScreen extends StatefulWidget {
  const _QRScanFullScreen();

  @override
  State<_QRScanFullScreen> createState() => _QRScanFullScreenState();
}

class _QRScanFullScreenState extends State<_QRScanFullScreen>
    with SingleTickerProviderStateMixin {
  final _controller = MobileScannerController();
  late AnimationController _scanLineController;
  late Animation<double> _scanLine;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scanLine = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null) {
      setState(() => _scanned = true);
      Navigator.of(context).pop(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full camera view
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
          ),

          // Dark overlay with center cutout
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanOverlayPainter(),
            ),
          ),

          // Corner bracket overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _CornerBracketPainter(),
            ),
          ),

          // Animated scan line (amber, moves top to bottom)
          AnimatedBuilder(
            animation: _scanLine,
            builder: (ctx, child) {
              final topPad = size.height * 0.25;
              final scanAreaHeight = size.height * 0.5;
              final lineY = topPad + (_scanLine.value * scanAreaHeight);
              return Positioned(
                top: lineY,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        RoBeeTheme.amber.withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),

                  ),
                ),
              );
            },
          ),

          // Status text
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _scanned
                      ? 'QR Code Detected! ✓'
                      : 'Scanning for RoBee QR code...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _scanned ? RoBeeTheme.healthGreen : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_scanned) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Point camera at the QR code on your trailer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Close button top right
          Positioned(
            top: 52,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),

          // Title
          Positioned(
            top: 56,
            left: 20,
            child: Text(
              'SCAN QR CODE',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark overlay with transparent center cutout for scanner
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.65);
    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12)));
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter _) => false;
}

class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    // Center box coordinates (matches _ScanOverlayPainter)
    final boxSize = size.width * 0.7;
    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2;
    final right = left + boxSize;
    final bottom = top + boxSize;
    const padding = 2.0;

    final l = left + padding;
    final t = top + padding;
    final r = right - padding;
    final b = bottom - padding;

    // Top-left
    canvas.drawLine(Offset(l, t + len), Offset(l, t), paint);
    canvas.drawLine(Offset(l, t), Offset(l + len, t), paint);

    // Top-right
    canvas.drawLine(Offset(r, t + len), Offset(r, t), paint);
    canvas.drawLine(Offset(r, t), Offset(r - len, t), paint);

    // Bottom-left
    canvas.drawLine(Offset(l, b - len), Offset(l, b), paint);
    canvas.drawLine(Offset(l, b), Offset(l + len, b), paint);

    // Bottom-right
    canvas.drawLine(Offset(r, b - len), Offset(r, b), paint);
    canvas.drawLine(Offset(r, b), Offset(r - len, b), paint);

    // Amber inner glow
    final amberPaint = Paint()
      ..color = RoBeeTheme.amber.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTRB(l + 4, t + 4, r - 4, b - 4),
      amberPaint,
    );
  }

  @override
  bool shouldRepaint(_CornerBracketPainter _) => false;
}
