import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'garmin_config.dart';
import 'garmin_auth_service.dart';
import 'garmin_api_client.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// Garmin Health API 데이터 소스
///
/// iOS와 Android 모두에서 동일하게 동작합니다.
/// Garmin Connect 계정을 통해 운동 데이터를 가져옵니다.
class GarminDataSource {
  final GarminAuthService _authService;
  final GarminApiClient _apiClient;

  GarminDataSource({
    GarminAuthService? authService,
    GarminApiClient? apiClient,
  })  : _authService = authService ?? GarminAuthService(),
        _apiClient = apiClient ?? GarminApiClient();

  /// Garmin 연동 여부 확인
  Future<bool> isConnected() async {
    return await _authService.isAuthenticated();
  }

  /// Garmin 설정 완료 여부 확인
  bool get isConfigured => GarminConfig.isConfigured;

  /// Garmin 인증 시작
  /// Returns: 인증 URL (브라우저에서 열어야 함)
  Future<Either<String, String>> startAuthentication() async {
    if (!GarminConfig.isConfigured) {
      return Left('Garmin API가 설정되지 않았습니다. garmin_config.dart를 확인해주세요.');
    }
    return await _authService.startAuthorization();
  }

  /// 인증 URL을 브라우저에서 열기
  Future<Either<String, bool>> launchAuthUrl(String authUrl) async {
    return await _authService.launchAuthorizationUrl(authUrl);
  }

  /// OAuth 콜백 처리
  Future<Either<String, bool>> handleAuthCallback(String oauthVerifier) async {
    final result = await _authService.handleCallback(oauthVerifier);
    return result.fold(
      (error) => Left(error),
      (tokens) => Right(true),
    );
  }

  /// Garmin 연결 해제
  Future<void> disconnect() async {
    await _authService.clearTokens();
  }

  /// 특정 기간의 운동 데이터 가져오기
  Future<Either<String, List<WorkoutEntity>>> fetchWorkouts({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    if (!await isConnected()) {
      return Left('Garmin 연결이 필요합니다.');
    }

    try {
      // 날짜 형식: epoch seconds
      final startSeconds = startDate.millisecondsSinceEpoch ~/ 1000;
      final endSeconds = endDate.millisecondsSinceEpoch ~/ 1000;

      final result = await _apiClient.get(
        GarminConfig.activitiesEndpoint,
        queryParams: {
          'uploadStartTimeInSeconds': startSeconds.toString(),
          'uploadEndTimeInSeconds': endSeconds.toString(),
        },
      );

      return result.fold(
        (error) => Left(error),
        (data) {
          final activities = <WorkoutEntity>[];

          final activityList = data['data'] as List? ?? [];
          for (final activityJson in activityList) {
            final activity = GarminActivity.fromJson(activityJson);
            final workoutEntity = _mapToWorkoutEntity(activity, userId);
            if (workoutEntity != null) {
              activities.add(workoutEntity);
            }
          }

          AppLogger.info('Garmin', '${activities.length}개 운동 데이터 조회됨');
          return Right(activities);
        },
      );
    } catch (e) {
      return Left('Garmin 운동 데이터 가져오기 실패: ${e.toString()}');
    }
  }

  /// 최근 N일간의 운동 데이터 가져오기
  Future<Either<String, List<WorkoutEntity>>> fetchRecentWorkouts({
    int days = 7,
    required String userId,
  }) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    return fetchWorkouts(
      startDate: startDate,
      endDate: now,
      userId: userId,
    );
  }

  /// 오늘의 일일 요약 가져오기
  Future<Either<String, GarminDailySummary?>> fetchTodaySummary() async {
    if (!await isConnected()) {
      return Left('Garmin 연결이 필요합니다.');
    }

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final startSeconds = startOfDay.millisecondsSinceEpoch ~/ 1000;
      final endSeconds = today.millisecondsSinceEpoch ~/ 1000;

      final result = await _apiClient.get(
        GarminConfig.dailiesEndpoint,
        queryParams: {
          'uploadStartTimeInSeconds': startSeconds.toString(),
          'uploadEndTimeInSeconds': endSeconds.toString(),
        },
      );

      return result.fold(
        (error) => Left(error),
        (data) {
          final dailyList = data['data'] as List? ?? [];
          if (dailyList.isNotEmpty) {
            return Right(GarminDailySummary.fromJson(dailyList.first));
          }
          return Right(null);
        },
      );
    } catch (e) {
      return Left('일일 요약 가져오기 실패: ${e.toString()}');
    }
  }

  /// GarminActivity를 WorkoutEntity로 변환
  WorkoutEntity? _mapToWorkoutEntity(GarminActivity activity, String userId) {
    if (activity.startTime == null) return null;

    final workoutTypeString = GarminActivityType.mapToWorkoutType(
      activity.activityType ?? 'other',
    );
    final workoutType = WorkoutType.values.firstWhere(
      (e) => e.name == workoutTypeString,
      orElse: () => WorkoutType.other,
    );

    return WorkoutEntity(
      id: 'garmin_${activity.activityId ?? activity.startTime!.millisecondsSinceEpoch}',
      userId: userId,
      source: WorkoutSource.garmin,
      type: workoutType,
      startTime: activity.startTime!,
      endTime: activity.endTime ?? activity.startTime!.add(
        Duration(seconds: activity.durationInSeconds ?? 0),
      ),
      durationMinutes: activity.durationMinutes,
      distance: activity.distanceKm,
      calories: activity.activeKilocalories,
      averageHeartRate: activity.averageHeartRateInBeatsPerMinute,
      maxHeartRate: activity.maxHeartRateInBeatsPerMinute,
      steps: activity.steps,
      elevationGain: activity.elevationGainInMeters,
      calibratedWorkload: 0, // 캘리브레이션은 Mapper에서 처리
      calibratedScore: 0,
      createdAt: DateTime.now(),
    );
  }
}
