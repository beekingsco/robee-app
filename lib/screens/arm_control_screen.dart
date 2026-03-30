import 'package:flutter/material.dart';
import '../services/arm_driver_stub.dart';
import '../models/arm_telemetry.dart';
import '../theme/robee_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/slide_to_confirm.dart';

/// ArmControlScreen — Tesla instrument panel for the RoBee gantry arm.
class ArmControlScreen extends StatefulWidget {
  const ArmControlScreen({super.key});

  @override
  State<ArmControlScreen> createState() => _ArmControlScreenState();
}

class _ArmControlScreenState extends State<ArmControlScreen> {
  late final ArmDriverStub _arm;

  // Gantry frame selection (1-10, maps to 0-315mm)
  int _selectedFrame = 1;
  static const int _frameCount = 10;
  static const double _maxX = 315.0; // mm

  // Track last issued command label
  String _lastCmd = '--';
  bool _showEStop = false;

  @override
  void initState() {
    super.initState();
    _arm = ArmDriverStub();
    _arm.addListener(_onArmUpdate);
    _arm.connect();
  }

  void _onArmUpdate() => setState(() {});

  @override
  void dispose() {
    _arm.removeListener(_onArmUpdate);
    _arm.dispose();
    super.dispose();
  }

  double get _frameXMm => (_selectedFrame - 1) / (_frameCount - 1) * _maxX;

  Color _connectionColor(ArmConnectionState s) {
    switch (s) {
      case ArmConnectionState.connected:
        return RoBeeTheme.healthGreen;
      case ArmConnectionState.connecting:
        return RoBeeTheme.amber;
      case ArmConnectionState.error:
        return RoBeeTheme.healthRed;
      default:
        return RoBeeTheme.glassWhite60;
    }
  }

  String _connectionLabel(ArmConnectionState s) {
    switch (s) {
      case ArmConnectionState.connected:
        return 'ONLINE';
      case ArmConnectionState.connecting:
        return 'LINKING';
      case ArmConnectionState.error:
        return 'FAULT';
      default:
        return 'OFFLINE';
    }
  }

  Future<void> _cmdHome() async {
    setState(() => _lastCmd = 'HOME');
    await _arm.home();
  }

  Future<void> _cmdInspect() async {
    setState(() => _lastCmd = 'INSPECT FRAME $_selectedFrame');
    // Move arm to gantry X position for selected frame
    await _arm.sendCommand(
      ArmCommand.move(
        _arm.deviceId,
        pose: {'x': _frameXMm, 'z': 100.0},
      ),
    );
  }

  Future<void> _cmdEStop() async {
    setState(() {
      _lastCmd = 'E-STOP';
      _showEStop = false;
    });
    await _arm.stop();
  }

