import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_contribution_entity.dart';

/// 통나무런 BLoC 상태
abstract class LogRunState extends Equatable {
  const LogRunState();

  @override
  List<Object?> get props => [];
}

/// 초기 상태
class LogRunInitial extends LogRunState {
  const LogRunInitial();
}

/// 로딩 중
class LogRunLoading extends LogRunState {
  const LogRunLoading();
}

/// 챌린지 목록 로드 성공
class ChallengesLoaded extends LogRunState {
  final List<LogRunChallengeEntity> activeChallenges;
  final List<LogRunChallengeEntity> completedChallenges;

  const ChallengesLoaded({
    required this.activeChallenges,
    required this.completedChallenges,
  });

  @override
  List<Object?> get props => [activeChallenges, completedChallenges];
}

/// 챌린지 상세 로드 성공 (목록 상태 유지)
class ChallengeDetailLoaded extends LogRunState {
  final LogRunChallengeEntity challenge;
  final List<LogRunContributionEntity> contributions;
  // 목록 상태도 함께 유지
  final List<LogRunChallengeEntity> activeChallenges;
  final List<LogRunChallengeEntity> completedChallenges;

  const ChallengeDetailLoaded({
    required this.challenge,
    required this.contributions,
    this.activeChallenges = const [],
    this.completedChallenges = const [],
  });

  @override
  List<Object?> get props => [challenge, contributions, activeChallenges, completedChallenges];
}

/// 챌린지 생성 성공
class ChallengeCreated extends LogRunState {
  final LogRunChallengeEntity challenge;

  const ChallengeCreated(this.challenge);

  @override
  List<Object?> get props => [challenge];
}

/// 챌린지 참가 성공
class ChallengeJoined extends LogRunState {
  final String challengeId;

  const ChallengeJoined(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

/// 운동 기록 제출 성공
class WorkoutSubmitted extends LogRunState {
  final LogRunContributionEntity contribution;

  const WorkoutSubmitted(this.contribution);

  @override
  List<Object?> get props => [contribution];
}

/// 챌린지 삭제 성공
class ChallengeDeleted extends LogRunState {
  final String challengeId;

  const ChallengeDeleted(this.challengeId);

  @override
  List<Object?> get props => [challengeId];
}

/// 실시간 챌린지 업데이트
class ChallengeUpdated extends LogRunState {
  final LogRunChallengeEntity challenge;

  const ChallengeUpdated(this.challenge);

  @override
  List<Object?> get props => [challenge];
}

/// 실시간 기여 내역 업데이트
class ContributionsUpdated extends LogRunState {
  final List<LogRunContributionEntity> contributions;

  const ContributionsUpdated(this.contributions);

  @override
  List<Object?> get props => [contributions];
}

/// 에러 상태
class LogRunError extends LogRunState {
  final String message;

  const LogRunError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 빈 상태 (챌린지 없음)
class LogRunEmpty extends LogRunState {
  const LogRunEmpty();
}
