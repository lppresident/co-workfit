import 'package:health/health.dart';
import 'package:co_workfit/core/constants/health_data_types.dart';
import 'package:dartz/dartz.dart';

/// HealthKit 데이터 소스
class HealthKitDataSource {
  final Health _health;

  HealthKitDataSource({Health? health}) : _health = health ?? Health();

  /// HealthKit 권한 요청
  /// Returns: Right(true) if authorized, Left(error) if failed
  Future<Either<String, bool>> requestAuthorization() async {
    try {
      final authorized = await _health.requestAuthorization(
        HealthDataTypes.readTypes,
        permissions: HealthDataTypes.readTypes
            .map((type) => HealthDataAccess.READ)
            .toList(),
      );

      if (authorized) {
        return Right(true);
      } else {
        return Left('HealthKit 권한이 거부되었습니다.');
      }
    } catch (e) {
      return Left('HealthKit 권한 요청 중 오류 발생: ${e.toString()}');
    }
  }

  /// 특정 기간의 운동 데이터 가져오기
  /// [startDate]: 시작 날짜
  /// [endDate]: 종료 날짜
  /// Returns: 운동 데이터 리스트
  Future<Either<String, List<HealthDataPoint>>> fetchWorkoutData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // WORKOUT 타입 데이터 가져오기
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: startDate,
        endTime: endDate,
      );

      return Right(healthData);
    } catch (e) {
      return Left('운동 데이터 가져오기 실패: ${e.toString()}');
    }
  }

  /// 특정 운동에 대한 상세 데이터 가져오기 (칼로리, 거리, 심박수 등)
  /// [workoutStart]: 운동 시작 시간
  /// [workoutEnd]: 운동 종료 시간
  /// Returns: 운동 상세 데이터 Map
  Future<Either<String, Map<String, dynamic>>> fetchWorkoutDetails({
    required DateTime workoutStart,
    required DateTime workoutEnd,
  }) async {
    try {
      final details = <String, dynamic>{};

      // 칼로리 데이터
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

      // 거리 데이터 (걷기/달리기)
      final distanceData = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.DISTANCE_WALKING_RUNNING,
          HealthDataType.DISTANCE_CYCLING,
          HealthDataType.DISTANCE_SWIMMING,
        ],
        startTime: workoutStart,
        endTime: workoutEnd,
      );

      if (distanceData.isNotEmpty) {
        final totalDistance = distanceData.fold<double>(
          0,
          (sum, point) => sum + (point.value as NumericHealthValue).numericValue,
        );
        // meters to kilometers
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

      // 심박수 데이터
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
          final avgHeartRate =
              heartRates.reduce((a, b) => a + b) / heartRates.length;
          final maxHeartRate = heartRates.reduce((a, b) => a > b ? a : b);

          details['averageHeartRate'] = avgHeartRate.round();
          details['maxHeartRate'] = maxHeartRate.round();
        }
      }

      // 계단 오른 층수 (고도 게인 계산에 사용)
      final flightsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.FLIGHTS_CLIMBED],
        startTime: workoutStart,
        endTime: workoutEnd,
      );

      if (flightsData.isNotEmpty) {
        final totalFlights = flightsData.fold<double>(
          0,
          (sum, point) => sum + (point.value as NumericHealthValue).numericValue,
        );
        // 1 flight ≈ 3 meters
        details['elevationGain'] = totalFlights * 3.0;
      }

      return Right(details);
    } catch (e) {
      return Left('운동 상세 데이터 가져오기 실패: ${e.toString()}');
    }
  }

  /// HealthKit 사용 가능 여부 확인
  Future<bool> isHealthKitAvailable() async {
    try {
      return Health().isDataTypeAvailable(HealthDataType.WORKOUT);
    } catch (e) {
      return false;
    }
  }

  /// 오늘의 운동 데이터 가져오기
  Future<Either<String, List<HealthDataPoint>>> fetchTodayWorkouts() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return fetchWorkoutData(
      startDate: startOfDay,
      endDate: now,
    );
  }

  /// 최근 N일간의 운동 데이터 가져오기
  Future<Either<String, List<HealthDataPoint>>> fetchRecentWorkouts({
    int days = 7,
  }) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    return fetchWorkoutData(
      startDate: startDate,
      endDate: now,
    );
  }
}
