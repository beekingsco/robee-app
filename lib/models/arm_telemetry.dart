/// Mirrors `public.device_telemetry` from Axon schema.
class ArmTelemetry {
  final String deviceId;
  final String? sessionId;

  // Joint positions (degrees)
  final double? joint1;
  final double? joint2;
  final double? joint3;
  final double? joint4;
  final double? joint5;
  final double? joint6;

  // End-effector pose
  final double? posX;
  final double? posY;
  final double? posZ;
  final double? rotRoll;
  final double? rotPitch;
  final double? rotYaw;

  // Gripper (0.0 = closed, 100.0 = fully open)
  final double? gripperOpen;
  final String? toolState;

  // System health
  final double? voltage;
  final double? currentMa;
  final double? tempC;
  final int errorFlags;

  final Map<String, dynamic> raw;
  final DateTime deviceTs;
  final DateTime? serverTs;

  const ArmTelemetry({
    required this.deviceId,
    this.sessionId,
    this.joint1,
    this.joint2,
    this.joint3,
    this.joint4,
    this.joint5,
    this.joint6,
    this.posX,
    this.posY,
    this.posZ,
    this.rotRoll,
    this.rotPitch,
    this.rotYaw,
    this.gripperOpen,
    this.toolState,
    this.voltage,
    this.currentMa,
    this.tempC,
    this.errorFlags = 0,
    this.raw = const {},
    required this.deviceTs,
    this.serverTs,
  });

  List<double?> get joints => [joint1, joint2, joint3, joint4, joint5, joint6];

  factory ArmTelemetry.fromJson(Map<String, dynamic> json) => ArmTelemetry(
        deviceId: json['device_id'] as String,
        sessionId: json['session_id'] as String?,
        joint1: (json['joint_1'] as num?)?.toDouble(),
        joint2: (json['joint_2'] as num?)?.toDouble(),
        joint3: (json['joint_3'] as num?)?.toDouble(),
        joint4: (json['joint_4'] as num?)?.toDouble(),
        joint5: (json['joint_5'] as num?)?.toDouble(),
        joint6: (json['joint_6'] as num?)?.toDouble(),
        posX: (json['pos_x'] as num?)?.toDouble(),
        posY: (json['pos_y'] as num?)?.toDouble(),
        posZ: (json['pos_z'] as num?)?.toDouble(),
        rotRoll: (json['rot_roll'] as num?)?.toDouble(),
        rotPitch: (json['rot_pitch'] as num?)?.toDouble(),
        rotYaw: (json['rot_yaw'] as num?)?.toDouble(),
        gripperOpen: (json['gripper_open'] as num?)?.toDouble(),
        toolState: json['tool_state'] as String?,
        voltage: (json['voltage'] as num?)?.toDouble(),
        currentMa: (json['current_ma'] as num?)?.toDouble(),
        tempC: (json['temp_c'] as num?)?.toDouble(),
        errorFlags: (json['error_flags'] as int?) ?? 0,
        raw: (json['raw'] as Map<String, dynamic>?) ?? {},
        deviceTs: DateTime.parse(json['device_ts'] as String),
        serverTs: json['server_ts'] != null
            ? DateTime.parse(json['server_ts'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'session_id': sessionId,
        'joint_1': joint1,
        'joint_2': joint2,
        'joint_3': joint3,
        'joint_4': joint4,
        'joint_5': joint5,
        'joint_6': joint6,
        'pos_x': posX,
        'pos_y': posY,
        'pos_z': posZ,
        'rot_roll': rotRoll,
        'rot_pitch': rotPitch,
        'rot_yaw': rotYaw,
        'gripper_open': gripperOpen,
        'tool_state': toolState,
        'voltage': voltage,
        'current_ma': currentMa,
        'temp_c': tempC,
        'error_flags': errorFlags,
        'raw': raw,
        'device_ts': deviceTs.toIso8601String(),
      };

  /// Generate plausible mock telemetry for testing
  static ArmTelemetry mock({String deviceId = 'robee-mock-001'}) => ArmTelemetry(
        deviceId: deviceId,
        sessionId: 'mock-session',
        joint1: 0.0,
        joint2: -45.0,
        joint3: 90.0,
        joint4: 0.0,
        joint5: 45.0,
        joint6: 0.0,
        posX: 150.0,
        posY: 0.0,
        posZ: 200.0,
        rotRoll: 0.0,
        rotPitch: 0.0,
        rotYaw: 0.0,
        gripperOpen: 50.0,
        toolState: 'idle',
        voltage: 24.1,
        currentMa: 850.0,
        tempC: 32.5,
        errorFlags: 0,
        deviceTs: DateTime.now(),
      );
}

/// A command sent to the arm (mirrors `public.arm_commands`)
class ArmCommand {
  final String deviceId;
  final String? sessionId;
  final ArmCommandType commandType;
  final Map<String, dynamic> payload;
  final int priority;

  const ArmCommand({
    required this.deviceId,
    this.sessionId,
    required this.commandType,
    this.payload = const {},
    this.priority = 5,
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'session_id': sessionId,
        'command_type': commandType.value,
        'payload': payload,
        'priority': priority,
      };

  /// Pre-built convenience constructors
  static ArmCommand home(String deviceId) => ArmCommand(
        deviceId: deviceId,
        commandType: ArmCommandType.home,
        priority: 8,
      );

  static ArmCommand stop(String deviceId) => ArmCommand(
        deviceId: deviceId,
        commandType: ArmCommandType.stop,
        priority: 10,
      );

  static ArmCommand gripper(String deviceId, double openPercent) => ArmCommand(
        deviceId: deviceId,
        commandType: ArmCommandType.gripper,
        payload: {'open_percent': openPercent},
      );

  static ArmCommand move(
    String deviceId, {
    List<double>? joints,
    Map<String, double>? pose,
  }) =>
      ArmCommand(
        deviceId: deviceId,
        commandType: ArmCommandType.move,
        payload: {
          if (joints != null) 'joints': joints,
          if (pose != null) 'pose': pose,
        },
      );
}

enum ArmCommandType {
  move('move'),
  home('home'),
  stop('stop'),
  gripper('gripper'),
  tool('tool'),
  raw('raw');

  const ArmCommandType(this.value);
  final String value;
}
