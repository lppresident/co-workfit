import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/entities/contribution_entity.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';

/// 챌린지 기여 내역 조회 UseCase
class GetChallengeContributions implements UseCase<List<ContributionEntity>, String> {
  final ChallengeRepository repository;

  GetChallengeContributions(this.repository);

  @override
  Future<Either<Failure, List<ContributionEntity>>> call(String challengeId) async {
    return await repository.getChallengeContributions(challengeId);
  }
}
