import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';

/// 운동 데이터 가져오기 UseCase
class GetWorkouts {
  final WorkoutRepository repository;

  GetWorkouts(this.repository);

  /// 특정 기간의 운동 데이터 가져오기
  Future<Either<String, List<WorkoutEntity>>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await repository.getWorkouts(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// 오늘의 운동 데이터 가져오기 UseCase
class GetTodayWorkouts {
  final WorkoutRepository repository;

  GetTodayWorkouts(this.repository);

  Future<Either<String, List<WorkoutEntity>>> call() async {
    return await repository.getTodayWorkouts();
  }
}

/// 최근 N일간의 운동 데이터 가져오기 UseCase
class GetRecentWorkouts {
  final WorkoutRepository repository;

  GetRecentWorkouts(this.repository);

  Future<Either<String, List<WorkoutEntity>>> call({int days = 7}) async {
    return await repository.getRecentWorkouts(days: days);
  }
}
