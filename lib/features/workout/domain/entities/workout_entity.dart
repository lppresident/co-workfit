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
  final int durationMinutes;

  // 원본 데이터 (플랫폼별로 다를 수 있음)
  final double? distance; // km
  final int? calories; // kcal
  final int? averageHeartRate; // bpm
  final int? maxHeartRate; // bpm
  final int? steps;
  final double? elevationGain; // meters

  // 캘리브레이션된 데이터
  final double calibratedWorkload; // 표준화된 노동 지수 (0-100)
  final int calibratedScore; // 점수 (캘리브레이션 후)

  final DateTime createdAt;
  final DateTime? syncedAt;

  const WorkoutEntity({
    required this.id,
    required this.userId,
    required this.source,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.distance,
    this.calories,
    this.averageHeartRate,
    this.maxHeartRate,
    this.steps,
    this.elevationGain,
    required this.calibratedWorkload,
    required this.calibratedScore,
    required this.createdAt,
    this.syncedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        source,
        type,
        startTime,
        endTime,
        durationMinutes,
        distance,
        calories,
        averageHeartRate,
        maxHeartRate,
        steps,
        elevationGain,
        calibratedWorkload,
        calibratedScore,
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
    int? durationMinutes,
    double? distance,
    int? calories,
    int? averageHeartRate,
    int? maxHeartRate,
    int? steps,
    double? elevationGain,
    double? calibratedWorkload,
    int? calibratedScore,
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
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      steps: steps ?? this.steps,
      elevationGain: elevationGain ?? this.elevationGain,
      calibratedWorkload: calibratedWorkload ?? this.calibratedWorkload,
      calibratedScore: calibratedScore ?? this.calibratedScore,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
}
