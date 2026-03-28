class FrameSnapshot {
  final String id;
  final String hiveId;
  final int frameNumber;
  final String boxType; // 'brood' | 'honey'
  final String? inspectionId;
  final double? fullnessPercent;
  final bool? hasQueen;
  final String? sideAUrl;
  final String? sideBUrl;
  final String? notes;
  final DateTime timestamp;

  const FrameSnapshot({
    required this.id,
    required this.hiveId,
    required this.frameNumber,
    required this.boxType,
    this.inspectionId,
    this.fullnessPercent,
    this.hasQueen,
    this.sideAUrl,
    this.sideBUrl,
    this.notes,
    required this.timestamp,
  });

  factory FrameSnapshot.fromJson(Map<String, dynamic> json) {
    return FrameSnapshot(
      id: json['id'] as String,
      hiveId: json['hive_id'] as String,
      frameNumber: json['frame_number'] as int,
      boxType: json['box_type'] as String,
      inspectionId: json['inspection_id'] as String?,
      fullnessPercent: (json['fullness_percent'] as num?)?.toDouble(),
      hasQueen: json['has_queen'] as bool?,
      sideAUrl: json['side_a_url'] as String?,
      sideBUrl: json['side_b_url'] as String?,
      notes: json['notes'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hive_id': hiveId,
        'frame_number': frameNumber,
        'box_type': boxType,
        'inspection_id': inspectionId,
        'fullness_percent': fullnessPercent,
        'has_queen': hasQueen,
        'side_a_url': sideAUrl,
        'side_b_url': sideBUrl,
        'notes': notes,
        'timestamp': timestamp.toIso8601String(),
      };

  FrameSnapshot copyWith({
    String? id,
    String? hiveId,
    int? frameNumber,
    String? boxType,
    String? inspectionId,
    double? fullnessPercent,
    bool? hasQueen,
    String? sideAUrl,
    String? sideBUrl,
    String? notes,
    DateTime? timestamp,
  }) {
    return FrameSnapshot(
      id: id ?? this.id,
      hiveId: hiveId ?? this.hiveId,
      frameNumber: frameNumber ?? this.frameNumber,
      boxType: boxType ?? this.boxType,
      inspectionId: inspectionId ?? this.inspectionId,
      fullnessPercent: fullnessPercent ?? this.fullnessPercent,
      hasQueen: hasQueen ?? this.hasQueen,
      sideAUrl: sideAUrl ?? this.sideAUrl,
      sideBUrl: sideBUrl ?? this.sideBUrl,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
