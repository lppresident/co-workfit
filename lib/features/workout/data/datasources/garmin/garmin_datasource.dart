import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'garmin_config.dart';
import 'garmin_auth_service.dart';
import 'garmin_api_client.dart';
import 'garmin_sync_manager.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// Garmin Health API 데이터 소스
///
/// iOS와 Android 모두에서 동일하게 동작합니다.
/// Garmin Connect 계정을 통해 운동 데이터를 가져옵니다.
///
/// Rate Limit 최적화:
/// - 하루 최대 2회 자동 동기화
/// - 6시간 최소 간격
/// - 마지막 동기화 이후 데이터만 조회
/// - 수동 새로고침 5분 쿨다운
class GarminDataSource {
  final GarminAuthService _authService;
  final GarminApiClient _apiClient;
  final GarminSyncManager _syncManager;

  GarminDataSource({
    GarminAuthService? authService,
    GarminApiClient? apiClient,
    required GarminSyncManager syncManager,
  })  : _authService = authService ?? GarminAuthService(),
        _apiClient = apiClient ?? GarminApiClient(),
        _syncManager = syncManager;

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

  /// 자동 동기화 (Rate Limit 고려)
  ///
  /// - 하루 최대 2회
  /// - 6시간 최소 간격
  /// - 마지막 동기화 이후 데이터만
  Future<Either<String, List<WorkoutEntity>>> autoSync({
    required String userId,
  }) async {
    if (!await isConnected()) {
      return Left('Garmin 연결이 필요합니다.');
    }

    if (!_syncManager.canAutoSync()) {
      AppLogger.info('GarminDataSource', 'Auto sync skipped (rate limit)');
      _syncManager.logSyncStats();
      return Left('자동 동기화 제한 (다음 동기화: ${_syncManager.nextAutoSyncTime})');
    }

    AppLogger.info('GarminDataSource', '자동 동기화 시작');
    _syncManager.logSyncStats();

    final startDate = _syncManager.getSyncStartDate();
    final endDate = DateTime.now();

    final result = await _fetchWorkouts(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
    );

    return result.fold(
      (error) {
        _syncManager.recordSyncFailure(error);
        return Left(error);
      },
      (workouts) async {
        await _syncManager.recordSyncComplete();
        AppLogger.info('GarminDataSource', '자동 동기화 완료: ${workouts.length}개');
        return Right(workouts);
      },
    );
  }

  /// 수동 새로고침 (사용자 버튼 클릭)
  ///
  /// - 5분 쿨다운
  Future<Either<String, List<WorkoutEntity>>> manualRefresh({
    required String userId,
  }) async {
    if (!await isConnected()) {
      return Left('Garmin 연결이 필요합니다.');
    }

    if (!_syncManager.canManualSync()) {
      final nextSync = _syncManager.lastSyncTime
          ?.add(const Duration(minutes: 5));
      return Left('잠시 후 다시 시도해주세요 (다음 새로고침: $nextSync)');
    }

    AppLogger.info('GarminDataSource', '수동 새로고침 시작');

    final startDate = _syncManager.getSyncStartDate();
    final endDate = DateTime.now();

    final result = await _fetchWorkouts(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
    );

    return result.fold(
      (error) {
        _syncManager.recordSyncFailure(error);
        return Left(error);
      },
      (workouts) async {
        await _syncManager.recordSyncComplete();
        AppLogger.info('GarminDataSource', '수동 새로고침 완료: ${workouts.length}개');
        return Right(workouts);
      },
    );
  }

  /// 특정 기간의 운동 데이터 가져오기 (내부 메서드)
  Future<Either<String, List<WorkoutEntity>>> _fetchWorkouts({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    try {
      // 날짜 형식: epoch seconds
      final startSeconds = startDate.millisecondsSinceEpoch ~/ 1000;
      final endSeconds = endDate.millisecondsSinceEpoch ~/ 1000;

      AppLogger.debug(
        'GarminDataSource',
        'Fetching workouts: ${startDate.toString().substring(0, 10)} ~ ${endDate.toString().substring(0, 10)}',
      );

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

          AppLogger.info('GarminDataSource', '${activities.length}개 운동 데이터 조회됨');
          return Right(activities);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('GarminDataSource', 'Failed to fetch workouts', e, stackTrace);
      return Left('Garmin 운동 데이터 가져오기 실패: ${e.toString()}');
    }
  }

  /// 특정 기간의 운동 데이터 가져오기 (외부 호출용, Rate Limit 무시)
  Future<Either<String, List<WorkoutEntity>>> fetchWorkouts({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    if (!await isConnected()) {
      return Left('Garmin 연결이 필요합니다.');
    }

    return _fetchWorkouts(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
    );
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
