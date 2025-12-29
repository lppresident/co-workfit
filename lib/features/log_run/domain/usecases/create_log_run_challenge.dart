import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/repositories/log_run_repository.dart';

/// 통나무런 챌린지 생성 UseCase
class CreateLogRunChallenge implements UseCase<LogRunChallengeEntity, CreateChallengeParams> {
  final LogRunRepository repository;

  CreateLogRunChallenge(this.repository);

  @override
  Future<Either<Failure, LogRunChallengeEntity>> call(CreateChallengeParams params) async {
    return await repository.createChallenge(
      userId: params.userId,
      userNickname: params.userNickname,
      targetWeight: params.targetWeight,
      startDate: params.startDate,
      endDate: params.endDate,
      maxParticipants: params.maxParticipants,
    );
  }
}

class CreateChallengeParams {
  final String userId;
  final String userNickname;
  final double targetWeight;
  final DateTime startDate;
  final DateTime endDate;
  final int? maxParticipants;

  CreateChallengeParams({
    required this.userId,
    required this.userNickname,
    required this.targetWeight,
    required this.startDate,
    required this.endDate,
    this.maxParticipants,
  });
}
