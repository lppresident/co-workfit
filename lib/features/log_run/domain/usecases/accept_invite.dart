import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';

/// 챌린지 초대 수락 UseCase
class AcceptInvite implements UseCase<void, AcceptInviteParams> {
  final ChallengeRepository repository;

  AcceptInvite(this.repository);

  @override
  Future<Either<Failure, void>> call(AcceptInviteParams params) async {
    return await repository.acceptInvite(
      inviteId: params.inviteId,
      challengeId: params.challengeId,
      userId: params.userId,
      userNickname: params.userNickname,
    );
  }
}

class AcceptInviteParams {
  final String inviteId;
  final String challengeId;
  final String userId;
  final String userNickname;

  AcceptInviteParams({
    required this.inviteId,
    required this.challengeId,
    required this.userId,
    required this.userNickname,
  });
}
