import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';

/// 챌린지 초대 거절 UseCase
class RejectInvite implements UseCase<void, String> {
  final ChallengeRepository repository;

  RejectInvite(this.repository);

  @override
  Future<Either<Failure, void>> call(String inviteId) async {
    return await repository.rejectInvite(inviteId: inviteId);
  }
}
