import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';

/// 챌린지 생성 UseCase
class CreateChallenge implements UseCase<ChallengeEntity, CreateChallengeParams> {
  final ChallengeRepository repository;

  CreateChallenge(this.repository);

  @override
  Future<Either<Failure, ChallengeEntity>> call(CreateChallengeParams params) async {
    return await repository.createChallenge(
      userId: params.userId,
      userNickname: params.userNickname,
      targetWeight: params.targetWeight,
      challengeDate: params.challengeDate,
      maxParticipants: params.maxParticipants,
    );
  }
}

class CreateChallengeParams {
  final String userId;
  final String userNickname;
  final double targetWeight;
  final DateTime challengeDate;
  final int? maxParticipants;

  CreateChallengeParams({
    required this.userId,
    required this.userNickname,
    required this.targetWeight,
    required this.challengeDate,
    this.maxParticipants,
  });
}
