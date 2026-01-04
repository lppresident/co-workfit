import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_contribution_entity.dart';
import 'package:co_workfit/features/log_run/domain/repositories/log_run_repository.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

/// 운동 기록을 챌린지에 제출하는 UseCase
class SubmitWorkoutToChallenge implements UseCase<LogRunContributionEntity, SubmitWorkoutParams> {
  final LogRunRepository repository;

  SubmitWorkoutToChallenge(this.repository);

  @override
  Future<Either<Failure, LogRunContributionEntity>> call(SubmitWorkoutParams params) async {
    return await repository.submitWorkout(
      challengeId: params.challengeId,
      userId: params.userId,
      userNickname: params.userNickname,
      workout: params.workout,
    );
  }
}

class SubmitWorkoutParams {
  final String challengeId;
  final String userId;
  final String userNickname;
  final WorkoutEntity workout;

  SubmitWorkoutParams({
    required this.challengeId,
    required this.userId,
    required this.userNickname,
    required this.workout,
  });
}
