import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/repositories/log_run_repository.dart';
import 'package:co_workfit/features/log_run/domain/utils/invite_code_generator.dart';

/// 초대 코드로 통나무런 챌린지 참가 UseCase
///
/// 1. 초대 코드 검증
/// 2. 코드로 챌린지 조회
/// 3. 챌린지 참가
class JoinChallengeByInviteCode
    implements UseCase<LogRunChallengeEntity, JoinByCodeParams> {
  final LogRunRepository repository;

  JoinChallengeByInviteCode(this.repository);

  @override
  Future<Either<Failure, LogRunChallengeEntity>> call(
      JoinByCodeParams params) async {
    // 1. 초대 코드 검증
    final normalizedCode = InviteCodeGenerator.normalize(params.inviteCode);
    if (!InviteCodeGenerator.isValid(normalizedCode)) {
      return Left(ValidationFailure('초대 코드 형식이 올바르지 않습니다'));
    }

    // 2. 초대 코드로 챌린지 조회
    final challengeResult =
        await repository.getChallengeByInviteCode(normalizedCode);

    return challengeResult.fold(
      (failure) => Left(failure),
      (challenge) async {
        // 3. 챌린지 유효성 검증
        if (challenge.isExpired) {
          return Left(ValidationFailure('만료된 챌린지입니다'));
        }

        if (challenge.isFull) {
          return Left(ValidationFailure('참가 인원이 가득 찼습니다'));
        }

        if (challenge.participants.contains(params.userId)) {
          return Left(ValidationFailure('이미 참가 중인 챌린지입니다'));
        }

        // 4. 챌린지 참가
        final joinResult = await repository.joinChallenge(
          challengeId: challenge.id,
          userId: params.userId,
          userName: params.userName,
        );

        return joinResult.fold(
          (failure) => Left(failure),
          (_) => Right(challenge),
        );
      },
    );
  }
}

class JoinByCodeParams {
  final String inviteCode;
  final String userId;
  final String userName;

  JoinByCodeParams({
    required this.inviteCode,
    required this.userId,
    required this.userName,
  });
}
