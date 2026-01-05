import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';

/// 모든 챌린지 목록 조회 UseCase (활성, 완료, 만료 모두 포함)
class GetAllChallenges implements UseCase<List<ChallengeEntity>, String> {
  final ChallengeRepository repository;

  GetAllChallenges(this.repository);

  @override
  Future<Either<Failure, List<ChallengeEntity>>> call(String userId) async {
    return await repository.getAllChallenges(userId);
  }
}
