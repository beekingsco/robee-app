class Trailer {
  final String id;
  final String name;
  final String? trailerNumber;
  final String status;
  final String? address;
  final String? timezone;
  final double? batteryLevel;
  final double? storageUsage;
  final String tempUnit;
  final String weightUnit;
  final String inspectionFrequency;
  final Map<String, double>? currentLocation;
  final List<String> sharedWith;
  final bool archived;

  const Trailer({
    required this.id,
    required this.name,
    this.trailerNumber,
    this.status = 'online',
    this.address,
    this.timezone,
    this.batteryLevel,
    this.storageUsage,
    this.tempUnit = 'F',
    this.weightUnit = 'lbs',
    this.inspectionFrequency = 'daily',
    this.currentLocation,
    this.sharedWith = const [],
    this.archived = false,
  });

  factory Trailer.fromJson(Map<String, dynamic> json) {
    return Trailer(
      id: json['id'] as String,
      name: json['name'] as String,
      trailerNumber: json['trailer_number'] as String?,
      status: json['status'] as String? ?? 'online',
      address: json['address'] as String?,
      timezone: json['timezone'] as String?,
      batteryLevel: (json['battery_level'] as num?)?.toDouble(),
      storageUsage: (json['storage_usage'] as num?)?.toDouble(),
      tempUnit: json['temp_unit'] as String? ?? 'F',
      weightUnit: json['weight_unit'] as String? ?? 'lbs',
      inspectionFrequency: json['inspection_frequency'] as String? ?? 'daily',
      currentLocation: json['current_location'] != null
          ? Map<String, double>.from(json['current_location'] as Map)
          : null,
      sharedWith: (json['shared_with'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      archived: json['archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'trailer_number': trailerNumber,
        'status': status,
        'address': address,
        'timezone': timezone,
        'battery_level': batteryLevel,
        'storage_usage': storageUsage,
        'temp_unit': tempUnit,
        'weight_unit': weightUnit,
        'inspection_frequency': inspectionFrequency,
        'current_location': currentLocation,
        'shared_with': sharedWith,
        'archived': archived,
      };

  Trailer copyWith({
    String? id,
    String? name,
    String? trailerNumber,
    String? status,
    String? address,
    String? timezone,
    double? batteryLevel,
    double? storageUsage,
    String? tempUnit,
    String? weightUnit,
    String? inspectionFrequency,
    Map<String, double>? currentLocation,
    List<String>? sharedWith,
    bool? archived,
  }) {
    return Trailer(
      id: id ?? this.id,
      name: name ?? this.name,
      trailerNumber: trailerNumber ?? this.trailerNumber,
      status: status ?? this.status,
      address: address ?? this.address,
      timezone: timezone ?? this.timezone,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      storageUsage: storageUsage ?? this.storageUsage,
      tempUnit: tempUnit ?? this.tempUnit,
      weightUnit: weightUnit ?? this.weightUnit,
      inspectionFrequency: inspectionFrequency ?? this.inspectionFrequency,
      currentLocation: currentLocation ?? this.currentLocation,
      sharedWith: sharedWith ?? this.sharedWith,
      archived: archived ?? this.archived,
    );
  }
}
