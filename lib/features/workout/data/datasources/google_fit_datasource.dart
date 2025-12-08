import 'package:health/health.dart';
import 'package:co_workfit/core/constants/health_data_types.dart';
import 'package:dartz/dartz.dart';

/// Google Fit 데이터 소스
/// Android 기기에서 Google Fit 데이터를 가져옵니다.
class GoogleFitDataSource {
  final Health _health;

  GoogleFitDataSource({Health? health}) : _health = health ?? Health();

  /// Google Fit 권한 요청
  /// Returns: Right(true) if authorized, Left(error) if failed
  Future<Either<String, bool>> requestAuthorization() async {
    try {
      print('[GoogleFit] 권한 요청 시작');

      // Google Fit 사용 가능 여부 체크
      final isAvailable = await isGoogleFitAvailable();
      print('[GoogleFit] Google Fit 사용 가능 여부: $isAvailable');

      if (!isAvailable) {
        print('[GoogleFit] Google Fit 사용 불가');
        return Left('Google Fit을 사용할 수 없습니다. Android 기기에서만 사용 가능합니다.');
      }

      print('[GoogleFit] requestAuthorization 호출');
      // health 패키지는 Android에서 Google Fit 권한 요청
      final authorized = await _health.requestAuthorization(
        HealthDataTypes.readTypes,
        permissions: HealthDataTypes.readTypes
            .map((type) => HealthDataAccess.READ)
            .toList(),
      );

      print('[GoogleFit] 권한 요청 결과: $authorized');

      if (authorized) {
        return Right(true);
      } else {
        // 권한이 완전히 거부된 경우에도, 일부 데이터는 접근 가능할 수 있음
        // 실제 데이터 접근 테스트
        print('[GoogleFit] 실제 데이터 접근 가능 여부 테스트');
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        try {
          await _health.getHealthDataFromTypes(
            types: [HealthDataType.STEPS],
            startTime: yesterday,
            endTime: now,
          );
          print('[GoogleFit] 데이터 접근 성공');
          return Right(true);
        } catch (e) {
          print('[GoogleFit] 데이터 접근 실패: $e');
          return Left('Google Fit 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.');
        }
      }
    } catch (e) {
      print('[GoogleFit] 권한 요청 중 오류: $e');
      return Left('Google Fit 권한 요청 중 오류 발생: ${e.toString()}');
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
      print('[GoogleFit] 운동 데이터 요청: $startDate ~ $endDate');

      // WORKOUT 타입 데이터 가져오기
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: startDate,
        endTime: endDate,
      );

      print('[GoogleFit] 운동 데이터 ${healthData.length}개 조회됨');
      return Right(healthData);
    } catch (e) {
      print('[GoogleFit] 운동 데이터 가져오기 실패: $e');
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

      // 칼로리 데이터 (Google Fit은 ACTIVE_ENERGY_BURNED 또는 TOTAL_CALORIES_BURNED)
      final caloriesData = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
        startTime: workoutStart,
        endTime: workoutEnd,
      );

      if (caloriesData.isNotEmpty) {
        final totalCalories = caloriesData.fold<double>(
          0,
          (sum, point) =>
              sum + (point.value as NumericHealthValue).numericValue,
        );
        details['calories'] = totalCalories.round();
      }

      // 거리 데이터
      final distanceData = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.DISTANCE_DELTA,
        ],
        startTime: workoutStart,
        endTime: workoutEnd,
      );

      if (distanceData.isNotEmpty) {
        final totalDistance = distanceData.fold<double>(
          0,
          (sum, point) =>
              sum + (point.value as NumericHealthValue).numericValue,
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
          (sum, point) =>
              sum + (point.value as NumericHealthValue).numericValue,
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

      // 고도 상승 (Google Fit에서 지원하는 경우)
      try {
        final elevationData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.FLIGHTS_CLIMBED],
          startTime: workoutStart,
          endTime: workoutEnd,
        );

        if (elevationData.isNotEmpty) {
          final totalFlights = elevationData.fold<double>(
            0,
            (sum, point) =>
                sum + (point.value as NumericHealthValue).numericValue,
          );
          // 1 flight ≈ 3 meters
          details['elevationGain'] = totalFlights * 3.0;
        }
      } catch (e) {
        // FLIGHTS_CLIMBED가 지원되지 않을 수 있음
        print('[GoogleFit] 고도 데이터 가져오기 실패 (지원되지 않을 수 있음): $e');
      }

      return Right(details);
    } catch (e) {
      return Left('운동 상세 데이터 가져오기 실패: ${e.toString()}');
    }
  }

  /// Google Fit 사용 가능 여부 확인
  Future<bool> isGoogleFitAvailable() async {
    try {
      // Android에서 Google Fit 사용 가능 여부 확인
      // health 패키지는 Android에서 자동으로 Google Fit을 사용
      return Health().isDataTypeAvailable(HealthDataType.STEPS);
    } catch (e) {
      print('[GoogleFit] 사용 가능 여부 확인 실패: $e');
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

  /// 오늘의 걸음 수 가져오기
  Future<Either<String, int>> fetchTodaySteps() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );

      if (stepsData.isEmpty) {
        return Right(0);
      }

      final totalSteps = stepsData.fold<double>(
        0,
        (sum, point) => sum + (point.value as NumericHealthValue).numericValue,
      );

      return Right(totalSteps.round());
    } catch (e) {
      return Left('걸음 수 가져오기 실패: ${e.toString()}');
    }
  }

  /// 오늘의 칼로리 소모량 가져오기
  Future<Either<String, int>> fetchTodayCalories() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final caloriesData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: now,
      );

      if (caloriesData.isEmpty) {
        return Right(0);
      }

      final totalCalories = caloriesData.fold<double>(
        0,
        (sum, point) => sum + (point.value as NumericHealthValue).numericValue,
      );

      return Right(totalCalories.round());
    } catch (e) {
      return Left('칼로리 가져오기 실패: ${e.toString()}');
    }
  }
}
