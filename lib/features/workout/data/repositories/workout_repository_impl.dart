import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';
import 'package:co_workfit/features/workout/data/datasources/health_kit_datasource.dart';
import 'package:co_workfit/features/workout/data/datasources/health_connect_datasource.dart';
import 'package:co_workfit/features/workout/data/datasources/health_data_mapper.dart';
import 'package:co_workfit/features/workout/data/datasources/garmin/garmin_datasource.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// WorkoutRepository 구현체
/// iOS에서는 HealthKit, Android에서는 Health Connect를 사용합니다.
/// Garmin은 iOS/Android 모두 Garmin Health API를 통해 직접 연동합니다.
class WorkoutRepositoryImpl implements WorkoutRepository {
  final HealthKitDataSource _healthKitDataSource;
  final HealthConnectDataSource _healthConnectDataSource;
  final GarminDataSource _garminDataSource;
  final HealthDataMapper _healthDataMapper;
  final String _userId; // TODO: AuthRepository에서 가져오도록 변경

  // SharedPreferences 키
  static const String _correctedDistancesKey = 'workout_corrected_distances';

  // 메모리 캐시 (앱 실행 중 빠른 접근용)
  Map<String, double>? _correctedDistancesCache;

  WorkoutRepositoryImpl({
    required HealthKitDataSource healthKitDataSource,
    required HealthConnectDataSource healthConnectDataSource,
    required GarminDataSource garminDataSource,
    required HealthDataMapper healthDataMapper,
    String userId = 'current_user', // 임시 기본값
  })  : _healthKitDataSource = healthKitDataSource,
        _healthConnectDataSource = healthConnectDataSource,
        _garminDataSource = garminDataSource,
        _healthDataMapper = healthDataMapper,
        _userId = userId;

