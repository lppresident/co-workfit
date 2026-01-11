import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:equatable/equatable.dart';

/// 챌린지 BLoC 이벤트
abstract class ChallengeEvent extends Equatable {
  const ChallengeEvent();

  @override
  List<Object?> get props => [];
}

/// 챌린지 목록 로드 (활성, 완료, 만료 모두 포함)
class LoadChallenges extends ChallengeEvent {
  final String userId;

  const LoadChallenges(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 챌린지 생성
class CreateChallengeEvent extends ChallengeEvent {
  final String userId;
  final String userNickname;
  final double targetWeight;
  final DateTime challengeDate;
  final int? maxParticipants;

  const CreateChallengeEvent({
    required this.userId,
    required this.userNickname,
    required this.targetWeight,
    required this.challengeDate,
    this.maxParticipants,
  });

  @override
  List<Object?> get props => [
        userId,
        userNickname,
        targetWeight,
        challengeDate,
        maxParticipants,
      ];
}

/// 챌린지 참가
class JoinChallengeEvent extends ChallengeEvent {
  final String challengeId;
  final String userId;
  final String userNickname;

  const JoinChallengeEvent({
    required this.challengeId,
    required this.userId,
    required this.userNickname,
  });

  @override
  List<Object?> get props => [challengeId, userId, userNickname];
}

/// 초대 코드로 챌린지 참가
class JoinChallengeByCode extends ChallengeEvent {
  final String inviteCode;
  final String userId;
  final String userNickname;

  const JoinChallengeByCode({
    required this.inviteCode,
    required this.userId,
    required this.userNickname,
  });

  @override
  List<Object?> get props => [inviteCode, userId, userNickname];
}

/// 챌린지 탈퇴
class LeaveChallenge extends ChallengeEvent {
  final String challengeId;
  final String userId;

  const LeaveChallenge({
    required this.challengeId,
    required this.userId,
  });

  @override
  List<Object?> get props => [challengeId, userId];
}

/// 운동 기록 제출
class SubmitWorkout extends ChallengeEvent {
  final String challengeId;
  final String userId;
  final String userNickname;
  final WorkoutEntity workout;

  const SubmitWorkout({
    required this.challengeId,
    required this.userId,
    required this.userNickname,
    required this.workout,
  });

  @override
  List<Object?> get props => [
        challengeId,
        userId,
        userNickname,
        workout,
      ];
}

/// 챌린지 상세 조회
class LoadChallengeDetail extends ChallengeEvent {
  final String challengeId;

  const LoadChallengeDetail(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

/// 챌린지 기여 내역 조회
class LoadChallengeContributions extends ChallengeEvent {
  final String challengeId;

  const LoadChallengeContributions(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

/// 챌린지 실시간 구독 시작
class WatchChallenge extends ChallengeEvent {
  final String challengeId;

  const WatchChallenge(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

/// 기여 내역 실시간 구독 시작
class WatchContributions extends ChallengeEvent {
  final String challengeId;

  const WatchContributions(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

/// 챌린지 삭제
class DeleteChallenge extends ChallengeEvent {
  final String challengeId;
  final String userId;

  const DeleteChallenge({
    required this.challengeId,
    required this.userId,
  });

  @override
  List<Object?> get props => [challengeId, userId];
}

/// 챌린지 목표 수정 (방장만 가능)
class UpdateChallengeTarget extends ChallengeEvent {
  final String challengeId;
  final String userId;
  final double newTargetWeight;

  const UpdateChallengeTarget({
    required this.challengeId,
    required this.userId,
    required this.newTargetWeight,
  });

  @override
  List<Object?> get props => [challengeId, userId, newTargetWeight];
}

/// 기여 기록 삭제
class DeleteContributionEvent extends ChallengeEvent {
  final String challengeId;
  final String contributionId;
  final String userId;

  const DeleteContributionEvent({
    required this.challengeId,
    required this.contributionId,
    required this.userId,
  });

  @override
  List<Object?> get props => [challengeId, contributionId, userId];
}

/// 챌린지 초대 생성 (친구에게 직접 초대)
class CreateChallengeInvites extends ChallengeEvent {
  final String challengeId;
  final String challengeName;
  final String inviterId;
  final String inviterNickname;
  final List<String> inviteeIds;
  final double targetWeight;
  final DateTime startDate;
  final DateTime endDate;
  final int participantCount;

  const CreateChallengeInvites({
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

  @override
  List<Object?> get props => [
        challengeId,
        challengeName,
        inviterId,
        inviterNickname,
        inviteeIds,
        targetWeight,
        startDate,
        endDate,
        participantCount,
      ];
}

/// 내가 받은 챌린지 초대 목록 로드
class LoadMyInvites extends ChallengeEvent {
  final String userId;

  const LoadMyInvites(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 내가 받은 챌린지 초대 실시간 구독
class WatchMyInvites extends ChallengeEvent {
  final String userId;

  const WatchMyInvites(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 챌린지 초대 수락
class AcceptInviteEvent extends ChallengeEvent {
  final String inviteId;
  final String challengeId;
  final String userId;
  final String userNickname;

  const AcceptInviteEvent({
    required this.inviteId,
    required this.challengeId,
    required this.userId,
    required this.userNickname,
  });

  @override
  List<Object?> get props => [inviteId, challengeId, userId, userNickname];
}

/// 챌린지 초대 거절
class RejectInviteEvent extends ChallengeEvent {
  final String inviteId;
  final String challengeId;

  const RejectInviteEvent({
    required this.inviteId,
    required this.challengeId,
  });

  @override
  List<Object?> get props => [inviteId, challengeId];
}

/// 챌린지 아카이브 조회
class LoadChallengeArchives extends ChallengeEvent {
  final String userId;

  const LoadChallengeArchives(this.userId);

  @override
  List<Object?> get props => [userId];
}
