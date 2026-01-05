import 'package:health/health.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/core/constants/health_data_types.dart';
import 'package:co_workfit/features/workout/data/datasources/health_connect_datasource.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// Health 데이터를 WorkoutEntity로 변환하는 매퍼
/// Apple HealthKit, Google Fit, Samsung Health 데이터 모두 지원
class HealthDataMapper {

  /// HealthDataPoint를 WorkoutEntity로 변환
  /// [healthPoint]: Health 패키지에서 가져온 운동 데이터 포인트
  /// [details]: 운동 상세 데이터 (칼로리, 거리, 심박수 등)
  /// [userId]: 사용자 ID
  /// [source]: 데이터 소스 (appleHealth, googleFit, samsungHealth 등)
  WorkoutEntity toWorkoutEntity({
    required HealthDataPoint healthPoint,
    required Map<String, dynamic> details,
    required String userId,
    WorkoutSource source = WorkoutSource.appleHealth,
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
    final durationSeconds = endTime.difference(startTime).inSeconds;

    // WorkoutHealthValue에서 직접 거리 데이터 추출 (중복 합산 방지)
    double? distance;
    if (workoutValue.totalDistance != null && workoutValue.totalDistanceUnit != null) {
      final rawDistance = workoutValue.totalDistance!.toDouble();
      final unit = workoutValue.totalDistanceUnit!;

      // 단위에 따라 킬로미터로 변환
      if (unit == HealthDataUnit.METER) {
        distance = rawDistance / 1000.0;
        AppLogger.debug('HealthDataMapper', 'WORKOUT 거리: ${rawDistance}m → $distance km');
      } else if (unit == HealthDataUnit.MILE) {
        distance = rawDistance * 1.60934;
        AppLogger.debug('HealthDataMapper', 'WORKOUT 거리: ${rawDistance}mi → $distance km');
      } else {
        // 알 수 없는 단위는 미터로 가정
        distance = rawDistance / 1000.0;
        AppLogger.debug('HealthDataMapper', 'WORKOUT 거리 (알 수 없는 단위 $unit): $rawDistance → $distance km');
      }
    } else {
      // WORKOUT에 totalDistance가 없는 경우
      AppLogger.warning('HealthDataMapper',
        'WORKOUT totalDistance null - 위치 권한 필요 가능성 있음 '
        '(source: $source, type: $workoutType, '
        'start: $startTime, end: $endTime)');

      // fallback: details에서 가져옴 (하위 호환성)
      if (details.containsKey('distance') && details['distance'] != null) {
        distance = details['distance'] as double?;
        AppLogger.info('HealthDataMapper', 'fallback distance 사용: $distance km');
      }
    }

    // 상세 데이터에서 값 추출 (거리는 WORKOUT에서 직접 가져오므로 제외)
    final calories = details['calories'] as int?;
    final averageHeartRate = details['averageHeartRate'] as int?;
    final maxHeartRate = details['maxHeartRate'] as int?;
    final steps = details['steps'] as int?;
    final elevationGain = details['elevationGain'] as double?;

    return WorkoutEntity(
      id: _generateWorkoutId(healthPoint),
      userId: userId,
      source: source,
      type: workoutType,
      startTime: startTime,
      endTime: endTime,
      durationSeconds: durationSeconds,
      distance: distance,
      calories: calories,
      averageHeartRate: averageHeartRate,
      maxHeartRate: maxHeartRate,
      steps: steps,
      elevationGain: elevationGain,
      createdAt: DateTime.now(),
    );
  }

  /// 고유한 운동 ID 생성
  /// 형식: {timestamp}_{duration}
  /// - timestamp: 운동 시작 시간 (밀리초)
  /// - duration: 운동 시간 (초) - 같은 시간에 시작한 다른 운동과 구분
  /// 
  /// Note: Firestore 문서 ID는 ${userId}_${workoutId} 형태로 저장되어 전역 고유성 보장
  String _generateWorkoutId(HealthDataPoint healthPoint) {
    final timestamp = healthPoint.dateFrom.millisecondsSinceEpoch;
    final duration = healthPoint.dateTo.difference(healthPoint.dateFrom).inSeconds;
    return '${timestamp}_$duration';
  }

  /// 여러 HealthDataPoint를 WorkoutEntity 리스트로 변환
  /// [source]: 데이터 소스 (appleHealth, googleFit, samsungHealth 등)
  Future<List<WorkoutEntity>> toWorkoutEntities({
    required List<HealthDataPoint> healthPoints,
    required Future<Map<String, dynamic>> Function(
      DateTime start,
      DateTime end,
    ) detailsFetcher,
    required String userId,
    WorkoutSource source = WorkoutSource.appleHealth,
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
        source: source,
      );

      workouts.add(workout);
    }

    return workouts;
  }

  /// Health Connect 소스 정보가 포함된 데이터를 WorkoutEntity 리스트로 변환
  /// 각 데이터 포인트의 실제 소스(Samsung Health, Google Fit 등)를 감지하여 변환
  Future<List<WorkoutEntity>> toWorkoutEntitiesWithAutoSource({
    required List<HealthDataPointWithSource> healthPointsWithSource,
    required Future<Map<String, dynamic>> Function(
      DateTime start,
      DateTime end,
    ) detailsFetcher,
    required String userId,
  }) async {
    final workouts = <WorkoutEntity>[];

    for (final pointWithSource in healthPointsWithSource) {
      final point = pointWithSource.healthDataPoint;
      final source = pointWithSource.detectedSource;

      // 각 운동에 대한 상세 데이터 가져오기
      final details = await detailsFetcher(
        point.dateFrom,
        point.dateTo,
      );

      final workout = toWorkoutEntity(
        healthPoint: point,
        details: details,
        userId: userId,
        source: source,
      );

      workouts.add(workout);
    }

    return workouts;
  }
}