  /// SharedPreferences에서 수정된 거리 정보 로드
  Future<Map<String, double>> _loadCorrectedDistances() async {
    if (_correctedDistancesCache != null) {
      return _correctedDistancesCache!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_correctedDistancesKey);
      
      if (jsonString != null) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        _correctedDistancesCache = decoded.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        AppLogger.debug('WorkoutRepo', '저장된 거리 수정 정보 로드: ${_correctedDistancesCache!.length}개');
      } else {
        _correctedDistancesCache = {};
      }
    } catch (e) {
      AppLogger.error('WorkoutRepo', '거리 수정 정보 로드 실패', e);
      _correctedDistancesCache = {};
    }

    return _correctedDistancesCache!;
  }

  /// SharedPreferences에 수정된 거리 정보 저장
  Future<void> _saveCorrectedDistances() async {
    if (_correctedDistancesCache == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_correctedDistancesCache);
      await prefs.setString(_correctedDistancesKey, jsonString);
      AppLogger.debug('WorkoutRepo', '거리 수정 정보 저장 완료: ${_correctedDistancesCache!.length}개');
    } catch (e) {
      AppLogger.error('WorkoutRepo', '거리 수정 정보 저장 실패', e);
    }
  }

  /// 현재 플랫폼이 iOS인지 확인
  bool get _isIOS => Platform.isIOS;

  /// 현재 플랫폼이 Android인지 확인
  bool get _isAndroid => Platform.isAndroid;

  @override
  Future<Either<String, bool>> requestHealthAuthorization() async {
    if (_isIOS) {
      AppLogger.info('WorkoutRepo', 'iOS - HealthKit 권한 요청');
      return await _healthKitDataSource.requestAuthorization();
    } else if (_isAndroid) {
      AppLogger.info('WorkoutRepo', 'Android - Health Connect 권한 요청');
      return await _healthConnectDataSource.requestAuthorization();
    } else {
      return Left('지원하지 않는 플랫폼입니다.');
    }
  }

  @override
  Future<bool> isHealthKitAvailable() async {
    if (_isIOS) {
      return await _healthKitDataSource.isHealthKitAvailable();
    } else if (_isAndroid) {
      return await _healthConnectDataSource.isHealthConnectAvailable();
    }
    return false;
  }

  @override
  Future<void> installHealthConnect() async {
    if (_isAndroid) {
      return await _healthConnectDataSource.installHealthConnect();
    } else {
      throw Exception('Health Connect는 Android에서만 사용 가능합니다.');
    }
  }

  @override
  Future<void> openHealthConnectSettings() async {
    if (_isAndroid) {
      return await _healthConnectDataSource.openHealthConnectSettings();
    } else {
      throw Exception('Health Connect는 Android에서만 사용 가능합니다.');
    }
  }

  // ========== Garmin 관련 메서드 ==========

  /// Garmin 연동 여부 확인
  Future<bool> isGarminConnected() async {
    return await _garminDataSource.isConnected();
  }

  /// Garmin 설정 완료 여부
  bool get isGarminConfigured => _garminDataSource.isConfigured;

  /// Garmin 인증 시작
  Future<Either<String, String>> startGarminAuth() async {
    return await _garminDataSource.startAuthentication();
  }

  /// Garmin 인증 URL 열기
  Future<Either<String, bool>> launchGarminAuthUrl(String authUrl) async {
    return await _garminDataSource.launchAuthUrl(authUrl);
  }

  /// Garmin OAuth 콜백 처리
  Future<Either<String, bool>> handleGarminCallback(String oauthVerifier) async {
    return await _garminDataSource.handleAuthCallback(oauthVerifier);
  }

  /// Garmin 연결 해제
  Future<void> disconnectGarmin() async {
    await _garminDataSource.disconnect();
  }

  // ========== 운동 데이터 조회 ==========

  @override
  Future<Either<String, List<WorkoutEntity>>> getWorkouts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final allWorkouts = <WorkoutEntity>[];
    String? platformError;

    // 1. 플랫폼별 기본 데이터 가져오기
    if (_isIOS) {
      final healthKitResult = await _getWorkoutsFromHealthKit(
        startDate: startDate,
        endDate: endDate,
      );
      healthKitResult.fold(
        (error) {
          AppLogger.error('WorkoutRepo', 'HealthKit 오류: $error');
          platformError = error;
        },
        (workouts) => allWorkouts.addAll(workouts),
      );
    } else if (_isAndroid) {
      final healthConnectResult = await _getWorkoutsFromHealthConnect(
        startDate: startDate,
        endDate: endDate,
      );
      healthConnectResult.fold(
        (error) {
          AppLogger.error('WorkoutRepo', 'Health Connect 오류: $error');
          platformError = error;
        },
        (workouts) => allWorkouts.addAll(workouts),
      );
    }

    // 플랫폼 데이터 가져오기에 실패한 경우, 권한 관련 에러면 즉시 반환
    if (platformError != null) {
      final errorLower = platformError!.toLowerCase();
      // 권한 관련 에러 감지
      if (errorLower.contains('permission') ||
          errorLower.contains('권한') ||
          errorLower.contains('authorized') ||
          errorLower.contains('access denied') ||
          errorLower.contains('not available')) {
        AppLogger.warning('WorkoutRepo', '권한 에러 감지 - 즉시 반환: $platformError');
        return Left(platformError!);
      }
      // 기타 에러는 계속 진행 (Garmin 등 다른 소스에서 데이터 가져올 수 있음)
    }

    // 2. Garmin 데이터 추가 (연결된 경우)
    if (await isGarminConnected()) {
      final garminResult = await _garminDataSource.fetchWorkouts(
        startDate: startDate,
        endDate: endDate,
        userId: _userId,
      );
      garminResult.fold(
        (error) => AppLogger.error('WorkoutRepo', 'Garmin 오류: $error'),
        (workouts) => allWorkouts.addAll(workouts),
      );
    }

    // 3. 수정된 거리 적용 (로컬 저장소에서 로드)
    final correctedDistances = await _loadCorrectedDistances();
    final workoutsWithCorrections = allWorkouts.map((workout) {
      final correctedDistance = correctedDistances[workout.id];
      if (correctedDistance != null) {
        return workout.copyWith(correctedDistance: correctedDistance);
      }
      return workout;
    }).toList();

    // 4. 시간순 정렬 (최신순)
    workoutsWithCorrections.sort((a, b) => b.startTime.compareTo(a.startTime));

    // 5. 모든 운동 데이터를 그대로 반환 (중복 제거 안 함)
    AppLogger.info('WorkoutRepo', '총 ${workoutsWithCorrections.length}개 운동 데이터 반환');

    return Right(workoutsWithCorrections);
  }

  /// HealthKit에서 운동 데이터 가져오기 (iOS)
  Future<Either<String, List<WorkoutEntity>>> _getWorkoutsFromHealthKit({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final healthDataResult = await _healthKitDataSource.fetchWorkoutData(
      startDate: startDate,
      endDate: endDate,
    );

    return healthDataResult.fold(
      (error) => Left(error),
      (healthPoints) async {
        final workouts = await _healthDataMapper.toWorkoutEntities(
          healthPoints: healthPoints,
          detailsFetcher: (start, end) async {
            final detailsResult =
                await _healthKitDataSource.fetchWorkoutDetails(
              workoutStart: start,
              workoutEnd: end,
            );

            return detailsResult.fold(
              (error) => <String, dynamic>{},
              (details) => details,
            );
          },
          userId: _userId,
          source: WorkoutSource.appleHealth,
        );

        return Right(workouts);
      },
    );
  }

  /// Health Connect에서 운동 데이터 가져오기 (Android)
  Future<Either<String, List<WorkoutEntity>>> _getWorkoutsFromHealthConnect({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final healthDataResult = await _healthConnectDataSource.fetchWorkoutDataWithSource(
      startDate: startDate,
      endDate: endDate,
    );

    return healthDataResult.fold(
      (error) => Left(error),
      (healthPointsWithSource) async {
        final workouts = await _healthDataMapper.toWorkoutEntitiesWithAutoSource(
          healthPointsWithSource: healthPointsWithSource,
          detailsFetcher: (start, end) async {
            final detailsResult =
                await _healthConnectDataSource.fetchWorkoutDetails(
              workoutStart: start,
              workoutEnd: end,
            );

            return detailsResult.fold(
              (error) => <String, dynamic>{},
              (details) => details,
            );
          },
          userId: _userId,
        );

        return Right(workouts);
      },
    );
  }

  @override
  Future<Either<String, List<WorkoutEntity>>> getTodayWorkouts() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return getWorkouts(startDate: startOfDay, endDate: now);
  }

  @override
  Future<Either<String, List<WorkoutEntity>>> getRecentWorkouts({
    int days = 7,
  }) async {
    AppLogger.info('WorkoutRepo', '최근 $days일 운동 데이터 요청');

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    final result = await getWorkouts(startDate: startDate, endDate: now);

    return result.fold(
      (error) {
        AppLogger.error('WorkoutRepo', '데이터 가져오기 실패: $error');
        return Left(error);
      },
      (workouts) {
        AppLogger.info('WorkoutRepo', '최종 운동 데이터: ${workouts.length}개');

        // 소스별 통계 로깅
        final sourceStats = <WorkoutSource, int>{};
        for (final workout in workouts) {
          sourceStats[workout.source] = (sourceStats[workout.source] ?? 0) + 1;
        }
        AppLogger.debug('WorkoutRepo', '소스별 데이터: $sourceStats');

        return Right(workouts);
      },
    );
  }

  /// 연결된 건강 데이터 소스 목록 가져오기
  Future<List<String>> getConnectedSources() async {
    final sources = <String>[];

    if (_isIOS) {
      sources.add('Apple Health');
    } else if (_isAndroid) {
      final healthConnectSources = await _healthConnectDataSource.getConnectedSources();
      sources.addAll(healthConnectSources);
    }

    if (await isGarminConnected()) {
      sources.add('Garmin Connect');
    }

    return sources;
  }

  @override
  Future<Either<String, bool>> saveWorkout(WorkoutEntity workout) async {
    // TODO: 로컬 데이터베이스(Hive/SQLite)에 저장 구현
    return Left('로컬 저장 기능 아직 미구현');
  }

  @override
  Future<Either<String, bool>> deleteWorkout(String workoutId) async {
    // TODO: 로컬 데이터베이스에서 삭제 구현
    return Left('삭제 기능 아직 미구현');
  }

  @override
  Future<Either<String, WorkoutEntity>> updateWorkoutDistance({
    required String workoutId,
    required double correctedDistance,
  }) async {
    try {
      AppLogger.info('WorkoutRepo', '운동 거리 수정: $workoutId -> ${correctedDistance}km');

      // 로컬 저장소에 수정된 거리 저장 (영구 저장)
      final correctedDistances = await _loadCorrectedDistances();
      correctedDistances[workoutId] = correctedDistance;
      _correctedDistancesCache = correctedDistances;
      await _saveCorrectedDistances();

      // 현재 운동 데이터 조회 (최근 30일)
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      final workoutsResult = await getWorkouts(
        startDate: startDate,
        endDate: now,
      );

      return workoutsResult.fold(
        (error) => Left('운동 데이터 조회 실패: $error'),
        (workouts) {
          // 수정한 운동 찾기
          final updatedWorkout = workouts.firstWhere(
            (w) => w.id == workoutId,
            orElse: () => throw Exception('운동 기록을 찾을 수 없습니다.'),
          );

          AppLogger.info('WorkoutRepo', '거리 수정 완료 (로컬 저장): ${updatedWorkout.effectiveDistance}km');
          return Right(updatedWorkout);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('WorkoutRepo', '거리 수정 실패', e, stackTrace);
      return Left('거리 수정 실패: $e');
    }
  }

  @override
  Future<Either<String, List<WorkoutEntity>>> getLocalWorkouts() async {
    // TODO: 로컬 데이터베이스에서 가져오기 구현
    return Left('로컬 조회 기능 아직 미구현');
  }

  @override
  Future<Either<String, bool>> syncWithServer() async {
    // TODO: 서버 동기화 구현
    return Left('서버 동기화 기능 아직 미구현');
  }
}
