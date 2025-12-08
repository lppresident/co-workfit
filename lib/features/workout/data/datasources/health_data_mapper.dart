import 'package:health/health.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/core/constants/health_data_types.dart';
import 'package:co_workfit/features/calibration/domain/usecases/calibrate_workout.dart';

/// HealthKit 데이터를 WorkoutEntity로 변환하는 매퍼
class HealthDataMapper {
  final CalibrateWorkout _calibrateWorkout = CalibrateWorkout();

  /// HealthDataPoint를 WorkoutEntity로 변환
  /// [healthPoint]: HealthKit에서 가져온 운동 데이터 포인트
  /// [details]: 운동 상세 데이터 (칼로리, 거리, 심박수 등)
  /// [userId]: 사용자 ID
  WorkoutEntity toWorkoutEntity({
    required HealthDataPoint healthPoint,
    required Map<String, dynamic> details,
    required String userId,
  }) {
    // Workout 타입 매핑
    final workoutValue = healthPoint.value as WorkoutHealthValue;
    final workoutTypeString =
        HealthWorkoutMapper.mapWorkoutType(workoutValue.workoutActivityType);
    final workoutType = WorkoutType.values.firstWhere(
      (e) => e.name == workoutTypeString,
      orElse: () => WorkoutType.other,
    );

    // 시간 정보
    final startTime = healthPoint.dateFrom;
    final endTime = healthPoint.dateTo;
    final durationMinutes = endTime.difference(startTime).inMinutes;

    // 상세 데이터에서 값 추출
    final calories = details['calories'] as int?;
    final distance = details['distance'] as double?;
    final averageHeartRate = details['averageHeartRate'] as int?;
    final maxHeartRate = details['maxHeartRate'] as int?;
    final steps = details['steps'] as int?;
    final elevationGain = details['elevationGain'] as double?;

    // 임시 엔티티 생성 (캘리브레이션 전)
    final tempEntity = WorkoutEntity(
      id: _generateWorkoutId(healthPoint),
      userId: userId,
      source: WorkoutSource.appleHealth,
      type: workoutType,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      distance: distance,
      calories: calories,
      averageHeartRate: averageHeartRate,
      maxHeartRate: maxHeartRate,
      steps: steps,
      elevationGain: elevationGain,
      calibratedWorkload: 0, // 임시값
      calibratedScore: 0, // 임시값
      createdAt: DateTime.now(),
    );

    // 캘리브레이션 실행
    final calibrationResult = _calibrateWorkout.execute(tempEntity);

    // 최종 엔티티 반환
    return tempEntity.copyWith(
      calibratedWorkload: calibrationResult.workload,
      calibratedScore: calibrationResult.score,
    );
  }

  /// 고유한 운동 ID 생성
  String _generateWorkoutId(HealthDataPoint healthPoint) {
    // 시간 기반 ID 생성 (health 패키지에 uuid 프로퍼티가 없을 수 있음)
    final timestamp = healthPoint.dateFrom.millisecondsSinceEpoch;
    final type = healthPoint.type.name;
    return 'apple_health_${type}_$timestamp';
  }

  /// 여러 HealthDataPoint를 WorkoutEntity 리스트로 변환
  Future<List<WorkoutEntity>> toWorkoutEntities({
    required List<HealthDataPoint> healthPoints,
    required Future<Map<String, dynamic>> Function(DateTime start, DateTime end)
        detailsFetcher,
    required String userId,
  }) async {
    final workouts = <WorkoutEntity>[];

    for (final point in healthPoints) {
      // 각 운동에 대한 상세 데이터 가져오기
      final details = await detailsFetcher(
        point.dateFrom,
        point.dateTo,
      );

      final workout = toWorkoutEntity(
        healthPoint: point,
        details: details,
        userId: userId,
      );

      workouts.add(workout);
    }

    return workouts;
  }
}
