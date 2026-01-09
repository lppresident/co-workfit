import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_archive_entity.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';

/// 챌린지 아카이브 조회 UseCase
class GetChallengeArchives implements UseCase<List<ChallengeArchiveEntity>, String> {
  final ChallengeRepository repository;

  GetChallengeArchives(this.repository);

  @override
  Future<Either<Failure, List<ChallengeArchiveEntity>>> call(String userId) {
    return repository.getChallengeArchives(userId);
  }
}
