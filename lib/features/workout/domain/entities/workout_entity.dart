import 'package:equatable/equatable.dart';

/// 운동 플랫폼 소스
enum WorkoutSource {
  garmin,
  appleHealth,
  googleFit,
  samsungHealth,
  manual,
}

/// 운동 타입
enum WorkoutType {
  running,
  cycling,
  walking,
  swimming,
  weightTraining,
  yoga,
  hiking,
  other,
}

/// 운동 데이터 엔티티 (도메인 모델)
class WorkoutEntity extends Equatable {
  final String id;
  final String userId;
  final WorkoutSource source;
  final WorkoutType type;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds; // 초 단위 (정확한 페이스 계산용)

  // 원본 데이터 (플랫폼별로 다를 수 있음)
  final double? distance; // km (원본 거리)
  final double? correctedDistance; // km (사용자가 수정한 거리)
  final int? calories; // kcal
  final int? averageHeartRate; // bpm
  final int? maxHeartRate; // bpm
  final int? steps;
  final double? elevationGain; // meters

  final DateTime createdAt;
  final DateTime? syncedAt;

  const WorkoutEntity({
    required this.id,
    required this.userId,
    required this.source,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    this.distance,
    this.correctedDistance,
    this.calories,
    this.averageHeartRate,
    this.maxHeartRate,
    this.steps,
    this.elevationGain,
    required this.createdAt,
    this.syncedAt,
  });

  /// 운동 시간 (분 단위, UI 표시용) - 반올림
  int get durationMinutes => (durationSeconds / 60).round();

  @override
  List<Object?> get props => [
        id,
        userId,
        source,
        type,
        startTime,
        endTime,
        durationSeconds,
        distance,
        correctedDistance,
        calories,
        averageHeartRate,
        maxHeartRate,
        steps,
        elevationGain,
        createdAt,
        syncedAt,
      ];

  WorkoutEntity copyWith({
    String? id,
    String? userId,
    WorkoutSource? source,
    WorkoutType? type,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    double? distance,
    double? correctedDistance,
    bool clearCorrectedDistance = false, // true면 correctedDistance를 null로 설정
    int? calories,
    int? averageHeartRate,
    int? maxHeartRate,
    int? steps,
    double? elevationGain,
    DateTime? createdAt,
    DateTime? syncedAt,
  }) {
    return WorkoutEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      source: source ?? this.source,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distance: distance ?? this.distance,
      correctedDistance: clearCorrectedDistance ? null : (correctedDistance ?? this.correctedDistance),
      calories: calories ?? this.calories,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      steps: steps ?? this.steps,
      elevationGain: elevationGain ?? this.elevationGain,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// 실제 표시할 거리 (수정된 거리가 있으면 수정된 거리, 없으면 원본 거리)
  double? get effectiveDistance => correctedDistance ?? distance;

  /// 사용자가 거리를 수정했는지 여부
  bool get hasDistanceCorrection => correctedDistance != null;
}
