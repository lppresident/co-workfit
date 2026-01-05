import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';

/// Firestore + Health 병합 운동 데이터 조회 UseCase
class GetMergedWorkouts implements UseCase<List<WorkoutEntity>, GetMergedWorkoutsParams> {
  final WorkoutRepository repository;

  GetMergedWorkouts(this.repository);

  @override
  Future<Either<Failure, List<WorkoutEntity>>> call(GetMergedWorkoutsParams params) async {
    final result = await repository.getMergedWorkouts(
      startDate: params.startDate,
      endDate: params.endDate,
    );

    return result.fold(
      (error) => Left(ServerFailure(error)),
      (workouts) => Right(workouts),
    );
  }
}

class GetMergedWorkoutsParams {
  final DateTime startDate;
  final DateTime endDate;

  GetMergedWorkoutsParams({
    required this.startDate,
    required this.endDate,
  });
}
