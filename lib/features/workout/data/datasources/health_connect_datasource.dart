import 'package:health/health.dart';
import 'package:co_workfit/core/constants/health_data_types.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/core/platform/health_connect_checker.dart';
import 'package:dartz/dartz.dart';
import 'package:url_launcher/url_launcher.dart';

/// Health Connect 데이터 소스
/// Android에서 Health Connect를 통해 여러 소스(Google Fit, Samsung Health 등)의 데이터를 통합 관리합니다.
class HealthConnectDataSource {
  final Health _health;

  HealthConnectDataSource({Health? health}) : _health = health ?? Health();

  /// Health Connect 권한 요청
  ///
  /// 개선된 권한 요청 플로우:
  /// 1. 먼저 Health Connect 앱 설치 여부를 확인 (MethodChannel 사용)
  /// 2. 미설치 시 'HEALTH_CONNECT_NOT_INSTALLED' 반환
  /// 3. 설치되어 있으면 권한 요청 진행 (10초 타임아웃)
  /// 4. requestAuthorization이 false를 반환해도 실제 데이터 조회로 재확인
  Future<Either<String, bool>> requestAuthorization() async {
    try {
      // 1단계: Health Connect 앱 설치 여부 확인 (정확한 방법)
      final isInstalled = await HealthConnectChecker.isHealthConnectInstalled();

      if (!isInstalled) {
        print('[HealthConnect] Health Connect 앱이 설치되지 않음');
        return const Left('HEALTH_CONNECT_NOT_INSTALLED');
      }

      print('[HealthConnect] Health Connect 앱 설치 확인됨, 권한 요청 시작');

      // 2단계: 전체 권한 요청 (10초 타임아웃)
      final authorized = await _health
          .requestAuthorization(
            HealthDataTypes.readTypes,
            permissions: HealthDataTypes.readTypes
                .map((type) => HealthDataAccess.READ)
                .toList(),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('[HealthConnect] 권한 요청 타임아웃 (10초)');
              return false;
            },
          );

      print('[HealthConnect] requestAuthorization 결과: $authorized');

      // 3단계: authorized가 false여도 실제 데이터 접근으로 재확인
      // Health Connect는 이미 권한이 있을 때도 false를 반환하는 버그가 있음
      if (!authorized) {
        print('[HealthConnect] false 반환됨 - 실제 데이터 접근 테스트 시도');

        try {
          // 간단한 데이터 조회로 실제 권한 확인
          final testData = await _health
              .getHealthDataFromTypes(
                types: [HealthDataType.STEPS],
                startTime: DateTime.now().subtract(const Duration(days: 1)),
                endTime: DateTime.now(),
              )
              .timeout(const Duration(seconds: 3));

          print('[HealthConnect] 테스트 데이터 조회 성공 - 실제로는 권한 있음');
          return const Right(true);
        } catch (e) {
          print('[HealthConnect] 테스트 데이터 조회 실패: $e');
          // 실제로 권한이 없는 것으로 판단
          return const Left('HEALTH_PERMISSION_DENIED');
        }
      }

      print('[HealthConnect] 권한 승인됨');
      return const Right(true);
    } catch (e) {
      print('[HealthConnect] 권한 요청 중 예외 발생: $e');
      final errorString = e.toString().toLowerCase();

      // 혹시 모를 fallback: health 패키지가 'not available' 반환하는 경우
      if (errorString.contains('not available')) {
        return const Left('HEALTH_CONNECT_NOT_INSTALLED');
      }

      return Left('Health Connect 권한 요청 중 오류: ${e.toString()}');
    }
  }

  /// Health Connect 설치 유도 (Play Store로 이동)
  Future<void> installHealthConnect() async {
    try {
      final url = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Play Store를 열 수 없습니다.');
      }
    } catch (e) {
      throw Exception('Health Connect 설치를 시작할 수 없습니다: $e');
    }
  }

  /// Health Connect 앱 설정 화면 열기
  ///
  /// health 패키지의 권한 다이얼로그가 작동하지 않는 경우
  /// 사용자를 직접 Health Connect 설정으로 이동시킵니다.
  Future<void> openHealthConnectSettings() async {
    try {
      // Health Connect 앱 설정 화면으로 이동
      final url = Uri.parse('package:com.google.android.apps.healthdata');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // 설정 앱에서 Health Connect 검색
        final settingsUrl = Uri.parse('android-app://com.android.settings');
        if (await canLaunchUrl(settingsUrl)) {
          await launchUrl(settingsUrl, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('설정 화면을 열 수 없습니다.');
        }
      }
    } catch (e) {
      print('[HealthConnect] 설정 화면 열기 실패: $e');
      throw Exception('Health Connect 설정을 열 수 없습니다: $e');
    }
  }

  /// 특정 기간의 운동 데이터 가져오기 (소스 정보 포함)
  Future<Either<String, List<HealthDataPointWithSource>>> fetchWorkoutDataWithSource({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('[HealthConnect] 운동 데이터 요청: $startDate ~ $endDate');

      final healthData = await _health
          .getHealthDataFromTypes(
            types: [HealthDataType.WORKOUT],
            startTime: startDate,
            endTime: endDate,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('[HealthConnect] 데이터 조회 타임아웃 (10초)');
              return [];
            },
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
  /// 거리 데이터는 WORKOUT의 totalDistance를 직접 사용하므로 여기서는 조회하지 않음
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
  ///
  /// 주의: 이 메소드는 Health Connect 앱의 실제 설치 여부가 아니라
  /// 데이터 타입에 대한 접근 권한이 있는지를 확인합니다.
  /// 앱 설치 여부를 확인하려면 requestAuthorization()의 예외 처리를 사용하세요.
  Future<bool> isHealthConnectAvailable() async {
    try {
      return Health().isDataTypeAvailable(HealthDataType.STEPS);
    } catch (e) {
      print('[HealthConnect] 사용 가능 여부 확인 실패: $e');
      return false;
    }
  }

  /// Health Connect 앱 설치 여부 확인
  ///
  /// MethodChannel을 통해 정확하게 Health Connect 앱의 설치 여부를 확인합니다.
  Future<bool> isHealthConnectInstalled() async {
    try {
      return await HealthConnectChecker.isHealthConnectInstalled();
    } catch (e) {
      print('[HealthConnect] 설치 여부 확인 실패: $e');
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
