import 'package:health/health.dart';
import 'package:co_workfit/core/constants/health_data_types.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:dartz/dartz.dart';

/// Health Connect 데이터 소스
/// Android에서 Health Connect를 통해 여러 소스(Google Fit, Samsung Health 등)의 데이터를 통합 관리합니다.
class HealthConnectDataSource {
  final Health _health;

  HealthConnectDataSource({Health? health}) : _health = health ?? Health();

  /// Health Connect 권한 요청
  Future<Either<String, bool>> requestAuthorization() async {
    try {
      print('[HealthConnect] 권한 요청 시작');

      final isAvailable = await isHealthConnectAvailable();
      print('[HealthConnect] Health Connect 사용 가능 여부: $isAvailable');

      if (!isAvailable) {
        return Left('Health Connect를 사용할 수 없습니다. Android 14 이상 또는 Health Connect 앱이 필요합니다.');
      }

      final authorized = await _health.requestAuthorization(
        HealthDataTypes.readTypes,
        permissions: HealthDataTypes.readTypes
            .map((type) => HealthDataAccess.READ)
            .toList(),
      );

      print('[HealthConnect] 권한 요청 결과: $authorized');

      if (authorized) {
        return Right(true);
      } else {
        // 부분 권한이라도 데이터 접근 시도
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        try {
          await _health.getHealthDataFromTypes(
            types: [HealthDataType.STEPS],
            startTime: yesterday,
            endTime: now,
          );
          return Right(true);
        } catch (e) {
          return Left('Health Connect 권한이 거부되었습니다.');
        }
      }
    } catch (e) {
      print('[HealthConnect] 권한 요청 중 오류: $e');
      return Left('Health Connect 권한 요청 중 오류: ${e.toString()}');
    }
  }

