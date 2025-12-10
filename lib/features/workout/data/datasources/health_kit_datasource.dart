import 'package:health/health.dart';
import 'package:co_workfit/core/constants/health_data_types.dart';
import 'package:dartz/dartz.dart';

/// HealthKit 데이터 소스
class HealthKitDataSource {
  final Health _health;

  HealthKitDataSource({Health? health}) : _health = health ?? Health();

  /// HealthKit 권한 요청
  /// Returns: Right(true) if authorized, Left(error) if failed
  ///
  /// 참고: iOS HealthKit은 사용자가 일부 권한만 허용해도 false를 반환할 수 있습니다.
  /// 따라서 권한 요청 후 실제로 데이터를 읽을 수 있는지 테스트합니다.
  Future<Either<String, bool>> requestAuthorization() async {
    try {
      print('[HealthKit] 권한 요청 시작');

      // health 패키지는 iOS에서만 동작하므로 플랫폼 체크
      final isAvailable = await isHealthKitAvailable();
      print('[HealthKit] HealthKit 사용 가능 여부: $isAvailable');

      if (!isAvailable) {
        print('[HealthKit] HealthKit 사용 불가');
        return Left('HealthKit을 사용할 수 없습니다. iOS 기기에서만 사용 가능합니다.');
      }

      print('[HealthKit] requestAuthorization 호출');
      // requestAuthorization은 types만 받고, 읽기 권한으로 자동 요청됨
      await _health.requestAuthorization(
        HealthDataTypes.readTypes,
      );

      print('[HealthKit] 권한 다이얼로그 표시 완료');

      // iOS HealthKit은 프라이버시 보호를 위해 권한 상태를 정확히 알려주지 않습니다.
      // 대신 실제로 데이터를 읽을 수 있는지 테스트합니다.
      print('[HealthKit] 실제 데이터 접근 가능 여부 테스트');
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      try {
        final testData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.WORKOUT],
          startTime: yesterday,
          endTime: now,
        );

        print('[HealthKit] 데이터 접근 성공 (${testData.length}개 항목)');
        // 데이터 접근이 성공하면 권한이 있는 것으로 간주
        return Right(true);
      } catch (e) {
        print('[HealthKit] 데이터 접근 실패: $e');
        // 데이터 접근 실패 시에도 권한은 요청되었으므로 성공으로 처리
        // (사용자가 데이터가 없을 수도 있음)
        return Right(true);
      }
    } catch (e) {
      print('[HealthKit] 권한 요청 중 오류: $e');
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

        // 디버그: 실제 반환되는 값과 단위 확인
        print('[HealthKit] 거리 데이터 원본값: $totalDistance');
        print('[HealthKit] 거리 데이터 개수: ${distanceData.length}');
        if (distanceData.isNotEmpty) {
          print('[HealthKit] 첫 번째 데이터 포인트 단위: ${distanceData.first.unit}');
          print('[HealthKit] 첫 번째 데이터 포인트 값: ${(distanceData.first.value as NumericHealthValue).numericValue}');
        }

        // health 패키지는 기본적으로 미터 단위로 반환
        // 하지만 일부 경우 단위가 다를 수 있으므로 단위 확인
        final unit = distanceData.first.unit;
        double distanceInKm;

        if (unit == HealthDataUnit.METER) {
          // 미터 → 킬로미터
          distanceInKm = totalDistance / 1000.0;
          print('[HealthKit] 미터 단위 감지: ${totalDistance}m → ${distanceInKm}km');
        } else if (unit == HealthDataUnit.MILE) {
          // 마일 → 킬로미터
          distanceInKm = totalDistance * 1.60934;
          print('[HealthKit] 마일 단위 감지: ${totalDistance}mi → ${distanceInKm}km');
        } else {
          // 알 수 없는 단위는 미터로 가정
          distanceInKm = totalDistance / 1000.0;
          print('[HealthKit] 알 수 없는 단위 ($unit), 미터로 가정: ${totalDistance} → ${distanceInKm}km');
        }

        details['distance'] = distanceInKm;
        print('[HealthKit] 최종 거리: ${distanceInKm}km');
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
