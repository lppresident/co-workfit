/// Garmin Activity 응답 모델
class GarminActivity {
  final String activityId;
  final String activityType;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final double? distanceMeters;
  final int? calories;
  final int? averageHeartRate;
  final int? maxHeartRate;
  final double? elevationGainMeters;
  final double? elevationLossMeters;
  final int? steps;

  const GarminActivity({
    required this.activityId,
    required this.activityType,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    this.distanceMeters,
    this.calories,
    this.averageHeartRate,
    this.maxHeartRate,
    this.elevationGainMeters,
    this.elevationLossMeters,
    this.steps,
  });

  /// JSON에서 생성
  factory GarminActivity.fromJson(Map<String, dynamic> json) {
    return GarminActivity(
      activityId: json['activityId'].toString(),
      activityType: json['activityType'] as String? ?? 'OTHER',
      startTime: DateTime.parse(json['startTimeGMT'] as String),
      endTime: DateTime.parse(json['endTimeGMT'] as String? ?? json['startTimeGMT'] as String),
      durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
      distanceMeters: (json['distance'] as num?)?.toDouble(),
      calories: (json['calories'] as num?)?.toInt(),
      averageHeartRate: (json['averageHR'] as num?)?.toInt(),
      maxHeartRate: (json['maxHR'] as num?)?.toInt(),
      elevationGainMeters: (json['elevationGain'] as num?)?.toDouble(),
      elevationLossMeters: (json['elevationLoss'] as num?)?.toDouble(),
      steps: (json['steps'] as num?)?.toInt(),
    );
  }

  @override
  String toString() {
    return 'GarminActivity('
        'id: $activityId, '
        'type: $activityType, '
        'distance: ${distanceMeters != null ? "${(distanceMeters! / 1000).toStringAsFixed(2)}km" : "N/A"}, '
        'duration: ${durationSeconds}s'
        ')';
  }
}
