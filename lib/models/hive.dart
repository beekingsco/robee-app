class Hive {
  final String id;
  final String name;
  final String trailerId;
  final int hiveNumber;
  final double? currentTemp;
  final double? currentHumidity;
  final double? currentWeight;
  final String queenStatus;
  final String entranceState;
  final String boxOrientation;
  final String healthStatus;

  const Hive({
    required this.id,
    required this.name,
    required this.trailerId,
    required this.hiveNumber,
    this.currentTemp,
    this.currentHumidity,
    this.currentWeight,
    this.queenStatus = 'unknown',
    this.entranceState = 'open',
    this.boxOrientation = 'brood_near_rail',
    this.healthStatus = 'healthy',
  });

  factory Hive.fromJson(Map<String, dynamic> json) {
    return Hive(
      id: json['id'] as String,
      name: json['name'] as String,
      trailerId: json['trailer_id'] as String,
      hiveNumber: json['hive_number'] as int,
      currentTemp: (json['current_temp'] as num?)?.toDouble(),
      currentHumidity: (json['current_humidity'] as num?)?.toDouble(),
      currentWeight: (json['current_weight'] as num?)?.toDouble(),
      queenStatus: json['queen_status'] as String? ?? 'unknown',
      entranceState: json['entrance_state'] as String? ?? 'open',
      boxOrientation: json['box_orientation'] as String? ?? 'brood_near_rail',
      healthStatus: json['health_status'] as String? ?? 'healthy',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'trailer_id': trailerId,
        'hive_number': hiveNumber,
        'current_temp': currentTemp,
        'current_humidity': currentHumidity,
        'current_weight': currentWeight,
        'queen_status': queenStatus,
        'entrance_state': entranceState,
        'box_orientation': boxOrientation,
        'health_status': healthStatus,
      };

  Hive copyWith({
    String? id,
    String? name,
    String? trailerId,
    int? hiveNumber,
    double? currentTemp,
    double? currentHumidity,
    double? currentWeight,
    String? queenStatus,
    String? entranceState,
    String? boxOrientation,
    String? healthStatus,
  }) {
    return Hive(
      id: id ?? this.id,
      name: name ?? this.name,
      trailerId: trailerId ?? this.trailerId,
      hiveNumber: hiveNumber ?? this.hiveNumber,
      currentTemp: currentTemp ?? this.currentTemp,
      currentHumidity: currentHumidity ?? this.currentHumidity,
      currentWeight: currentWeight ?? this.currentWeight,
      queenStatus: queenStatus ?? this.queenStatus,
      entranceState: entranceState ?? this.entranceState,
      boxOrientation: boxOrientation ?? this.boxOrientation,
      healthStatus: healthStatus ?? this.healthStatus,
    );
  }
}
