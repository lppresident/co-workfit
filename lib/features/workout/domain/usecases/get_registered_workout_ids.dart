import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';

/// 등록된 운동 ID 조회 파라미터
class GetRegisteredWorkoutIdsParams {
  final DateTime startDate;
  final DateTime endDate;

  const GetRegisteredWorkoutIdsParams({
    required this.startDate,
    required this.endDate,
  });
}

/// Firestore에 등록된 운동 ID 목록을 조회하는 UseCase
class GetRegisteredWorkoutIds
    implements UseCase<Set<String>, GetRegisteredWorkoutIdsParams> {
  final WorkoutRepository repository;

  GetRegisteredWorkoutIds(this.repository);

  @override
  Future<Either<Failure, Set<String>>> call(
    GetRegisteredWorkoutIdsParams params,
  ) async {
    final result = await repository.getRegisteredWorkoutIds(
      startDate: params.startDate,
      endDate: params.endDate,
    );

    return result.fold(
      (error) => Left(ServerFailure(error)),
      (workoutIds) => Right(workoutIds),
    );
  }
}


