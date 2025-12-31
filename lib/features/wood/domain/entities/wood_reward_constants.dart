/// 통나무 보상 상수 정의
///
/// 이슈 #68 기반 보상 체계
abstract class WoodRewardConstants {
  // ========== 개인 운동 보상 ==========

  /// 기본 보상 (운동 완료 시)
  static const int personalBase = 5;

  /// 거리당 보상 (km당)
  static const double personalPerKm = 2.0;

  /// 일일 첫 운동 보너스
  static const int dailyFirstWorkoutBonus = 3;

  // ========== 챌린지 기여 보상 ==========

  /// 기여 거리당 보상 (km당)
  static const double contributionPerKm = 1.0;

  /// 챌린지 첫 기여 보너스
  static const int firstContributionBonus = 5;

  // ========== 챌린지 성공 보상 (성공 시만) ==========

  /// 완료 보너스 (모든 참가자)
  static const int completionBonus = 30;

  /// MVP 보너스 (기여도 1위)
  static const int mvpBonus = 20;

  /// 협력 보너스 (참가자당)
  static const int cooperationPerParticipant = 3;

  /// 협력 보너스 최대값
  static const int maxCooperationBonus = 30;

  // ========== 마일스톤 보너스 ==========

  /// 10km 이상 마일스톤
  static const int milestone10km = 10;

  /// 하프마라톤 (21.0975km) 이상 마일스톤
  static const int milestoneHalf = 30;

  /// 풀마라톤 (42.195km) 이상 마일스톤
  static const int milestoneFull = 50;

  // ========== 정산 관련 ==========

  /// 보상 수령 가능 기간 (일)
  static const int settlementExpirationDays = 7;

  // ========== 개인 운동 기본 보상 (챌린지 없을 때) ==========

  /// 개인 운동 기본 보상 (챌린지 보상 없을 때만 지급)
  /// 챌린지 참여 없이 운동한 사용자에게 최소 보상 제공
  static const int soloWorkoutBase = 3;

  /// 개인 운동 거리당 보상 (km당)
  static const double soloWorkoutPerKm = 1.0;

  /// 개인 운동 최대 보상 (하루)
  static const int soloWorkoutMaxReward = 20;
}

/// 마일스톤 타입
enum MilestoneType {
  /// 10km 이상
  km10,

  /// 하프마라톤 (21.0975km)
  half,

  /// 풀마라톤 (42.195km)
  full,
}

extension MilestoneTypeExtension on MilestoneType {
  String get displayName {
    switch (this) {
      case MilestoneType.km10:
        return '10km';
      case MilestoneType.half:
        return '하프마라톤';
      case MilestoneType.full:
        return '풀마라톤';
    }
  }

  int get bonusAmount {
    switch (this) {
      case MilestoneType.km10:
        return WoodRewardConstants.milestone10km;
      case MilestoneType.half:
        return WoodRewardConstants.milestoneHalf;
      case MilestoneType.full:
        return WoodRewardConstants.milestoneFull;
    }
  }

  /// 거리로부터 마일스톤 타입 결정
  static MilestoneType? fromDistance(double distanceKm) {
    if (distanceKm >= 42.195) return MilestoneType.full;
    if (distanceKm >= 21.0975) return MilestoneType.half;
    if (distanceKm >= 10) return MilestoneType.km10;
    return null;
  }
}

