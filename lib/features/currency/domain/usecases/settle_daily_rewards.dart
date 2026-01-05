import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/domain/entities/settlement_entity.dart';
import 'package:co_workfit/features/currency/domain/repositories/currency_repository.dart';
import 'package:co_workfit/features/currency/domain/usecases/calculate_reward.dart';

/// 통합 일일 정산 UseCase
///
/// 정산 로직:
/// 1. 해당 날짜에 종료된 모든 챌린지 조회
/// 2. 각 재화 타입별로 챌린지 분류
/// 3. 각 재화별로 가장 높은 보상 챌린지 1개 선택
/// 4. 챌린지 보상이 없는 재화는 개인 운동 기록 확인 → 기본 보상 지급
/// 5. 모든 재화 한 번에 정산
class SettleDailyRewards {
  final CurrencyRepository _repository;
  final RewardCalculator _calculator;

  SettleDailyRewards({
    required CurrencyRepository repository,
    RewardCalculator? calculator,
  })  : _repository = repository,
        _calculator = calculator ?? const RewardCalculator();

  /// 특정 날짜의 보상 정산
  ///
  /// Returns: 정산 결과 (보상이 0인 경우 null)
  Future<SettlementEntity?> call({
    required String userId,
    required String settlementDate,
  }) async {
    // 1. 이미 정산된 날짜인지 확인
    final existingSettlement =
        await _repository.getSettlement(userId, settlementDate);
    if (existingSettlement != null) {
      return existingSettlement;
    }

    final now = DateTime.now();

    // 2. 해당 날짜에 종료된 챌린지 조회
    final challenges =
        await _repository.getChallengesEndedOn(userId, settlementDate);

    // 3. 유효한 챌린지만 필터링 (7일 이내)
    final validChallenges = challenges.where((challenge) {
      final daysSinceEnd = now.difference(challenge.endDate).inDays;
      return daysSinceEnd <= 7;
    }).toList();

    // 4. 재화별로 챌린지 분류 및 보상 계산
    final Map<CurrencyType, List<ChallengeReward>> rewardsByType = {};
    final List<ChallengeReward> allChallengeRewards = [];

    for (final challenge in validChallenges) {
      final currencyType = challenge.currencyType;

      final reward = _calculator.calculateChallengeReward(
        challengeData: challenge,
      );

      allChallengeRewards.add(reward);
      rewardsByType.putIfAbsent(currencyType, () => []).add(reward);
    }

    // 5. 각 재화별 최고 보상 선택
    final Map<CurrencyType, String?> selectedChallengeIds = {};
    final Map<CurrencyType, int> rewards = {};

    for (final type in CurrencyType.values) {
      final typeRewards = rewardsByType[type] ?? [];
      if (typeRewards.isNotEmpty) {
        typeRewards.sort((a, b) => b.total.compareTo(a.total));
        final best = typeRewards.first;
        if (best.total > 0) {
          selectedChallengeIds[type] = best.challengeId;
          rewards[type] = best.total;
        }
      }
    }

    // 6. 챌린지 보상이 없는 재화는 개인 운동 확인
    final List<SoloWorkoutReward> soloWorkoutRewards = [];

    for (final type in CurrencyType.values) {
      if (selectedChallengeIds[type] == null) {
        final soloData = await _repository.getSoloWorkoutData(
          userId,
          settlementDate,
          type,
        );

        if (soloData != null && soloData.hasData) {
          final soloReward = _calculator.calculateSoloWorkoutReward(
            workoutData: soloData,
          );

          if (soloReward.total > 0) {
            soloWorkoutRewards.add(soloReward);
            rewards[type] = (rewards[type] ?? 0) + soloReward.total;
          }
        }
      }
    }

    // 7. 보상이 없으면 저장하지 않음
    final hasRewards = rewards.values.any((v) => v > 0);
    if (!hasRewards) {
      return null;
    }

    // 8. 선택된 챌린지 표시
    final finalChallengeRewards = allChallengeRewards.map((r) {
      final isSelected = selectedChallengeIds[r.currencyType] == r.challengeId;
      if (isSelected) {
        return ChallengeReward(
          challengeId: r.challengeId,
          challengeName: r.challengeName,
          currencyType: r.currencyType,
          isSuccess: r.isSuccess,
          personalReward: r.personalReward,
          contributionReward: r.contributionReward,
          successBonus: r.successBonus,
          total: r.total,
          selected: true,
          isMvp: r.isMvp,
          milestoneName: r.milestoneName,
        );
      }
      return r;
    }).toList();

    // 9. 정산 기록 생성
    final settlement = SettlementEntity(
      settlementDate: settlementDate,
      settledAt: now,
      rewards: rewards,
      selectedChallengeIds: selectedChallengeIds,
      challengeRewards: finalChallengeRewards,
      soloWorkoutRewards: soloWorkoutRewards,
    );

    // 10. 재화 지급 및 정산 기록 저장
    await _repository.addCurrencies(userId, rewards, settlementDate);
    await _repository.saveSettlement(userId, settlement);

    return settlement;
  }
}

