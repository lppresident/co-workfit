import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/contribution_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_invite_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_archive_entity.dart';

/// 챌린지 BLoC 상태
abstract class ChallengeState extends Equatable {
  const ChallengeState();

  @override
  List<Object?> get props => [];
}

/// 초기 상태
class ChallengeInitial extends ChallengeState {
  const ChallengeInitial();
}

/// 로딩 중
class ChallengeLoading extends ChallengeState {
  const ChallengeLoading();
}

/// 챌린지 목록 로드 성공
/// 모든 챌린지를 하나의 리스트로 관리하고, 각 챌린지의 status로 구분
class ChallengesLoaded extends ChallengeState {
  final List<ChallengeEntity> challenges;
  final List<ChallengeInviteEntity> invites;

  const ChallengesLoaded({
    required this.challenges,
    this.invites = const [],
  });

  /// 활성 챌린지 필터
  List<ChallengeEntity> get activeChallenges =>
      challenges.where((c) => c.status == ChallengeStatus.active).toList();

  /// 완료된 챌린지 필터
  List<ChallengeEntity> get completedChallenges =>
      challenges.where((c) => c.status == ChallengeStatus.completed).toList();

  /// 만료된(실패) 챌린지 필터
  List<ChallengeEntity> get expiredChallenges =>
      challenges.where((c) => c.status == ChallengeStatus.expired).toList();

  @override
  List<Object?> get props => [challenges, invites];
}

/// 챌린지 상세 로드 성공 (목록 상태 유지)
class ChallengeDetailLoaded extends ChallengeState {
  final ChallengeEntity challenge;
  final List<ContributionEntity> contributions;
  final List<ChallengeEntity> challenges; // 목록 상태 유지

  const ChallengeDetailLoaded({
    required this.challenge,
    required this.contributions,
    this.challenges = const [],
  });

  @override
  List<Object?> get props => [challenge, contributions, challenges];
}

/// 챌린지 생성 성공
class ChallengeCreated extends ChallengeState {
  final ChallengeEntity challenge;

  const ChallengeCreated(this.challenge);

  @override
  List<Object?> get props => [challenge];
}

/// 챌린지 참가 성공
class ChallengeJoined extends ChallengeState {
  final String challengeId;

  const ChallengeJoined(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

/// 운동 기록 제출 성공
class WorkoutSubmitted extends ChallengeState {
  final ContributionEntity contribution;
  final ChallengeEntity challenge;
  final List<ChallengeEntity> challenges;

  const WorkoutSubmitted({
    required this.contribution,
    required this.challenge,
    this.challenges = const [],
  });

  @override
  List<Object?> get props => [contribution, challenge, challenges];
}

/// 챌린지 삭제 성공
class ChallengeDeleted extends ChallengeState {
  final String challengeId;

  const ChallengeDeleted(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

/// 챌린지 목표 수정 성공
class ChallengeTargetUpdated extends ChallengeState {
  final ChallengeEntity challenge;

  const ChallengeTargetUpdated(this.challenge);

  @override
  List<Object?> get props => [challenge];
}

/// 실시간 챌린지 업데이트
class ChallengeUpdated extends ChallengeState {
  final ChallengeEntity challenge;

  const ChallengeUpdated(this.challenge);

  @override
  List<Object?> get props => [challenge];
}

/// 실시간 기여 내역 업데이트
class ContributionsUpdated extends ChallengeState {
  final List<ContributionEntity> contributions;

  const ContributionsUpdated(this.contributions);

  @override
  List<Object?> get props => [contributions];
}

/// 에러 상태
class ChallengeError extends ChallengeState {
  final String message;

  const ChallengeError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 빈 상태 (챌린지 없음)
class ChallengeEmpty extends ChallengeState {
  const ChallengeEmpty();
}

/// 기여 기록 삭제 성공
class ContributionDeleted extends ChallengeState {
  final String contributionId;
  final String challengeId;

  const ContributionDeleted({
    required this.contributionId,
    required this.challengeId,
  });

  @override
  List<Object?> get props => [contributionId, challengeId];
}

/// 챌린지 초대 생성 성공
class ChallengeInvitesCreated extends ChallengeState {
  final int inviteCount;

  const ChallengeInvitesCreated(this.inviteCount);

  @override
  List<Object?> get props => [inviteCount];
}

/// 내가 받은 챌린지 초대 목록 로드 성공
class MyInvitesLoaded extends ChallengeState {
  final List<ChallengeInviteEntity> invites;

  const MyInvitesLoaded(this.invites);

  @override
  List<Object?> get props => [invites];
}

/// 실시간 챌린지 초대 목록 업데이트
class MyInvitesUpdated extends ChallengeState {
  final List<ChallengeInviteEntity> invites;
  final List<ChallengeEntity> challenges;

  const MyInvitesUpdated(this.invites, {this.challenges = const []});

  @override
  List<Object?> get props => [invites, challenges];
}

/// 챌린지 초대 수락 성공
class InviteAccepted extends ChallengeState {
  final String inviteId;
  final String challengeId;

  const InviteAccepted({
    required this.inviteId,
    required this.challengeId,
  });

  @override
  List<Object?> get props => [inviteId, challengeId];
}

/// 챌린지 초대 거절 성공
class InviteRejected extends ChallengeState {
  final String inviteId;

  const InviteRejected(this.inviteId);

  @override
  List<Object?> get props => [inviteId];
}

/// 챌린지 아카이브 로드 성공
class ChallengeArchivesLoaded extends ChallengeState {
  final List<ChallengeArchiveEntity> archives;
  final List<ChallengeEntity> challenges; // 현재 챌린지 목록 유지

  const ChallengeArchivesLoaded({
    required this.archives,
    this.challenges = const [],
  });

  @override
  List<Object?> get props => [archives, challenges];
}
