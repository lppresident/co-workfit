import 'package:equatable/equatable.dart';

/// 통나무런 BLoC 이벤트
abstract class LogRunEvent extends Equatable {
  const LogRunEvent();

  @override
  List<Object?> get props => [];
}

/// 활성 챌린지 목록 로드
class LoadActiveChallenges extends LogRunEvent {
  final String userId;

  const LoadActiveChallenges(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 완료된 챌린지 목록 로드
class LoadCompletedChallenges extends LogRunEvent {
  final String userId;

  const LoadCompletedChallenges(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 챌린지 생성
class CreateChallenge extends LogRunEvent {
  final String userId;
  final String userNickname;
  final double targetWeight;
  final DateTime startDate;
  final DateTime endDate;
  final int? maxParticipants;

  const CreateChallenge({
    required this.userId,
    required this.userNickname,
    required this.targetWeight,
    required this.startDate,
    required this.endDate,
    this.maxParticipants,
  });

  @override
  List<Object?> get props => [
        userId,
        userNickname,
        targetWeight,
        startDate,
        endDate,
        maxParticipants,
      ];
}

/// 챌린지 참가
class JoinChallenge extends LogRunEvent {
  final String challengeId;
  final String userId;
  final String userNickname;

  const JoinChallenge({
    required this.challengeId,
    required this.userId,
    required this.userNickname,
  });

  @override
  List<Object?> get props => [challengeId, userId, userNickname];
}

/// 초대 코드로 챌린지 참가
class JoinChallengeByCode extends LogRunEvent {
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
class LeaveChallenge extends LogRunEvent {
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
class SubmitWorkout extends LogRunEvent {
  final String challengeId;
  final String userId;
  final String userNickname;
  final String workoutId;
  final double distance;
  final String workoutType;
  final DateTime workoutDate;

  const SubmitWorkout({
    required this.challengeId,
    required this.userId,
    required this.userNickname,
    required this.workoutId,
    required this.distance,
    required this.workoutType,
    required this.workoutDate,
  });

  @override
  List<Object?> get props => [
        challengeId,
        userId,
        userNickname,
        workoutId,
        distance,
        workoutType,
        workoutDate,
      ];
}

/// 챌린지 상세 조회
class LoadChallengeDetail extends LogRunEvent {
  final String challengeId;

  const LoadChallengeDetail(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

/// 챌린지 기여 내역 조회
class LoadChallengeContributions extends LogRunEvent {
  final String challengeId;

  const LoadChallengeContributions(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

/// 챌린지 실시간 구독 시작
class WatchChallenge extends LogRunEvent {
  final String challengeId;

  const WatchChallenge(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

/// 기여 내역 실시간 구독 시작
class WatchContributions extends LogRunEvent {
  final String challengeId;

  const WatchContributions(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

/// 챌린지 삭제
class DeleteChallenge extends LogRunEvent {
  final String challengeId;
  final String userId;

  const DeleteChallenge({
    required this.challengeId,
    required this.userId,
  });

  @override
  List<Object?> get props => [challengeId, userId];
}

/// 챌린지 새로고침
class RefreshChallenges extends LogRunEvent {
  final String userId;

  const RefreshChallenges(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 기여 기록 삭제
class DeleteContributionEvent extends LogRunEvent {
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
