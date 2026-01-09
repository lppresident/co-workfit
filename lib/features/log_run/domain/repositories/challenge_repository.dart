import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/contribution_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_invite_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_archive_entity.dart';
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

  /// 챌린지 초대 생성 (친구에게 직접 초대)
  Future<Either<Failure, void>> createChallengeInvites({
    required String challengeId,
    required String challengeName,
    required String inviterId,
    required String inviterNickname,
    required List<String> inviteeIds,
    required double targetWeight,
    required DateTime startDate,
    required DateTime endDate,
    required int participantCount,
  });

  /// 내가 받은 챌린지 초대 목록 조회
  Future<Either<Failure, List<ChallengeInviteEntity>>> getMyInvites(
    String userId,
  );

  /// 내가 받은 챌린지 초대 실시간 스트림
  Stream<Either<Failure, List<ChallengeInviteEntity>>> watchMyInvites(
    String userId,
  );

  /// 특정 챌린지의 초대된 사용자 ID 목록 조회
  Future<Either<Failure, List<String>>> getChallengeInvitedUserIds(
    String challengeId,
  );

  /// 챌린지 초대 수락
  Future<Either<Failure, void>> acceptInvite({
    required String inviteId,
    required String userId,
    required String userNickname,
  });

  /// 챌린지 초대 거절
  Future<Either<Failure, void>> rejectInvite({
    required String inviteId,
  });

  /// 사용자의 만료된 챌린지를 모두 expired 상태로 변경하고 isSuccess 저장
  /// 정산 전에 호출하여 정산 시 올바른 isSuccess 값을 사용할 수 있도록 함
  Future<Either<Failure, int>> markExpiredChallenges(String userId);

  /// 사용자의 챌린지 아카이브 조회
  Future<Either<Failure, List<ChallengeArchiveEntity>>> getChallengeArchives(String userId);
}
