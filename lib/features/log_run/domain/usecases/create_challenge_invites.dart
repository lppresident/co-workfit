import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/usecases/usecase.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';

/// 챌린지 초대 생성 UseCase
class CreateChallengeInvites implements UseCase<void, CreateChallengeInvitesParams> {
  final ChallengeRepository repository;

  CreateChallengeInvites(this.repository);

  @override
  Future<Either<Failure, void>> call(CreateChallengeInvitesParams params) async {
    return await repository.createChallengeInvites(
      challengeId: params.challengeId,
      challengeName: params.challengeName,
      inviterId: params.inviterId,
      inviterNickname: params.inviterNickname,
      inviteeIds: params.inviteeIds,
      targetWeight: params.targetWeight,
      startDate: params.startDate,
      endDate: params.endDate,
      participantCount: params.participantCount,
    );
  }
}

class CreateChallengeInvitesParams {
  final String challengeId;
  final String challengeName;
  final String inviterId;
  final String inviterNickname;
  final List<String> inviteeIds;
  final double targetWeight;
  final DateTime startDate;
  final DateTime endDate;
  final int participantCount;

  CreateChallengeInvitesParams({
    required this.challengeId,
    required this.challengeName,
    required this.inviterId,
    required this.inviterNickname,
    required this.inviteeIds,
    required this.targetWeight,
    required this.startDate,
    required this.endDate,
    required this.participantCount,
  });
}
