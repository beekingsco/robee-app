import 'package:flutter/material.dart';
import '../services/arm_driver_stub.dart';
import '../models/arm_telemetry.dart';

/// ArmControlScreen — live telemetry display + basic command controls.
class ArmControlScreen extends StatefulWidget {
  const ArmControlScreen({super.key});

  @override
  State<ArmControlScreen> createState() => _ArmControlScreenState();
}

class _ArmControlScreenState extends State<ArmControlScreen> {
  late final ArmDriverStub _arm;

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

  Color _stateColor(ArmConnectionState s) {
    switch (s) {
      case ArmConnectionState.connected: return Colors.green;
      case ArmConnectionState.connecting: return Colors.orange;
      case ArmConnectionState.error: return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = _arm.latestTelemetry;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arm Control'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _stateColor(_arm.state),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(_arm.state.name,
                    style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Telemetry panel
              Expanded(
                child: t == null
                    ? const Center(child: CircularProgressIndicator())
                    : _TelemetryPanel(telemetry: t),
              ),
              const SizedBox(height: 16),

              // Command buttons
              _CommandBar(arm: _arm),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryPanel extends StatelessWidget {
  final ArmTelemetry telemetry;
  const _TelemetryPanel({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Joint positions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Joint Positions (°)',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                ...List.generate(6, (i) {
                  final v = telemetry.joints[i];
                  return _JointRow(
                    label: 'J${i + 1}',
                    value: v,
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // End-effector pose
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('End-Effector Pose',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                _DataRow('X', '${telemetry.posX?.toStringAsFixed(1) ?? '--'} mm'),
                _DataRow('Y', '${telemetry.posY?.toStringAsFixed(1) ?? '--'} mm'),
                _DataRow('Z', '${telemetry.posZ?.toStringAsFixed(1) ?? '--'} mm'),
                _DataRow('Roll', '${telemetry.rotRoll?.toStringAsFixed(1) ?? '--'}°'),
                _DataRow('Pitch', '${telemetry.rotPitch?.toStringAsFixed(1) ?? '--'}°'),
                _DataRow('Yaw', '${telemetry.rotYaw?.toStringAsFixed(1) ?? '--'}°'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Health
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Health',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                _DataRow('Voltage', '${telemetry.voltage?.toStringAsFixed(2) ?? '--'} V'),
                _DataRow('Current', '${telemetry.currentMa?.toStringAsFixed(0) ?? '--'} mA'),
                _DataRow('Temp', '${telemetry.tempC?.toStringAsFixed(1) ?? '--'} °C'),
                _DataRow('Gripper', '${telemetry.gripperOpen?.toStringAsFixed(0) ?? '--'}%'),
                _DataRow('Tool', telemetry.toolState ?? '--'),
                _DataRow('Errors', telemetry.errorFlags.toString()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _JointRow extends StatelessWidget {
  final String label;
  final double? value;
  const _JointRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final pct = value != null ? ((value! + 180) / 360).clamp(0.0, 1.0) : 0.5;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(label,
                style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: Text(
              '${value?.toStringAsFixed(1) ?? '--'}°',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CommandBar extends StatelessWidget {
  final ArmDriverStub arm;
  const _CommandBar({required this.arm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: arm.isConnected ? () => arm.home() : null,
            icon: const Icon(Icons.home_outlined),
            label: const Text('Home'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: arm.isConnected ? () => arm.stop() : null,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('E-Stop'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: arm.isConnected ? () => arm.setGripper(arm.latestTelemetry?.gripperOpen == 100 ? 0 : 100) : null,
            icon: const Icon(Icons.open_in_full),
            label: const Text('Gripper'),
          ),
        ),
      ],
    );
  }
}
