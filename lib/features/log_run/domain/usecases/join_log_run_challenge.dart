import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/repositories/log_run_repository.dart';

/// 챌린지 참가 UseCase
class JoinLogRunChallenge implements UseCase<void, JoinChallengeParams> {
  final LogRunRepository repository;

  JoinLogRunChallenge(this.repository);

  @override
  Future<Either<Failure, void>> call(JoinChallengeParams params) async {
    return await repository.joinChallenge(
      challengeId: params.challengeId,
      userId: params.userId,
      userNickname: params.userNickname,
    );
  }
}

class JoinChallengeParams {
  final String challengeId;
  final String userId;
  final String userNickname;

  JoinChallengeParams({
    required this.challengeId,
    required this.userId,
    required this.userNickname,
  });
}
