class SensorReadingFields {
  static const String tableName = 'sensor_readings';
  static const String id = '_id';
  static const String timestamp = 'timestamp';
  static const String mq4Value = 'mq4_value';
  static const String mq7Value = 'mq7_value';
  static const String isHighReading = 'is_high_reading';

  static const List<String> values = [
    id, timestamp, mq4Value, mq7Value, isHighReading
  ];
}

class SensorReading {
  final int? id;
  final DateTime timestamp;
  final int mq4Value;
  final int mq7Value;
  final bool isHighReading;

  const SensorReading({
    this.id,
    required this.timestamp,
    required this.mq4Value,
    required this.mq7Value,
    required this.isHighReading,
  });

  SensorReading copy({
    int? id,
    DateTime? timestamp,
    int? mq4Value,
    int? mq7Value,
    bool? isHighReading,
  }) =>
      SensorReading(
        id: id ?? this.id,
        timestamp: timestamp ?? this.timestamp,
        mq4Value: mq4Value ?? this.mq4Value,
        mq7Value: mq7Value ?? this.mq7Value,
        isHighReading: isHighReading ?? this.isHighReading,
      );

  static SensorReading fromJson(Map<String, Object?> json) => SensorReading(
        id: json[SensorReadingFields.id] as int?,
        timestamp: DateTime.parse(json[SensorReadingFields.timestamp] as String),
        mq4Value: json[SensorReadingFields.mq4Value] as int,
        mq7Value: json[SensorReadingFields.mq7Value] as int,
        isHighReading: json[SensorReadingFields.isHighReading] == 1,
      );

  Map<String, Object?> toJson() => {
        SensorReadingFields.id: id,
        SensorReadingFields.timestamp: timestamp.toIso8601String(),
        SensorReadingFields.mq4Value: mq4Value,
        SensorReadingFields.mq7Value: mq7Value,
        SensorReadingFields.isHighReading: isHighReading ? 1 : 0,
      };
}
