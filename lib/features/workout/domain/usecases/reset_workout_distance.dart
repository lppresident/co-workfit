import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';

/// 운동 거리 초기화 UseCase (원래 값으로 되돌리기)
class ResetWorkoutDistance extends UseCase<WorkoutEntity, ResetWorkoutDistanceParams> {
  final WorkoutRepository repository;

  ResetWorkoutDistance(this.repository);

  @override
  Future<Either<Failure, WorkoutEntity>> call(ResetWorkoutDistanceParams params) async {
    final result = await repository.resetWorkoutDistance(
      workoutId: params.workoutId,
    );

    return result.fold(
      (error) => Left(ServerFailure(error)),
      (workout) => Right(workout),
    );
  }
}

/// ResetWorkoutDistance 파라미터
class ResetWorkoutDistanceParams {
  final String workoutId;

  const ResetWorkoutDistanceParams({
    required this.workoutId,
  });
}

