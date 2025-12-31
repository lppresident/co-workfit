import 'package:co_workfit/features/wood/domain/entities/wood_reward_constants.dart';

/// 챌린지 기여 보상 계산 UseCase
///
/// 보상 체계:
/// - 기여: 제출 거리(km) × 1
/// - 첫 기여: +5개 (챌린지당 첫 제출만)
class CalculateContributionReward {
  /// 챌린지 기여 보상 계산
  ///
  /// [contributionKm] 챌린지에 제출한 거리 (km)
  /// [isFirstContribution] 해당 챌린지에서 첫 기여인지 여부
  ContributionRewardResult call({
    required double contributionKm,
    required bool isFirstContribution,
  }) {
    // 기여 보상
    final contributionReward =
        (contributionKm * WoodRewardConstants.contributionPerKm).round();

    // 첫 기여 보너스
    final firstContributionBonus =
        isFirstContribution ? WoodRewardConstants.firstContributionBonus : 0;

    // 총 보상
    final total = contributionReward + firstContributionBonus;

    return ContributionRewardResult(
      contributionReward: contributionReward,
      firstContributionBonus: firstContributionBonus,
      total: total,
    );
  }
}

/// 챌린지 기여 보상 결과
class ContributionRewardResult {
  /// 기여 보상 (거리 기반)
  final int contributionReward;

  /// 첫 기여 보너스
  final int firstContributionBonus;

  /// 총 보상
  final int total;

  const ContributionRewardResult({
    required this.contributionReward,
    required this.firstContributionBonus,
    required this.total,
  });

  @override
  String toString() {
    return 'ContributionReward(contribution: $contributionReward, '
        'firstBonus: $firstContributionBonus, total: $total)';
  }
}

