import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';
import 'package:co_workfit/features/wood/domain/repositories/wood_repository.dart';
import 'package:co_workfit/features/wood/domain/usecases/calculate_challenge_reward.dart';

/// 일일 정산 UseCase
///
/// 정산 로직:
/// 1. 해당 날짜(D)에 종료된 모든 챌린지 조회
/// 2. 각 챌린지별 총 보상 계산 = 개인 운동 보상 + 기여 보상 + 성공 보너스
/// 3. 가장 높은 보상 챌린지 1개 선택
/// 4. 해당 챌린지 보상만 지급
/// 5. 나머지 챌린지는 보상 없음
/// 6. 0개 정산은 저장하지 않음
class SettleDailyRewards {
  final WoodRepository _repository;
  final CalculateChallengeReward _calculateChallengeReward;

  SettleDailyRewards({
    required WoodRepository repository,
    CalculateChallengeReward? calculateChallengeReward,
  })  : _repository = repository,
        _calculateChallengeReward =
            calculateChallengeReward ?? CalculateChallengeReward();

  /// 특정 날짜의 보상 정산
  ///
  /// [userId] 사용자 ID
  /// [settlementDate] 정산 대상 날짜 (yyyy-MM-dd 형식)
  /// 
  /// Returns: 정산 결과 (0개 정산인 경우 null)
  Future<WoodSettlementEntity?> call({
    required String userId,
    required String settlementDate,
  }) async {
    // 1. 이미 정산된 날짜인지 확인
    final existingSettlement =
        await _repository.getSettlement(userId, settlementDate);
    if (existingSettlement != null) {
      return existingSettlement;
    }

    // 2. 해당 날짜에 종료된 챌린지 조회
    final challenges =
        await _repository.getChallengesEndedOn(userId, settlementDate);

    // 정산할 챌린지가 없는 경우 - 저장하지 않고 null 반환
    if (challenges.isEmpty) {
      return null;
    }

    // 3. 유효한 챌린지만 필터링 (만료된 챌린지 제외 - 7일 이내)
    final now = DateTime.now();
    final validChallenges = challenges.where((challenge) {
      final daysSinceEnd = now.difference(challenge.endDate).inDays;
      return daysSinceEnd <= 7;
    }).toList();

    // 유효한 챌린지가 없는 경우 - 저장하지 않고 null 반환
    if (validChallenges.isEmpty) {
      return null;
    }

    // 4. 첫 운동 여부 확인 (해당 날짜 기준)
    final settlementDateTime = DateTime.parse(settlementDate);
    final isFirstWorkoutOfDay =
        await _repository.isFirstWorkoutOfDay(userId, settlementDateTime);

    // 5. 각 챌린지별 보상 계산
    final rewardDetails = <ChallengeRewardDetail>[];
    for (final challenge in validChallenges) {
      final reward = _calculateChallengeReward(
        challengeData: challenge,
        isFirstWorkoutOfDay: isFirstWorkoutOfDay,
      );
      rewardDetails.add(reward);
    }

    // 6. 가장 높은 보상 챌린지 선택
    rewardDetails.sort((a, b) => b.total.compareTo(a.total));
    final selectedReward = rewardDetails.first;

    // 보상이 0인 경우 저장하지 않음
    if (selectedReward.total <= 0) {
      return null;
    }

    // 선택된 챌린지 표시
    final finalRewards = rewardDetails.map((r) {
      if (r.challengeId == selectedReward.challengeId) {
        return ChallengeRewardDetail(
          challengeId: r.challengeId,
          challengeName: r.challengeName,
          isSuccess: r.isSuccess,
          personalReward: r.personalReward,
          contributionReward: r.contributionReward,
          successBonus: r.successBonus,
          total: r.total,
          selected: true,
          isMvp: r.isMvp,
          milestoneType: r.milestoneType,
        );
      }
      return r;
    }).toList();

    // 7. 정산 기록 생성
    final settlement = WoodSettlementEntity(
      settlementDate: settlementDate,
      settledAt: now,
      selectedChallengeId: selectedReward.challengeId,
      totalWoodAwarded: selectedReward.total,
      challenges: finalRewards,
    );

    // 8. 통나무 지급 및 정산 기록 저장
    await _repository.addWood(userId, selectedReward.total, settlementDate);
    await _repository.saveSettlement(userId, settlement);

    return settlement;
  }
}
