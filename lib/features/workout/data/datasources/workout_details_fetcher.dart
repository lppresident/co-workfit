import 'package:health/health.dart';
import 'package:dartz/dartz.dart';

/// 운동 상세 데이터 조회를 위한 공통 헬퍼 클래스
///
/// iOS (HealthKit)와 Android (Health Connect) 모두에서
/// 칼로리, 걸음수, 심박수, 고도 등의 상세 데이터를 조회하는 로직을 공통화합니다.
///
/// 주의: 거리 데이터는 WORKOUT의 totalDistance를 사용하므로 여기서 조회하지 않습니다.
class WorkoutDetailsFetcher {
  final Health _health;

  WorkoutDetailsFetcher({Health? health}) : _health = health ?? Health();

  /// 특정 운동에 대한 상세 데이터 가져오기
  ///
  /// [workoutStart]: 운동 시작 시간
  /// [workoutEnd]: 운동 종료 시간
  /// [includeElevation]: 고도 데이터 포함 여부 (일부 플랫폼에서 지원 안 될 수 있음)
  /// Returns: 운동 상세 데이터 Map (calories, steps, averageHeartRate, maxHeartRate, elevationGain)
  Future<Either<String, Map<String, dynamic>>> fetchWorkoutDetails({
    required DateTime workoutStart,
    required DateTime workoutEnd,
    bool includeElevation = true,
  }) async {
    try {
      final details = <String, dynamic>{};

      // 칼로리
      final calories = await _fetchCalories(workoutStart, workoutEnd);
      if (calories != null) {
        details['calories'] = calories;
      }

      // 걸음 수
      final steps = await _fetchSteps(workoutStart, workoutEnd);
      if (steps != null) {
        details['steps'] = steps;
      }

      // 심박수 (평균, 최대)
      final heartRateData = await _fetchHeartRate(workoutStart, workoutEnd);
      if (heartRateData != null) {
        details.addAll(heartRateData);
      }

      // 고도 (옵션)
      if (includeElevation) {
        final elevationGain = await _fetchElevationGain(workoutStart, workoutEnd);
        if (elevationGain != null) {
          details['elevationGain'] = elevationGain;
        }
      }

      return Right(details);
    } catch (e) {
      return Left('운동 상세 데이터 가져오기 실패: ${e.toString()}');
    }
  }

  /// 칼로리 데이터 조회
  Future<int?> _fetchCalories(DateTime start, DateTime end) async {
    try {
      final caloriesData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: end,
      );

      if (caloriesData.isEmpty) return null;

      final totalCalories = caloriesData.fold<double>(
        0,
        (sum, point) => sum + (point.value as NumericHealthValue).numericValue,
      );

      return totalCalories.round();
    } catch (e) {
      return null;
    }
  }

  /// 걸음 수 데이터 조회
  Future<int?> _fetchSteps(DateTime start, DateTime end) async {
    try {
      final stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: start,
        endTime: end,
      );

      if (stepsData.isEmpty) return null;

      final totalSteps = stepsData.fold<double>(
        0,
        (sum, point) => sum + (point.value as NumericHealthValue).numericValue,
      );

      return totalSteps.round();
    } catch (e) {
      return null;
    }
  }

  /// 심박수 데이터 조회 (평균, 최대)
  Future<Map<String, int>?> _fetchHeartRate(DateTime start, DateTime end) async {
    try {
      final heartRateData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );

      if (heartRateData.isEmpty) return null;

      final heartRates = heartRateData
          .map((point) => (point.value as NumericHealthValue).numericValue)
          .toList();

      if (heartRates.isEmpty) return null;

      final avgHeartRate = heartRates.reduce((a, b) => a + b) / heartRates.length;
      final maxHeartRate = heartRates.reduce((a, b) => a > b ? a : b);

      return {
        'averageHeartRate': avgHeartRate.round(),
        'maxHeartRate': maxHeartRate.round(),
      };
    } catch (e) {
      return null;
    }
  }

  /// 고도 데이터 조회 (계단 오른 층수 기반)
  Future<double?> _fetchElevationGain(DateTime start, DateTime end) async {
    try {
      final flightsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.FLIGHTS_CLIMBED],
        startTime: start,
        endTime: end,
      );

      if (flightsData.isEmpty) return null;

      final totalFlights = flightsData.fold<double>(
        0,
        (sum, point) => sum + (point.value as NumericHealthValue).numericValue,
      );

      // 1 flight ≈ 3 meters
      return totalFlights * 3.0;
    } catch (e) {
      // 일부 플랫폼에서 지원되지 않을 수 있음
      return null;
    }
  }
}
