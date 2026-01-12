import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/domain/entities/settlement_entity.dart';
import 'package:co_workfit/features/currency/domain/entities/challenge_settlement_data.dart';

/// 통합 보상 계산기
///
/// 모든 재화 타입에 대해 동일한 로직으로 보상 계산
class RewardCalculator {
  const RewardCalculator();

  /// 챌린지 성공 보너스 계산 (통합 챌린지)
  ///
  /// 성공 시 참여한 운동 종류에 따라 재화 분배
  /// - 1종류: 해당 재화 전액
  /// - 2종류: 2등분
  /// - 3종류: 3등분
  ///
  /// MVP는 가장 많이 기여한 운동 타입의 재화 +5
  ChallengeReward calculateChallengeSuccessBonus({
    required ChallengeSettlementData challengeData,
  }) {
    if (!challengeData.isSuccess) {
      // 실패 시 보상 없음
      return ChallengeReward(
        challengeId: challengeData.challengeId,
        challengeName: challengeData.challengeName,
        isSuccess: false,
        completionBonus: {},
        mvpBonus: {},
        totalRewards: {},
        selected: false,
        isMvp: false,
      );
    }

    final targetValue = challengeData.targetValue;
    final participatedTypes = challengeData.participatedWorkoutTypes;

    // 1. 기본 완료 보너스 계산
    final completionBonus = <CurrencyType, int>{};

    if (participatedTypes.isNotEmpty) {
      final rewardPerType = (targetValue / participatedTypes.length).ceil();

      for (final workoutType in participatedTypes) {
        final currencyType = ChallengeSettlementData.workoutTypeToCurrency(workoutType);
        completionBonus[currencyType] = rewardPerType;
      }
    }

    // 2. MVP 보너스 계산
    final mvpBonus = <CurrencyType, int>{};
    CurrencyType? mvpCurrencyType;

    if (challengeData.isUserMvp) {
      final topWorkoutType = challengeData.getUserTopContributionType();
      if (topWorkoutType != null) {
        mvpCurrencyType = ChallengeSettlementData.workoutTypeToCurrency(topWorkoutType);
        mvpBonus[mvpCurrencyType] = 5;
      }
    }

    // 3. 총 보상 계산
    final totalRewards = <CurrencyType, int>{};
    for (final type in CurrencyType.values) {
      final completion = completionBonus[type] ?? 0;
      final mvp = mvpBonus[type] ?? 0;
      final total = completion + mvp;
      if (total > 0) {
        totalRewards[type] = total;
      }
    }

    return ChallengeReward(
      challengeId: challengeData.challengeId,
      challengeName: challengeData.challengeName,
      isSuccess: true,
      completionBonus: completionBonus,
      mvpBonus: mvpBonus,
      totalRewards: totalRewards,
      selected: false, // 정산 시 결정
      isMvp: challengeData.isUserMvp,
      mvpCurrencyType: mvpCurrencyType,
    );
  }

  /// 챌린지 보상 계산 (구 로직 - deprecated)
  @Deprecated('Use calculateChallengeSuccessBonus instead')
  ChallengeReward calculateChallengeReward({
    required ChallengeSettlementData challengeData,
  }) {
    // 새로운 통합 챌린지 시스템 사용
    return calculateChallengeSuccessBonus(challengeData: challengeData);
  }

  /// 개인 운동 보상 계산 (챌린지 없을 때)
  ///
  /// 변환 규칙:
  /// - 달리기: 1km = 1개
  /// - 헬스/기타: 100 kcal = 1개
  /// - 올림 적용 (ceil)
  SoloWorkoutReward calculateSoloWorkoutReward({
    required SoloWorkoutData workoutData,
  }) {
    // value를 올림하여 재화 개수 계산
    final total = workoutData.value.ceil();

    return SoloWorkoutReward(
      currencyType: workoutData.currencyType,
      value: workoutData.value,
      unit: workoutData.unit,
      total: total,
    );
  }

}

