import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/repositories/log_run_repository.dart';

/// 기여 기록 삭제 UseCase
class DeleteContribution implements UseCase<void, DeleteContributionParams> {
  final LogRunRepository repository;

  DeleteContribution(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteContributionParams params) async {
    return await repository.deleteContribution(
      challengeId: params.challengeId,
      contributionId: params.contributionId,
      userId: params.userId,
    );
  }
}

class DeleteContributionParams {
  final String challengeId;
  final String contributionId;
  final String userId;

  DeleteContributionParams({
    required this.challengeId,
    required this.contributionId,
    required this.userId,
  });
}
