import 'dart:math';
import 'package:co_workfit/features/currency/domain/entities/reward_config.dart';
import 'package:co_workfit/features/currency/domain/entities/settlement_entity.dart';
import 'package:co_workfit/features/currency/domain/entities/challenge_settlement_data.dart';

/// 통합 보상 계산기
/// 
/// 모든 재화 타입에 대해 동일한 로직으로 보상 계산
class RewardCalculator {
  const RewardCalculator();

  /// 챌린지 보상 계산
  ChallengeReward calculateChallengeReward({
    required ChallengeSettlementData challengeData,
  }) {
    final currencyType = challengeData.currencyType;
    final config = CurrencyConfigRegistry.getConfig(currencyType);

    // 1. 개인 운동 보상
    final personalReward = _calculatePersonalReward(
      config: config,
      value: challengeData.userTotalWorkoutValue,
    );

    // 2. 챌린지 기여 보상
    final contributionReward = _calculateContributionReward(
      config: config,
      value: challengeData.userContribution,
      isFirstContribution: challengeData.isFirstContribution,
    );

    // 3. 성공 보너스
    final successBonus = _calculateSuccessBonus(
      config: config,
      isSuccess: challengeData.isSuccess,
      isMvp: challengeData.isUserMvp,
      participantCount: challengeData.participantCount,
      targetValue: challengeData.targetValue,
    );

    final total = personalReward + contributionReward + successBonus;
    final milestoneName = challengeData.isSuccess 
        ? config.getMilestoneName(challengeData.targetValue) 
        : null;

    return ChallengeReward(
      challengeId: challengeData.challengeId,
      challengeName: challengeData.challengeName,
      currencyType: currencyType,
      isSuccess: challengeData.isSuccess,
      personalReward: personalReward,
      contributionReward: contributionReward,
      successBonus: successBonus,
      total: total,
      selected: false, // 정산 시 결정
      isMvp: challengeData.isUserMvp,
      milestoneName: milestoneName,
    );
  }

  /// 개인 운동 보상 계산 (챌린지 없을 때)
  SoloWorkoutReward calculateSoloWorkoutReward({
    required SoloWorkoutData workoutData,
  }) {
    final config = CurrencyConfigRegistry.getConfig(workoutData.currencyType);

    final baseReward = config.soloWorkoutBase;
    final unitReward = (workoutData.value * config.soloWorkoutPerUnit).round();
    final total = min(baseReward + unitReward, config.soloWorkoutMaxReward);

    return SoloWorkoutReward(
      currencyType: workoutData.currencyType,
      value: workoutData.value,
      unit: workoutData.unit,
      total: total,
    );
  }

  int _calculatePersonalReward({
    required RewardConfig config,
    required double value,
  }) {
    final baseReward = config.personalBase;
    final unitReward = (value * config.personalPerUnit).round();

    return baseReward + unitReward;
  }

  int _calculateContributionReward({
    required RewardConfig config,
    required double value,
    required bool isFirstContribution,
  }) {
    final unitReward = (value * config.contributionPerUnit).round();
    final firstBonus = isFirstContribution ? config.firstContributionBonus : 0;

    return unitReward + firstBonus;
  }

  int _calculateSuccessBonus({
    required RewardConfig config,
    required bool isSuccess,
    required bool isMvp,
    required int participantCount,
    required double targetValue,
  }) {
    if (!isSuccess) return 0;

    int bonus = config.completionBonus;

    // MVP 보너스
    if (isMvp) {
      bonus += config.mvpBonus;
    }

    // 협력 보너스
    final cooperationBonus = 
        (participantCount - 1) * config.cooperationPerParticipant;
    bonus += cooperationBonus.clamp(0, config.maxCooperationBonus);

    // 마일스톤 보너스
    bonus += config.calculateMilestoneBonus(targetValue);

    return bonus;
  }
}

