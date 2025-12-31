/// 쇠(Iron) 보상 상수 정의
///
/// 이슈 #70 기반 보상 체계
/// 밸런스: 60분 중강도 헬스 ≈ 30분 달리기
abstract class IronRewardConstants {
  // ========== 강도 계수 (심박수 기반) ==========

  /// 저강도 (심박수 없음 or < 100 bpm)
  static const double intensityLow = 0.5;

  /// 중강도 (100-130 bpm)
  static const double intensityModerate = 0.83;

  /// 고강도 (130-150 bpm)
  static const double intensityHigh = 1.0;

  /// 매우 고강도 (150+ bpm)
  static const double intensityVeryHigh = 1.3;

  // ========== 개인 운동 보상 ==========

  /// 기본 보상 (운동 완료 시)
  static const int personalBase = 5;

  /// 점수당 보상 비율 (점수 ÷ 5)
  static const double personalScoreToIron = 0.2;

  /// 일일 첫 운동 보너스
  static const int dailyFirstWorkoutBonus = 3;

  // ========== 챌린지 기여 보상 ==========

  /// 기여 점수당 보상 비율 (점수 ÷ 10)
  static const double contributionScoreToIron = 0.1;

  /// 챌린지 첫 기여 보너스
  static const int firstContributionBonus = 5;

  // ========== 챌린지 성공 보상 (성공 시만) ==========

  /// 완료 보너스 (모든 참가자)
  static const int completionBonus = 30;

  /// MVP 보너스 (기여도 1위)
  static const int mvpBonus = 20;

  /// 협력 보너스 (참가자당)
  static const int cooperationPerParticipant = 2;

  /// 협력 보너스 최대값
  static const int maxCooperationBonus = 10;

  // ========== 마일스톤 보너스 (점수 기반) ==========

  /// 300점 이상 마일스톤
  static const int milestone300 = 5;

  /// 600점 이상 마일스톤
  static const int milestone600 = 10;

  /// 1200점 이상 마일스톤
  static const int milestone1200 = 20;

  // ========== 정산 관련 ==========

  /// 보상 수령 가능 기간 (일)
  static const int settlementExpirationDays = 7;
}

/// 운동 강도 타입
enum WorkoutIntensity {
  /// 저강도 (심박수 없음 or < 100 bpm)
  low,

  /// 중강도 (100-130 bpm)
  moderate,

  /// 고강도 (130-150 bpm)
  high,

  /// 매우 고강도 (150+ bpm)
  veryHigh,
}

extension WorkoutIntensityExtension on WorkoutIntensity {
  String get displayName {
    switch (this) {
      case WorkoutIntensity.low:
        return '저강도';
      case WorkoutIntensity.moderate:
        return '중강도';
      case WorkoutIntensity.high:
        return '고강도';
      case WorkoutIntensity.veryHigh:
        return '매우 고강도';
    }
  }

  double get coefficient {
    switch (this) {
      case WorkoutIntensity.low:
        return IronRewardConstants.intensityLow;
      case WorkoutIntensity.moderate:
        return IronRewardConstants.intensityModerate;
      case WorkoutIntensity.high:
        return IronRewardConstants.intensityHigh;
      case WorkoutIntensity.veryHigh:
        return IronRewardConstants.intensityVeryHigh;
    }
  }

  /// 심박수로부터 강도 타입 결정
  static WorkoutIntensity fromHeartRate(int? avgHeartRate) {
    if (avgHeartRate == null || avgHeartRate < 100) {
      return WorkoutIntensity.low;
    } else if (avgHeartRate < 130) {
      return WorkoutIntensity.moderate;
    } else if (avgHeartRate < 150) {
      return WorkoutIntensity.high;
    } else {
      return WorkoutIntensity.veryHigh;
    }
  }
}

/// 헬스 마일스톤 타입
enum StrengthMilestone {
  /// 300점 이상
  score300,

  /// 600점 이상
  score600,

  /// 1200점 이상
  score1200,
}

extension StrengthMilestoneExtension on StrengthMilestone {
  String get displayName {
    switch (this) {
      case StrengthMilestone.score300:
        return '300점';
      case StrengthMilestone.score600:
        return '600점';
      case StrengthMilestone.score1200:
        return '1,200점';
    }
  }

  int get bonusAmount {
    switch (this) {
      case StrengthMilestone.score300:
        return IronRewardConstants.milestone300;
      case StrengthMilestone.score600:
        return IronRewardConstants.milestone600;
      case StrengthMilestone.score1200:
        return IronRewardConstants.milestone1200;
    }
  }

  /// 점수로부터 마일스톤 타입 결정
  static StrengthMilestone? fromScore(double score) {
    if (score >= 1200) return StrengthMilestone.score1200;
    if (score >= 600) return StrengthMilestone.score600;
    if (score >= 300) return StrengthMilestone.score300;
    return null;
  }
}

/// 헬스 점수 계산 유틸리티
class StrengthScoreCalculator {
  /// 헬스 점수 계산
  /// 
  /// 공식: 시간(분) × 강도계수
  /// 예: 60분 × 0.83(중강도) = 50점
  static double calculateStrengthScore({
    required int durationMinutes,
    int? avgHeartRate,
  }) {
    final intensity = WorkoutIntensityExtension.fromHeartRate(avgHeartRate);
    return durationMinutes * intensity.coefficient;
  }

  /// 운동으로부터 쇠 개인 보상 계산
  static int calculatePersonalReward({
    required double strengthScore,
    required bool isFirstWorkout,
  }) {
    final baseReward = IronRewardConstants.personalBase;
    final scoreReward = (strengthScore * IronRewardConstants.personalScoreToIron).round();
    final firstBonus = isFirstWorkout ? IronRewardConstants.dailyFirstWorkoutBonus : 0;

    return baseReward + scoreReward + firstBonus;
  }

  /// 챌린지 기여 보상 계산
  static int calculateContributionReward({
    required double strengthScore,
    required bool isFirstContribution,
  }) {
    final scoreReward = (strengthScore * IronRewardConstants.contributionScoreToIron).round();
    final firstBonus = isFirstContribution ? IronRewardConstants.firstContributionBonus : 0;

    return scoreReward + firstBonus;
  }

  /// 챌린지 성공 보너스 계산
  static int calculateSuccessBonus({
    required double totalContributedScore,
    required int participantCount,
    required bool isMvp,
  }) {
    int bonus = IronRewardConstants.completionBonus;

    // MVP 보너스
    if (isMvp) {
      bonus += IronRewardConstants.mvpBonus;
    }

    // 협력 보너스
    final cooperationBonus = (participantCount - 1) * IronRewardConstants.cooperationPerParticipant;
    bonus += cooperationBonus.clamp(0, IronRewardConstants.maxCooperationBonus);

    // 마일스톤 보너스
    final milestone = StrengthMilestoneExtension.fromScore(totalContributedScore);
    if (milestone != null) {
      bonus += milestone.bonusAmount;
    }

    return bonus;
  }
}

