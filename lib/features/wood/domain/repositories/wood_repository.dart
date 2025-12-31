import 'package:co_workfit/features/log_run/domain/entities/workout_type.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_summary_entity.dart';

/// 통나무 재화 Repository 인터페이스
abstract class WoodRepository {
  // ========== Summary ==========

  /// 사용자의 통나무 보유 현황 조회
  Future<WoodSummaryEntity> getWoodSummary(String userId);

  /// 통나무 보유 현황 업데이트
  Future<void> updateWoodSummary(String userId, WoodSummaryEntity summary);

  /// 통나무 추가 (정산 시)
  Future<void> addWood(String userId, int amount, String settlementDate);

  /// 통나무 사용 (제작 시)
  Future<void> useWood(String userId, int amount);

  // ========== Iron (쇠) ==========

  /// 쇠 추가 (정산 시)
  Future<void> addIron(String userId, int amount, String settlementDate);

  /// 쇠 사용 (제작 시)
  Future<void> useIron(String userId, int amount);

  // ========== Settlement ==========

  /// 정산 기록 저장
  Future<void> saveSettlement(String userId, WoodSettlementEntity settlement);

  /// 특정 날짜의 정산 기록 조회
  Future<WoodSettlementEntity?> getSettlement(String userId, String date);

  /// 정산 기록 목록 조회 (최근 7일)
  Future<List<WoodSettlementEntity>> getSettlements(
    String userId, {
    int limit = 7,
  });

  /// 미정산 날짜 목록 조회 (마지막 정산일 이후 ~ 어제)
  Future<List<String>> getPendingSettlementDates(String userId);

  /// 7일 이상 지난 정산 기록 삭제
  Future<void> deleteOldSettlements(String userId);

  // ========== Challenge Data ==========

  /// 특정 날짜에 종료된 챌린지 목록 조회
  Future<List<ChallengeSettlementData>> getChallengesEndedOn(
    String userId,
    String date,
  );

  /// 사용자의 챌린지 기여 정보 조회
  Future<UserChallengeContribution> getUserContribution(
    String userId,
    String challengeId,
  );

  /// 해당 날짜가 사용자의 첫 운동인지 확인
  Future<bool> isFirstWorkoutOfDay(String userId, DateTime date);

  /// 해당 챌린지에서 사용자의 첫 기여인지 확인
  Future<bool> isFirstContribution(String userId, String challengeId);

  // ========== Solo Workout Data ==========

  /// 특정 날짜의 개인 운동 기록 조회 (달리기/걷기)
  Future<SoloWorkoutData?> getRunningWorkoutsOnDate(String userId, String date);

  /// 특정 날짜의 개인 운동 기록 조회 (헬스)
  Future<SoloWorkoutData?> getStrengthWorkoutsOnDate(String userId, String date);
}

/// 개인 운동 데이터 (챌린지 없이 운동한 기록)
class SoloWorkoutData {
  /// 총 거리 (km) - 달리기용
  final double totalDistance;

  /// 총 점수 - 헬스용
  final double totalScore;

  /// 운동 횟수
  final int workoutCount;

  /// 운동 날짜
  final String date;

  const SoloWorkoutData({
    this.totalDistance = 0,
    this.totalScore = 0,
    required this.workoutCount,
    required this.date,
  });

  bool get hasRunningData => totalDistance > 0;
  bool get hasStrengthData => totalScore > 0;
}

/// 정산용 챌린지 데이터
class ChallengeSettlementData {
  /// 챌린지 ID
  final String challengeId;

  /// 챌린지 이름 (목표 거리/점수 기반)
  final String challengeName;

  /// 챌린지 운동 타입
  final ChallengeType challengeType;

  /// 목표 거리 (km) 또는 목표 점수
  final double targetDistance;

  /// 달성 거리 (km) 또는 달성 점수
  final double achievedDistance;

  /// 성공 여부
  final bool isSuccess;

  /// 종료일
  final DateTime endDate;

  /// 참가자 수
  final int participantCount;

  /// 참가자별 기여 거리/점수
  final Map<String, double> participantContributions;

  /// 사용자의 기여 거리/점수
  final double userContribution;

  /// 사용자가 MVP인지 (기여도 1위)
  final bool isUserMvp;

  /// 사용자의 운동 거리/점수 합계 (개인 운동 보상용)
  final double userTotalWorkoutDistance;

  /// 사용자의 첫 기여 여부
  final bool isFirstContribution;

  /// 달리기 챌린지인지 확인
  bool get isRunning => challengeType == ChallengeType.running;

  /// 헬스 챌린지인지 확인
  bool get isStrengthTraining => challengeType == ChallengeType.strengthTraining;

  const ChallengeSettlementData({
    required this.challengeId,
    required this.challengeName,
    this.challengeType = ChallengeType.running,
    required this.targetDistance,
    required this.achievedDistance,
    required this.isSuccess,
    required this.endDate,
    required this.participantCount,
    required this.participantContributions,
    required this.userContribution,
    required this.isUserMvp,
    required this.userTotalWorkoutDistance,
    required this.isFirstContribution,
  });
}

/// 사용자의 챌린지 기여 정보
class UserChallengeContribution {
  /// 총 기여 거리 (km)
  final double totalDistance;

  /// 기여 횟수
  final int contributionCount;

  /// 첫 기여 여부
  final bool isFirst;

  const UserChallengeContribution({
    required this.totalDistance,
    required this.contributionCount,
    required this.isFirst,
  });
}

