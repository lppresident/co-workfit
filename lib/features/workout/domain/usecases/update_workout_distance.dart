import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';

/// 운동 거리 수정 UseCase
class UpdateWorkoutDistance extends UseCase<WorkoutEntity, UpdateWorkoutDistanceParams> {
  final WorkoutRepository repository;

  UpdateWorkoutDistance(this.repository);

  @override
  Future<Either<Failure, WorkoutEntity>> call(UpdateWorkoutDistanceParams params) async {
    final result = await repository.updateWorkoutDistance(
      workoutId: params.workoutId,
      correctedDistance: params.correctedDistance,
    );

    return result.fold(
      (error) => Left(ServerFailure(error)),
      (workout) => Right(workout),
    );
  }
}

/// UpdateWorkoutDistance 파라미터
class UpdateWorkoutDistanceParams {
  final String workoutId;
  final double correctedDistance;

  const UpdateWorkoutDistanceParams({
    required this.workoutId,
    required this.correctedDistance,
  });
}
