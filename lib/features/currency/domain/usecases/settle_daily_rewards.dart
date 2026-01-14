import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/domain/entities/settlement_entity.dart';
import 'package:co_workfit/features/currency/domain/repositories/currency_repository.dart';
import 'package:co_workfit/features/currency/domain/usecases/calculate_reward.dart';

/// 통합 일일 정산 UseCase
///
/// 정산 로직:
/// 1. 해당 날짜의 모든 운동 기록 조회 → 개인 운동 보상 계산
///    - 모든 운동: 10 kcal = 재화 1개 (칼로리 필수)
///    - 칼로리 없으면 보상 없음
/// 2. 해당 날짜에 종료된 성공 챌린지 조회 (7일 이내)
///    - 참여한 운동 종류 수만큼 재화 분배 (목표/종류 수)
///    - MVP는 최대 기여 운동 타입 재화 +5
/// 3. 최고 성공 보너스 챌린지 1개만 선택 (총 보상 합계 기준)
/// 4. 모든 재화 한 번에 정산 (개인 운동 + 선택된 챌린지)
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
    final Map<CurrencyType, int> rewards = {};

    // 2. 모든 운동 기록에 대한 기본 보상 계산
    final List<SoloWorkoutReward> workoutRewards = [];

    for (final type in CurrencyType.values) {
      final workoutData = await _repository.getSoloWorkoutData(
        userId,
        settlementDate,
        type,
      );

      if (workoutData != null && workoutData.hasData) {
        final workoutReward = _calculator.calculateSoloWorkoutReward(
          workoutData: workoutData,
        );

        if (workoutReward.total > 0) {
          workoutRewards.add(workoutReward);
          rewards[type] = (rewards[type] ?? 0) + workoutReward.total;
        }
      }
    }

    // 3. 해당 날짜에 종료된 챌린지 조회
    final challenges =
        await _repository.getChallengesEndedOn(userId, settlementDate);

    // 4. 유효한 성공 챌린지만 필터링 (7일 이내 + 성공)
    final validChallenges = challenges.where((challenge) {
      final daysSinceEnd = now.difference(challenge.endDate).inDays;
      return daysSinceEnd <= 7 && challenge.isSuccess;
    }).toList();

    // 5. 모든 챌린지의 성공 보너스 계산
    final List<ChallengeReward> allChallengeRewards = [];

    for (final challenge in validChallenges) {
      final reward = _calculator.calculateChallengeSuccessBonus(
        challengeData: challenge,
      );

      allChallengeRewards.add(reward);
    }

    // 6. 가장 높은 성공 보너스 챌린지 1개 선택 (총 보상 합계 기준)
    String? selectedChallengeId;
    ChallengeReward? selectedChallenge;

    if (allChallengeRewards.isNotEmpty) {
      // 총 보상 합계로 정렬
      allChallengeRewards.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      final best = allChallengeRewards.first;

      if (best.totalAmount > 0) {
        selectedChallengeId = best.challengeId;
        selectedChallenge = ChallengeReward(
          challengeId: best.challengeId,
          challengeName: best.challengeName,
          isSuccess: best.isSuccess,
          completionBonus: best.completionBonus,
          mvpBonus: best.mvpBonus,
          totalRewards: best.totalRewards,
          selected: true,
          isMvp: best.isMvp,
          mvpCurrencyType: best.mvpCurrencyType,
        );

        // 선택된 챌린지의 모든 재화를 보상에 추가
        for (final entry in best.totalRewards.entries) {
          rewards[entry.key] = (rewards[entry.key] ?? 0) + entry.value;
        }
      }
    }

    // 7. 보상이 없으면 저장하지 않음
    final hasRewards = rewards.values.any((v) => v > 0);
    if (!hasRewards) {
      return null;
    }

    // 8. 선택되지 않은 챌린지 표시
    final finalChallengeRewards = allChallengeRewards.map((r) {
      if (r.challengeId == selectedChallengeId) {
        return selectedChallenge!;
      }
      return r;
    }).toList();

    // 9. 정산 기록 생성
    final settlement = SettlementEntity(
      settlementDate: settlementDate,
      settledAt: now,
      rewards: rewards,
      selectedChallengeId: selectedChallengeId,
      challengeRewards: finalChallengeRewards,
      workoutRewards: workoutRewards,
    );

    // 10. 재화 지급 및 정산 기록 저장
    await _repository.addCurrencies(userId, rewards, settlementDate);
    await _repository.saveSettlement(userId, settlement);

    return settlement;
  }
}

