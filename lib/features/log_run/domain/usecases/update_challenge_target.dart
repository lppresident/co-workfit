import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';
import 'package:equatable/equatable.dart';

/// 챌린지 목표 수정 UseCase
///
/// 방장만 목표를 수정할 수 있으며, 수정 시 진행률과 기여도가 자동으로 재계산됩니다.
class UpdateChallengeTarget implements UseCase<ChallengeEntity, UpdateChallengeTargetParams> {
  final ChallengeRepository repository;

  UpdateChallengeTarget(this.repository);

  @override
  Future<Either<Failure, ChallengeEntity>> call(UpdateChallengeTargetParams params) async {
    return await repository.updateChallengeTarget(
      challengeId: params.challengeId,
      userId: params.userId,
      newTargetWeight: params.newTargetWeight,
    );
  }
}

class UpdateChallengeTargetParams extends Equatable {
  final String challengeId;
  final String userId;
  final double newTargetWeight;

  const UpdateChallengeTargetParams({
    required this.challengeId,
    required this.userId,
    required this.newTargetWeight,
  });

  @override
  List<Object?> get props => [challengeId, userId, newTargetWeight];
}
