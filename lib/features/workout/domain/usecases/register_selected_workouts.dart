import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';

/// 선택된 운동만 Firestore에 등록하는 UseCase
class RegisterSelectedWorkouts implements UseCase<int, List<WorkoutEntity>> {
  final WorkoutRepository repository;

  RegisterSelectedWorkouts(this.repository);

  @override
  Future<Either<Failure, int>> call(List<WorkoutEntity> workouts) async {
    final result = await repository.registerSelectedWorkouts(workouts);

    return result.fold(
      (error) => Left(ServerFailure(error)),
      (count) => Right(count),
    );
  }
}
