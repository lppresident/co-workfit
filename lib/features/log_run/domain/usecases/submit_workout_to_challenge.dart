import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_contribution_entity.dart';
import 'package:co_workfit/features/log_run/domain/repositories/log_run_repository.dart';

/// 운동 기록을 챌린지에 제출하는 UseCase
class SubmitWorkoutToChallenge implements UseCase<LogRunContributionEntity, SubmitWorkoutParams> {
  final LogRunRepository repository;

  SubmitWorkoutToChallenge(this.repository);

  @override
  Future<Either<Failure, LogRunContributionEntity>> call(SubmitWorkoutParams params) async {
    return await repository.submitWorkout(
      challengeId: params.challengeId,
      userId: params.userId,
      userName: params.userName,
      workoutId: params.workoutId,
      distance: params.distance,
      workoutType: params.workoutType,
      workoutDate: params.workoutDate,
    );
  }
}

class SubmitWorkoutParams {
  final String challengeId;
  final String userId;
  final String userName;
  final String workoutId;
  final double distance;
  final String workoutType;
  final DateTime workoutDate;

  SubmitWorkoutParams({
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.workoutId,
    required this.distance,
    required this.workoutType,
    required this.workoutDate,
  });
}