  @override
  Widget build(BuildContext context) {
    final t = _arm.latestTelemetry;

    return Scaffold(
      backgroundColor: RoBeeTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('ARM CONTROL', style: RoBeeTheme.displayMedium),
                  const Spacer(),
                  // Connection dot + label
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _connectionColor(_arm.state),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _connectionLabel(_arm.state),
                        style: RoBeeTheme.monoSmall.copyWith(
                          color: _connectionColor(_arm.state),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: t == null
                  ? _buildConnecting()
                  : _buildPanel(t),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnecting() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: RoBeeTheme.amber,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'LINKING ARM...',
            style: RoBeeTheme.labelLarge.copyWith(color: RoBeeTheme.amber),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(ArmTelemetry t) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // ── Status row ──────────────────────────────────────────────────────
        _StatusRow(arm: _arm, lastCmd: _lastCmd),
        const SizedBox(height: 10),

        // ── Telemetry grid ──────────────────────────────────────────────────
        _TelemetryGrid(telemetry: t),
        const SizedBox(height: 10),

        // ── X position / frame selector ─────────────────────────────────────
        _FrameSlider(
          selectedFrame: _selectedFrame,
          frameCount: _frameCount,
          currentXMm: t.posX ?? 0,
          maxXMm: _maxX,
          onFrameChanged: (f) => setState(() => _selectedFrame = f),
        ),
        const SizedBox(height: 10),

        // ── Z / lift height ──────────────────────────────────────────────────
        _LiftHeightBar(
          posZ: t.posZ,
          maxZ: 200.0,
        ),
        const SizedBox(height: 14),

        // ── Action buttons ───────────────────────────────────────────────────
        _ActionButtons(
          arm: _arm,
          selectedFrame: _selectedFrame,
          onHome: _cmdHome,
          onInspect: _cmdInspect,
          onEStopRequest: () => setState(() => _showEStop = !_showEStop),
        ),
        const SizedBox(height: 10),

        // ── Slide to E-Stop (shown on demand) ────────────────────────────────
        if (_showEStop) ...[
          SlideToConfirm(
            label: 'SLIDE TO CONFIRM EMERGENCY STOP',
            onConfirm: _cmdEStop,
            color: RoBeeTheme.healthRed,
          ),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Status Row ────────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final ArmDriverStub arm;
  final String lastCmd;

  const _StatusRow({required this.arm, required this.lastCmd});

  String _stateLabel(ArmConnectionState s) {
    switch (s) {
      case ArmConnectionState.connected:
        return 'READY';
      case ArmConnectionState.connecting:
        return 'LINKING';
      case ArmConnectionState.error:
        return 'FAULT';
      default:
        return 'IDLE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _StatusCell(
            label: 'CONNECTION',
            value: arm.isConnected ? 'ONLINE' : 'OFFLINE',
            valueColor: arm.isConnected
                ? RoBeeTheme.healthGreen
                : RoBeeTheme.healthRed,
          ),
          _VertDivider(),
          _StatusCell(
            label: 'STATE',
            value: _stateLabel(arm.state),
          ),
          _VertDivider(),
          _StatusCell(
            label: 'LAST CMD',
            value: lastCmd,
          ),
        ],
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: RoBeeTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: RoBeeTheme.monoSmall.copyWith(
              color: valueColor ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: RoBeeTheme.border,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

// ── Telemetry Grid ─────────────────────────────────────────────────────────────

class _TelemetryGrid extends StatelessWidget {
  final ArmTelemetry telemetry;

  const _TelemetryGrid({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIVE TELEMETRY',
            style: RoBeeTheme.labelLarge.copyWith(
              color: RoBeeTheme.amber,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TelCell(
                  label: 'POSITION X',
                  value:
                      '${telemetry.posX?.toStringAsFixed(1) ?? '--'} mm',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TelCell(
                  label: 'POSITION Z',
                  value:
                      '${telemetry.posZ?.toStringAsFixed(1) ?? '--'} mm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TelCell(
                  label: 'VELOCITY',
                  value: '0.0 mm/s',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TelCell(
                  label: 'TEMP',
                  value:
                      '${telemetry.tempC?.toStringAsFixed(1) ?? '--'} C',
                  valueColor: (telemetry.tempC != null &&
                          telemetry.tempC! > 50)
                      ? RoBeeTheme.healthRed
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TelCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TelCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A17),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RoBeeTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: RoBeeTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: RoBeeTheme.monoLarge.copyWith(
              fontSize: 16,
              color: valueColor ?? RoBeeTheme.amber,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Frame Slider ───────────────────────────────────────────────────────────────

class _FrameSlider extends StatelessWidget {
  final int selectedFrame;
  final int frameCount;
  final double currentXMm;
  final double maxXMm;
  final ValueChanged<int> onFrameChanged;

  const _FrameSlider({
    required this.selectedFrame,
    required this.frameCount,
    required this.currentXMm,
    required this.maxXMm,
    required this.onFrameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GANTRY POSITION',
                style: RoBeeTheme.labelLarge.copyWith(
                  color: RoBeeTheme.amber,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'FRAME $selectedFrame',
                style: RoBeeTheme.monoLarge.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: RoBeeTheme.amber,
              inactiveTrackColor: RoBeeTheme.glassWhite10,
              thumbColor: RoBeeTheme.amber,
              overlayColor: RoBeeTheme.amber.withOpacity(0.15),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 4,
            ),
            child: Slider(
              value: selectedFrame.toDouble(),
              min: 1,
              max: frameCount.toDouble(),
              divisions: frameCount - 1,
              onChanged: (v) => onFrameChanged(v.round()),
            ),
          ),
          // Frame labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(frameCount, (i) {
                final frame = i + 1;
                final isSelected = frame == selectedFrame;
                return Text(
                  '$frame',
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isSelected
                        ? RoBeeTheme.amber
                        : RoBeeTheme.glassWhite60,
                    letterSpacing: 0.5,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          // mm readout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TARGET',
                style: RoBeeTheme.labelSmall,
              ),
              Text(
                '${((selectedFrame - 1) / (frameCount - 1) * maxXMm).toStringAsFixed(0)} mm',
                style: RoBeeTheme.monoSmall.copyWith(
                  color: RoBeeTheme.amber,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Lift Height Bar ────────────────────────────────────────────────────────────

class _LiftHeightBar extends StatelessWidget {
  final double? posZ;
  final double maxZ;

  const _LiftHeightBar({this.posZ, required this.maxZ});

  @override
  Widget build(BuildContext context) {
    final pct = posZ != null ? (posZ! / maxZ).clamp(0.0, 1.0) : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIFT HEIGHT',
                  style: RoBeeTheme.labelLarge.copyWith(
                    color: RoBeeTheme.amber,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${posZ?.toStringAsFixed(0) ?? '--'} mm',
                  style: RoBeeTheme.monoLarge.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  'MAX ${maxZ.toStringAsFixed(0)} mm',
                  style: RoBeeTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Vertical progress bar
          SizedBox(
            width: 28,
            height: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${maxZ.toStringAsFixed(0)}',
                  style: RoBeeTheme.labelSmall.copyWith(fontSize: 8),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Container(
                    width: 12,
                    decoration: BoxDecoration(
                      color: RoBeeTheme.glassWhite10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: pct,
                        child: Container(
                          decoration: BoxDecoration(
                            color: RoBeeTheme.amber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '0',
                  style: RoBeeTheme.labelSmall.copyWith(fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons ─────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final ArmDriverStub arm;
  final int selectedFrame;
  final VoidCallback onHome;
  final VoidCallback onInspect;
  final VoidCallback onEStopRequest;

  const _ActionButtons({
    required this.arm,
    required this.selectedFrame,
    required this.onHome,
    required this.onInspect,
    required this.onEStopRequest,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = arm.isConnected;

    return Column(
      children: [
        // HOME + INSPECT row
        Row(
          children: [
            Expanded(
              child: _ArmButton(
                label: 'HOME',
                icon: Icons.home_outlined,
                enabled: enabled,
                onTap: onHome,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _ArmButton(
                label: 'INSPECT FRAME $selectedFrame',
                icon: Icons.center_focus_strong_outlined,
                enabled: enabled,
                onTap: onInspect,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // EMERGENCY STOP (red, full width)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: enabled
                    ? RoBeeTheme.healthRed
                    : RoBeeTheme.healthRed.withOpacity(0.3),
              ),
              backgroundColor: RoBeeTheme.healthRed.withOpacity(0.08),
              foregroundColor: RoBeeTheme.healthRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: enabled ? onEStopRequest : null,
            icon: const Icon(Icons.stop_circle_outlined, size: 20),
            label: const Text(
              'EMERGENCY STOP',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArmButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ArmButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? RoBeeTheme.amber : RoBeeTheme.amber.withOpacity(0.3),
          foregroundColor: RoBeeTheme.background,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
