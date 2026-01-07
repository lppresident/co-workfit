import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_invite_entity.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';

/// 내가 받은 챌린지 초대 조회 UseCase
class GetMyInvites implements UseCase<List<ChallengeInviteEntity>, String> {
  final ChallengeRepository repository;

  GetMyInvites(this.repository);

  @override
  Future<Either<Failure, List<ChallengeInviteEntity>>> call(String userId) async {
    return await repository.getMyInvites(userId);
  }
}
