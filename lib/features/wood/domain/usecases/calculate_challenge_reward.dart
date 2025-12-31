import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';
import 'package:co_workfit/features/wood/domain/repositories/wood_repository.dart';
import 'package:co_workfit/features/wood/domain/usecases/calculate_personal_reward.dart';
import 'package:co_workfit/features/wood/domain/usecases/calculate_contribution_reward.dart';
import 'package:co_workfit/features/wood/domain/usecases/calculate_success_bonus.dart';

/// 챌린지 전체 보상 계산 UseCase
///
/// 개인 운동 보상 + 기여 보상 + 성공 보너스를 통합 계산
class CalculateChallengeReward {
  final CalculatePersonalReward _calculatePersonalReward;
  final CalculateContributionReward _calculateContributionReward;
  final CalculateSuccessBonus _calculateSuccessBonus;

  CalculateChallengeReward({
    CalculatePersonalReward? calculatePersonalReward,
    CalculateContributionReward? calculateContributionReward,
    CalculateSuccessBonus? calculateSuccessBonus,
  })  : _calculatePersonalReward =
            calculatePersonalReward ?? CalculatePersonalReward(),
        _calculateContributionReward =
            calculateContributionReward ?? CalculateContributionReward(),
        _calculateSuccessBonus =
            calculateSuccessBonus ?? CalculateSuccessBonus();

  /// 챌린지 보상 계산
  ///
  /// [challengeData] 정산용 챌린지 데이터
  /// [isFirstWorkoutOfDay] 해당 날짜의 첫 운동인지 여부
  /// [currencyType] 보상 재화 타입 (wood/iron)
  ChallengeRewardDetail call({
    required ChallengeSettlementData challengeData,
    required bool isFirstWorkoutOfDay,
    RewardCurrencyType currencyType = RewardCurrencyType.wood,
  }) {
    // 1. 개인 운동 보상
    final personalResult = _calculatePersonalReward(
      distanceKm: challengeData.userTotalWorkoutDistance,
      isFirstWorkoutOfDay: isFirstWorkoutOfDay,
    );

    // 2. 챌린지 기여 보상
    final contributionResult = _calculateContributionReward(
      contributionKm: challengeData.userContribution,
      isFirstContribution: challengeData.isFirstContribution,
    );

    // 3. 성공 보너스
    final successResult = _calculateSuccessBonus(
      isSuccess: challengeData.isSuccess,
      isMvp: challengeData.isUserMvp,
      participantCount: challengeData.participantCount,
      targetDistanceKm: challengeData.targetDistance,
    );

    // 총 보상
    final total =
        personalResult.total + contributionResult.total + successResult.total;

    return ChallengeRewardDetail(
      challengeId: challengeData.challengeId,
      challengeName: challengeData.challengeName,
      currencyType: currencyType,
      isSuccess: challengeData.isSuccess,
      personalReward: personalResult.total,
      contributionReward: contributionResult.total,
      successBonus: successResult.total,
      total: total,
      selected: false, // 나중에 정산 시 결정
      isMvp: challengeData.isUserMvp,
      milestoneType: successResult.milestoneType?.name,
    );
  }
}

