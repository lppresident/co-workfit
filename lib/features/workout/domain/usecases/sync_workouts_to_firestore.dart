import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';

/// Firestore에 운동 데이터 동기화 UseCase
class SyncWorkoutsToFirestore implements UseCase<int, SyncWorkoutsParams> {
  final WorkoutRepository repository;

  SyncWorkoutsToFirestore(this.repository);

  @override
  Future<Either<Failure, int>> call(SyncWorkoutsParams params) async {
    final result = await repository.syncWorkoutsToFirestore(
      startDate: params.startDate,
      endDate: params.endDate,
    );

    return result.fold(
      (error) => Left(ServerFailure(error)),
      (count) => Right(count),
    );
  }
}

class SyncWorkoutsParams {
  final DateTime startDate;
  final DateTime endDate;

  SyncWorkoutsParams({
    required this.startDate,
    required this.endDate,
  });
}
