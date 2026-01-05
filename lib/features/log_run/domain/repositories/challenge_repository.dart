import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/contribution_entity.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

/// 챌린지 Repository 인터페이스
abstract class ChallengeRepository {
  /// 챌린지 생성
  Future<Either<Failure, ChallengeEntity>> createChallenge({
    required String userId,
    required String userNickname,
    required double targetWeight,
    required DateTime challengeDate,
    int? maxParticipants,
  });

  /// 챌린지 참가
  Future<Either<Failure, void>> joinChallenge({
    required String challengeId,
    required String userId,
    required String userNickname,
  });

  /// 챌린지 탈퇴
  Future<Either<Failure, void>> leaveChallenge({
    required String challengeId,
    required String userId,
  });

  /// 운동 기록 제출
  Future<Either<Failure, ContributionEntity>> submitWorkout({
    required String challengeId,
    required String userId,
    required String userNickname,
    required WorkoutEntity workout,
  });

  /// 모든 챌린지 목록 조회 (활성, 완료, 만료 모두 포함)
  Future<Either<Failure, List<ChallengeEntity>>> getAllChallenges(
    String userId,
  );

  /// 챌린지 상세 조회
  Future<Either<Failure, ChallengeEntity>> getChallengeById(
    String challengeId,
  );

  /// 초대 코드로 챌린지 조회
  Future<Either<Failure, ChallengeEntity>> getChallengeByInviteCode(
    String inviteCode,
  );

  /// 챌린지 기여 내역 조회
  Future<Either<Failure, List<ContributionEntity>>> getChallengeContributions(
    String challengeId,
  );

  /// 특정 사용자의 기여 내역 조회
  Future<Either<Failure, List<ContributionEntity>>> getUserContributions({
    required String challengeId,
    required String userId,
  });

  /// 챌린지 실시간 스트림
  Stream<Either<Failure, ChallengeEntity>> watchChallenge(
    String challengeId,
  );

  /// 기여 내역 실시간 스트림
  Stream<Either<Failure, List<ContributionEntity>>> watchContributions(
    String challengeId,
  );

  /// 챌린지 삭제 (방장만 가능)
  Future<Either<Failure, void>> deleteChallenge({
    required String challengeId,
    required String userId,
  });

  /// 기여 기록 삭제
  Future<Either<Failure, void>> deleteContribution({
    required String challengeId,
    required String contributionId,
    required String userId,
  });

  /// 특정 운동이 제출된 챌린지 목록 조회
  /// 운동 삭제 전 확인용
  Future<Either<Failure, List<String>>> getChallengesByWorkoutId(
    String workoutId,
  );
}