  /// 특정 기간의 운동 데이터 가져오기 (소스 정보 포함)
  Future<Either<String, List<HealthDataPointWithSource>>> fetchWorkoutDataWithSource({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('[HealthConnect] 운동 데이터 요청: $startDate ~ $endDate');

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: startDate,
        endTime: endDate,
      );

      // 소스 정보를 포함한 데이터로 변환
      final dataWithSource = healthData.map((point) {
        final source = _detectWorkoutSource(point);
        return HealthDataPointWithSource(
          healthDataPoint: point,
          detectedSource: source,
        );
      }).toList();

      print('[HealthConnect] 운동 데이터 ${dataWithSource.length}개 조회됨');

      // 소스별 통계 출력
      final sourceStats = <WorkoutSource, int>{};
      for (final data in dataWithSource) {
        sourceStats[data.detectedSource] = (sourceStats[data.detectedSource] ?? 0) + 1;
      }
      print('[HealthConnect] 소스별 데이터: $sourceStats');

      return Right(dataWithSource);
    } catch (e) {
      print('[HealthConnect] 운동 데이터 가져오기 실패: $e');
      return Left('운동 데이터 가져오기 실패: ${e.toString()}');
    }
  }

  /// HealthDataPoint에서 데이터 소스 감지
  WorkoutSource _detectWorkoutSource(HealthDataPoint point) {
    final sourceName = point.sourceName.toLowerCase();
    final sourceId = point.sourceId.toLowerCase();

    // Samsung Health 감지
    if (sourceName.contains('samsung') ||
        sourceName.contains('shealth') ||
        sourceId.contains('samsung') ||
        sourceId.contains('com.sec.android.app.shealth')) {
      return WorkoutSource.samsungHealth;
    }

    // Google Fit 감지
    if (sourceName.contains('google') ||
        sourceName.contains('fit') ||
        sourceId.contains('google') ||
        sourceId.contains('com.google.android.apps.fitness')) {
      return WorkoutSource.googleFit;
    }

    // Garmin 감지
    if (sourceName.contains('garmin') ||
        sourceId.contains('garmin') ||
        sourceId.contains('com.garmin')) {
      return WorkoutSource.garmin;
    }

    // 기본값: Google Fit (Health Connect 기본)
    return WorkoutSource.googleFit;
  }

  /// 특정 운동에 대한 상세 데이터 가져오기
  Future<Either<String, Map<String, dynamic>>> fetchWorkoutDetails({
    required DateTime workoutStart,
    required DateTime workoutEnd,
  }) async {
    try {
      final details = <String, dynamic>{};

      // 칼로리
      final caloriesData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: workoutStart,
        endTime: workoutEnd,
      );

      if (caloriesData.isNotEmpty) {
        final totalCalories = caloriesData.fold<double>(
          0,
          (sum, point) => sum + (point.value as NumericHealthValue).numericValue,
        );
        details['calories'] = totalCalories.round();
      }

      // 거리
      final distanceData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_DELTA],
        startTime: workoutStart,
        endTime: workoutEnd,
      );

      if (distanceData.isNotEmpty) {
        final totalDistance = distanceData.fold<double>(
          0,
          (sum, point) => sum + (point.value as NumericHealthValue).numericValue,
        );
        details['distance'] = totalDistance / 1000.0;
      }

      // 걸음 수
      final stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: workoutStart,
        endTime: workoutEnd,
      );

      if (stepsData.isNotEmpty) {
        final totalSteps = stepsData.fold<double>(
          0,
          (sum, point) => sum + (point.value as NumericHealthValue).numericValue,
        );
        details['steps'] = totalSteps.round();
      }

      // 심박수
      final heartRateData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: workoutStart,
        endTime: workoutEnd,
      );

      if (heartRateData.isNotEmpty) {
        final heartRates = heartRateData
            .map((point) => (point.value as NumericHealthValue).numericValue)
            .toList();

        if (heartRates.isNotEmpty) {
          final avgHeartRate = heartRates.reduce((a, b) => a + b) / heartRates.length;
          final maxHeartRate = heartRates.reduce((a, b) => a > b ? a : b);

          details['averageHeartRate'] = avgHeartRate.round();
          details['maxHeartRate'] = maxHeartRate.round();
        }
      }

      // 고도
      try {
        final elevationData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.FLIGHTS_CLIMBED],
          startTime: workoutStart,
          endTime: workoutEnd,
        );

        if (elevationData.isNotEmpty) {
          final totalFlights = elevationData.fold<double>(
            0,
            (sum, point) => sum + (point.value as NumericHealthValue).numericValue,
          );
          details['elevationGain'] = totalFlights * 3.0;
        }
      } catch (e) {
        // 지원되지 않을 수 있음
      }

      return Right(details);
    } catch (e) {
      return Left('운동 상세 데이터 가져오기 실패: ${e.toString()}');
    }
  }

  /// Health Connect 사용 가능 여부 확인
  Future<bool> isHealthConnectAvailable() async {
    try {
      return Health().isDataTypeAvailable(HealthDataType.STEPS);
    } catch (e) {
      print('[HealthConnect] 사용 가능 여부 확인 실패: $e');
      return false;
    }
  }

  /// 최근 N일간의 운동 데이터 가져오기
  Future<Either<String, List<HealthDataPointWithSource>>> fetchRecentWorkoutsWithSource({
    int days = 7,
  }) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    return fetchWorkoutDataWithSource(
      startDate: startDate,
      endDate: now,
    );
  }

  /// 연결된 데이터 소스 목록 가져오기
  Future<List<String>> getConnectedSources() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS, HealthDataType.WORKOUT],
        startTime: weekAgo,
        endTime: now,
      );

      final sources = healthData.map((point) => point.sourceName).toSet().toList();
      print('[HealthConnect] 연결된 소스: $sources');
      return sources;
    } catch (e) {
      print('[HealthConnect] 연결된 소스 조회 실패: $e');
      return [];
    }
  }
}

/// 소스 정보가 포함된 HealthDataPoint 래퍼
class HealthDataPointWithSource {
  final HealthDataPoint healthDataPoint;
  final WorkoutSource detectedSource;

  HealthDataPointWithSource({
    required this.healthDataPoint,
    required this.detectedSource,
  });
}
