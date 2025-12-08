import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';
import 'package:co_workfit/features/workout/data/datasources/health_kit_datasource.dart';
import 'package:co_workfit/features/workout/data/datasources/health_data_mapper.dart';

/// WorkoutRepository 구현체
class WorkoutRepositoryImpl implements WorkoutRepository {
  final HealthKitDataSource _healthKitDataSource;
  final HealthDataMapper _healthDataMapper;
  final String _userId; // TODO: AuthRepository에서 가져오도록 변경

  WorkoutRepositoryImpl({
    required HealthKitDataSource healthKitDataSource,
    required HealthDataMapper healthDataMapper,
    String userId = 'current_user', // 임시 기본값
  })  : _healthKitDataSource = healthKitDataSource,
        _healthDataMapper = healthDataMapper,
        _userId = userId;

  @override
  Future<Either<String, bool>> requestHealthAuthorization() async {
    return await _healthKitDataSource.requestAuthorization();
  }

  @override
  Future<bool> isHealthKitAvailable() async {
    return await _healthKitDataSource.isHealthKitAvailable();
  }

  @override
  Future<Either<String, List<WorkoutEntity>>> getWorkouts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // HealthKit에서 데이터 가져오기
    final healthDataResult = await _healthKitDataSource.fetchWorkoutData(
      startDate: startDate,
      endDate: endDate,
    );

    return healthDataResult.fold(
      (error) => Left(error),
      (healthPoints) async {
        // HealthDataPoint를 WorkoutEntity로 변환
        final workouts = await _healthDataMapper.toWorkoutEntities(
          healthPoints: healthPoints,
          detailsFetcher: (start, end) async {
            final detailsResult =
                await _healthKitDataSource.fetchWorkoutDetails(
              workoutStart: start,
              workoutEnd: end,
            );

            return detailsResult.fold(
              (error) => <String, dynamic>{}, // 에러시 빈 맵 반환
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
    final healthDataResult = await _healthKitDataSource.fetchTodayWorkouts();

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
        );

        return Right(workouts);
      },
    );
  }

  @override
  Future<Either<String, List<WorkoutEntity>>> getRecentWorkouts({
    int days = 7,
  }) async {
    final healthDataResult = await _healthKitDataSource.fetchRecentWorkouts(
      days: days,
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
        );

        return Right(workouts);
      },
    );
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
