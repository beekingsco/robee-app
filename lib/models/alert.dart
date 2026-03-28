class RoBeeAlert {
  final String id;
  final String title;
  final String message;
  final String severity;
  final bool isResolved;
  final String trailerId;
  final String? hiveId;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const RoBeeAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.trailerId,
    this.hiveId,
    this.isResolved = false,
    required this.createdAt,
    this.resolvedAt,
  });

  factory RoBeeAlert.fromJson(Map<String, dynamic> json) {
    return RoBeeAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      trailerId: json['trailer_id'] as String,
      hiveId: json['hive_id'] as String?,
      isResolved: json['is_resolved'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'severity': severity,
        'trailer_id': trailerId,
        'hive_id': hiveId,
        'is_resolved': isResolved,
        'created_at': createdAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
      };

  RoBeeAlert copyWith({
    String? id,
    String? title,
    String? message,
    String? severity,
    bool? isResolved,
    String? trailerId,
    String? hiveId,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return RoBeeAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      trailerId: trailerId ?? this.trailerId,
      hiveId: hiveId ?? this.hiveId,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
