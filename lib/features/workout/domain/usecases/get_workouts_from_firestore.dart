import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';

/// Firestore에 등록된 운동 데이터만 조회하는 UseCase (Health 데이터 제외)
class GetWorkoutsFromFirestore implements UseCase<List<WorkoutEntity>, GetWorkoutsFromFirestoreParams> {
  final WorkoutRepository repository;

  GetWorkoutsFromFirestore(this.repository);

  @override
  Future<Either<Failure, List<WorkoutEntity>>> call(GetWorkoutsFromFirestoreParams params) async {
    final result = await repository.getWorkoutsFromFirestore(
      startDate: params.startDate,
      endDate: params.endDate,
    );

    return result.fold(
      (error) => Left(ServerFailure(error)),
      (workouts) => Right(workouts),
    );
  }
}

class GetWorkoutsFromFirestoreParams {
  final DateTime startDate;
  final DateTime endDate;

  GetWorkoutsFromFirestoreParams({
    required this.startDate,
    required this.endDate,
  });
}
