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
  final String userName;
  final double targetWeight;
  final int? recordTimeLimit;
  final bool? allowFutureRecordsOnly;
  final DateTime? expiresAt;

  const CreateChallenge({
    required this.userId,
    required this.userName,
    required this.targetWeight,
    this.recordTimeLimit,
    this.allowFutureRecordsOnly,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [
        userId,
        userName,
        targetWeight,
        recordTimeLimit,
        allowFutureRecordsOnly,
        expiresAt,
      ];
}

/// 챌린지 참가
class JoinChallenge extends LogRunEvent {
  final String challengeId;
  final String userId;
  final String userName;

  const JoinChallenge({
    required this.challengeId,
    required this.userId,
    required this.userName,
  });

  @override
  List<Object?> get props => [challengeId, userId, userName];
}

/// 초대 코드로 챌린지 참가
class JoinChallengeByCode extends LogRunEvent {
  final String inviteCode;
  final String userId;
  final String userName;

  const JoinChallengeByCode({
    required this.inviteCode,
    required this.userId,
    required this.userName,
  });

  @override
  List<Object?> get props => [inviteCode, userId, userName];
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
  final String userName;
  final String workoutId;
  final double distance;
  final String workoutType;
  final DateTime workoutDate;

  const SubmitWorkout({
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.workoutId,
    required this.distance,
    required this.workoutType,
    required this.workoutDate,
  });

  @override
  List<Object?> get props => [
        challengeId,
        userId,
        userName,
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
