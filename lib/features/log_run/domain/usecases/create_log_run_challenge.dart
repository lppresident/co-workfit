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
      userName: params.userName,
      targetWeight: params.targetWeight,
      recordTimeLimit: params.recordTimeLimit,
      allowFutureRecordsOnly: params.allowFutureRecordsOnly,
      expiresAt: params.expiresAt,
    );
  }
}

class CreateChallengeParams {
  final String userId;
  final String userName;
  final double targetWeight;
  final int? recordTimeLimit;
  final bool? allowFutureRecordsOnly;
  final DateTime? expiresAt;

  CreateChallengeParams({
    required this.userId,
    required this.userName,
    required this.targetWeight,
    this.recordTimeLimit,
    this.allowFutureRecordsOnly,
    this.expiresAt,
  });
}
