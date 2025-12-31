import 'dart:io' show Platform;
import 'package:health/health.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/utils/logger.dart';

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

      // 속도/페이스 데이터 조회 (디버깅용 로그 포함)
      await _fetchSpeedData(workoutStart, workoutEnd, details);

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

  /// 속도/페이스 데이터 조회 (디버깅용)
  /// 
  /// iOS: WALKING_SPEED (m/s) - 걷기 속도만 지원
  /// Android: SPEED (m/s) - 일반 속도
  Future<void> _fetchSpeedData(
    DateTime start,
    DateTime end,
    Map<String, dynamic> details,
  ) async {
    try {
      AppLogger.info('SpeedData', '===== 속도/페이스 데이터 조회 시작 =====');
      AppLogger.info('SpeedData', '조회 기간: $start ~ $end');

      // iOS: WALKING_SPEED 조회
      if (Platform.isIOS) {
        await _fetchWalkingSpeed(start, end, details);
      }
      
      // Android: SPEED 조회
      if (Platform.isAndroid) {
        await _fetchSpeed(start, end, details);
      }

      AppLogger.info('SpeedData', '===== 속도/페이스 데이터 조회 완료 =====');
    } catch (e) {
      AppLogger.error('SpeedData', '속도 데이터 조회 실패', e);
    }
  }

  /// iOS WALKING_SPEED 데이터 조회
  Future<void> _fetchWalkingSpeed(
    DateTime start,
    DateTime end,
    Map<String, dynamic> details,
  ) async {
    try {
      AppLogger.info('SpeedData', '[iOS] WALKING_SPEED 조회 중...');
      
      final walkingSpeedData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WALKING_SPEED],
        startTime: start,
        endTime: end,
      );

      AppLogger.info('SpeedData', '[iOS] WALKING_SPEED 데이터 개수: ${walkingSpeedData.length}');

      if (walkingSpeedData.isEmpty) {
        AppLogger.info('SpeedData', '[iOS] WALKING_SPEED 데이터 없음');
        return;
      }

      // 각 데이터 포인트 로깅
      for (int i = 0; i < walkingSpeedData.length; i++) {
        final point = walkingSpeedData[i];
        final value = point.value as NumericHealthValue;
        final speedMps = value.numericValue; // m/s
        
        // m/s → 분/km 변환 (페이스)
        // 1 km = 1000m, 1분 = 60초
        // pace (min/km) = 1000 / (speed * 60) = 16.6667 / speed
        final paceMinPerKm = speedMps > 0 ? (1000 / speedMps) / 60 : 0.0;
        final paceMinutes = paceMinPerKm.floor();
        final paceSeconds = ((paceMinPerKm - paceMinutes) * 60).round();
        
        AppLogger.info('SpeedData', 
          '[iOS] WALKING_SPEED[$i]:\n'
          '  - 시간: ${point.dateFrom} ~ ${point.dateTo}\n'
          '  - 속도: ${speedMps.toStringAsFixed(2)} m/s\n'
          '  - 속도(km/h): ${(speedMps * 3.6).toStringAsFixed(2)} km/h\n'
          '  - 페이스: $paceMinutes\'${paceSeconds.toString().padLeft(2, '0')}"/km\n'
          '  - 단위: ${point.unit}\n'
          '  - 소스: ${point.sourceName}'
        );
      }

      // 평균 속도 계산
      final speeds = walkingSpeedData
          .map((p) => (p.value as NumericHealthValue).numericValue)
          .toList();
      final avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
      final maxSpeed = speeds.reduce((a, b) => a > b ? a : b);
      
      // 평균 페이스 계산
      final avgPaceMinPerKm = avgSpeed > 0 ? (1000 / avgSpeed) / 60 : 0.0;
      final avgPaceMinutes = avgPaceMinPerKm.floor();
      final avgPaceSeconds = ((avgPaceMinPerKm - avgPaceMinutes) * 60).round();
      
      // 최고 페이스 계산 (최고 속도 기준)
      final bestPaceMinPerKm = maxSpeed > 0 ? (1000 / maxSpeed) / 60 : 0.0;
      final bestPaceMinutes = bestPaceMinPerKm.floor();
      final bestPaceSeconds = ((bestPaceMinPerKm - bestPaceMinutes) * 60).round();

      AppLogger.info('SpeedData', 
        '[iOS] WALKING_SPEED 요약:\n'
        '  - 평균 속도: ${avgSpeed.toStringAsFixed(2)} m/s (${(avgSpeed * 3.6).toStringAsFixed(2)} km/h)\n'
        '  - 최고 속도: ${maxSpeed.toStringAsFixed(2)} m/s (${(maxSpeed * 3.6).toStringAsFixed(2)} km/h)\n'
        '  - 평균 페이스: $avgPaceMinutes\'${avgPaceSeconds.toString().padLeft(2, '0')}"/km\n'
        '  - 최고 페이스: $bestPaceMinutes\'${bestPaceSeconds.toString().padLeft(2, '0')}"/km'
      );

      // details에 추가 (선택적)
      details['walkingSpeedMps'] = avgSpeed;
      details['walkingSpeedKmh'] = avgSpeed * 3.6;
      details['walkingPaceMinPerKm'] = avgPaceMinPerKm;

    } catch (e) {
      AppLogger.error('SpeedData', '[iOS] WALKING_SPEED 조회 실패', e);
    }
  }

  /// Android SPEED 데이터 조회
  Future<void> _fetchSpeed(
    DateTime start,
    DateTime end,
    Map<String, dynamic> details,
  ) async {
    try {
      AppLogger.info('SpeedData', '[Android] SPEED 조회 중...');
      
      final speedData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SPEED],
        startTime: start,
        endTime: end,
      );

      AppLogger.info('SpeedData', '[Android] SPEED 데이터 개수: ${speedData.length}');

      if (speedData.isEmpty) {
        AppLogger.info('SpeedData', '[Android] SPEED 데이터 없음');
        return;
      }

      // 각 데이터 포인트 로깅
      for (int i = 0; i < speedData.length; i++) {
        final point = speedData[i];
        final value = point.value as NumericHealthValue;
        final speedMps = value.numericValue; // m/s
        
        // m/s → 분/km 변환 (페이스)
        final paceMinPerKm = speedMps > 0 ? (1000 / speedMps) / 60 : 0.0;
        final paceMinutes = paceMinPerKm.floor();
        final paceSeconds = ((paceMinPerKm - paceMinutes) * 60).round();
        
        AppLogger.info('SpeedData', 
          '[Android] SPEED[$i]:\n'
          '  - 시간: ${point.dateFrom} ~ ${point.dateTo}\n'
          '  - 속도: ${speedMps.toStringAsFixed(2)} m/s\n'
          '  - 속도(km/h): ${(speedMps * 3.6).toStringAsFixed(2)} km/h\n'
          '  - 페이스: $paceMinutes\'${paceSeconds.toString().padLeft(2, '0')}"/km\n'
          '  - 단위: ${point.unit}\n'
          '  - 소스: ${point.sourceName}'
        );
      }

      // 평균 속도 계산
      final speeds = speedData
          .map((p) => (p.value as NumericHealthValue).numericValue)
          .toList();
      final avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
      final maxSpeed = speeds.reduce((a, b) => a > b ? a : b);
      
      // 평균 페이스 계산
      final avgPaceMinPerKm = avgSpeed > 0 ? (1000 / avgSpeed) / 60 : 0.0;
      final avgPaceMinutes = avgPaceMinPerKm.floor();
      final avgPaceSeconds = ((avgPaceMinPerKm - avgPaceMinutes) * 60).round();
      
      // 최고 페이스 계산 (최고 속도 기준)
      final bestPaceMinPerKm = maxSpeed > 0 ? (1000 / maxSpeed) / 60 : 0.0;
      final bestPaceMinutes = bestPaceMinPerKm.floor();
      final bestPaceSeconds = ((bestPaceMinPerKm - bestPaceMinutes) * 60).round();

      AppLogger.info('SpeedData', 
        '[Android] SPEED 요약:\n'
        '  - 평균 속도: ${avgSpeed.toStringAsFixed(2)} m/s (${(avgSpeed * 3.6).toStringAsFixed(2)} km/h)\n'
        '  - 최고 속도: ${maxSpeed.toStringAsFixed(2)} m/s (${(maxSpeed * 3.6).toStringAsFixed(2)} km/h)\n'
        '  - 평균 페이스: $avgPaceMinutes\'${avgPaceSeconds.toString().padLeft(2, '0')}"/km\n'
        '  - 최고 페이스: $bestPaceMinutes\'${bestPaceSeconds.toString().padLeft(2, '0')}"/km'
      );

      // details에 추가 (선택적)
      details['speedMps'] = avgSpeed;
      details['speedKmh'] = avgSpeed * 3.6;
      details['paceMinPerKm'] = avgPaceMinPerKm;

    } catch (e) {
      AppLogger.error('SpeedData', '[Android] SPEED 조회 실패', e);
    }
  }
}
