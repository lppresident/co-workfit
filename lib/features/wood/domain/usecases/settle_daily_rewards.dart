import 'dart:math';
import 'package:co_workfit/features/iron/domain/entities/iron_reward_constants.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_reward_constants.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';
import 'package:co_workfit/features/wood/domain/repositories/wood_repository.dart';
import 'package:co_workfit/features/wood/domain/usecases/calculate_challenge_reward.dart';

/// 일일 정산 UseCase
///
/// 정산 로직:
/// 1. 해당 날짜(D)에 종료된 모든 챌린지 조회
/// 2. 챌린지를 타입별로 분리 (달리기/헬스)
/// 3. 각 타입별로 가장 높은 보상 챌린지 1개씩 선택
/// 4. 챌린지 보상이 없는 타입의 경우 개인 운동 기록 확인 → 기본 보상 지급
/// 5. 달리기 → 통나무, 헬스 → 쇠
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

    final now = DateTime.now();
    
    // 2. 해당 날짜에 종료된 챌린지 조회
    final challenges =
        await _repository.getChallengesEndedOn(userId, settlementDate);

    // 3. 유효한 챌린지만 필터링 (만료된 챌린지 제외 - 7일 이내)
    final validChallenges = challenges.where((challenge) {
      final daysSinceEnd = now.difference(challenge.endDate).inDays;
      return daysSinceEnd <= 7;
    }).toList();

    // 4. 첫 운동 여부 확인 (해당 날짜 기준)
    final settlementDateTime = DateTime.parse(settlementDate);
    final isFirstWorkoutOfDay =
        await _repository.isFirstWorkoutOfDay(userId, settlementDateTime);

    // 5. 챌린지를 타입별로 분리
    final runningChallenges = validChallenges.where((c) => c.isRunning).toList();
    final strengthChallenges = validChallenges.where((c) => c.isStrengthTraining).toList();

    // 6. 각 타입별 보상 계산 및 최고 보상 선택
    final List<ChallengeRewardDetail> allRewardDetails = [];
    ChallengeRewardDetail? selectedWoodReward;
    ChallengeRewardDetail? selectedIronReward;
    
    // 개인 운동 보상 추적
    int soloWoodReward = 0;
    int soloIronReward = 0;
    SoloWorkoutData? soloRunningData;
    SoloWorkoutData? soloStrengthData;

    // 달리기 챌린지 처리
    if (runningChallenges.isNotEmpty) {
      final woodRewards = <ChallengeRewardDetail>[];
      for (final challenge in runningChallenges) {
        final reward = _calculateChallengeReward(
          challengeData: challenge,
          isFirstWorkoutOfDay: isFirstWorkoutOfDay,
          currencyType: RewardCurrencyType.wood,
        );
        woodRewards.add(reward);
      }
      woodRewards.sort((a, b) => b.total.compareTo(a.total));
      if (woodRewards.isNotEmpty && woodRewards.first.total > 0) {
        selectedWoodReward = woodRewards.first;
      }
      allRewardDetails.addAll(woodRewards);
    }

    // 헬스 챌린지 처리
    if (strengthChallenges.isNotEmpty) {
      final ironRewards = <ChallengeRewardDetail>[];
      for (final challenge in strengthChallenges) {
        final reward = _calculateChallengeReward(
          challengeData: challenge,
          isFirstWorkoutOfDay: isFirstWorkoutOfDay,
          currencyType: RewardCurrencyType.iron,
        );
        ironRewards.add(reward);
      }
      ironRewards.sort((a, b) => b.total.compareTo(a.total));
      if (ironRewards.isNotEmpty && ironRewards.first.total > 0) {
        selectedIronReward = ironRewards.first;
      }
      allRewardDetails.addAll(ironRewards);
    }

    // 7. 챌린지 보상이 없는 경우 개인 운동 기록 확인
    // 달리기 챌린지 보상이 없으면 → 개인 달리기 운동 확인
    if (selectedWoodReward == null) {
      soloRunningData = await _repository.getRunningWorkoutsOnDate(userId, settlementDate);
      if (soloRunningData != null && soloRunningData.hasRunningData) {
        soloWoodReward = _calculateSoloRunningReward(soloRunningData.totalDistance);
      }
    }

    // 헬스 챌린지 보상이 없으면 → 개인 헬스 운동 확인
    if (selectedIronReward == null) {
      soloStrengthData = await _repository.getStrengthWorkoutsOnDate(userId, settlementDate);
      if (soloStrengthData != null && soloStrengthData.hasStrengthData) {
        soloIronReward = _calculateSoloStrengthReward(soloStrengthData.totalScore);
      }
    }

    // 총 보상 계산
    final totalWood = (selectedWoodReward?.total ?? 0) + soloWoodReward;
    final totalIron = (selectedIronReward?.total ?? 0) + soloIronReward;
    
    // 보상이 0인 경우 저장하지 않음
    if (totalWood <= 0 && totalIron <= 0) {
      return null;
    }

    // 8. 선택된 챌린지 표시
    final finalRewards = allRewardDetails.map((r) {
      final isSelectedWood = selectedWoodReward != null && 
          r.challengeId == selectedWoodReward.challengeId;
      final isSelectedIron = selectedIronReward != null && 
          r.challengeId == selectedIronReward.challengeId;
      
      if (isSelectedWood || isSelectedIron) {
        return ChallengeRewardDetail(
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
          milestoneType: r.milestoneType,
        );
      }
      return r;
    }).toList();

    // 9. 개인 운동 보상 추가 (챌린지가 아닌 개인 운동)
    if (soloWoodReward > 0 && soloRunningData != null) {
      finalRewards.add(ChallengeRewardDetail(
        challengeId: 'solo_running_$settlementDate',
        challengeName: '개인 달리기 (${soloRunningData.totalDistance.toStringAsFixed(1)}km)',
        currencyType: RewardCurrencyType.wood,
        isSuccess: true,
        personalReward: soloWoodReward,
        contributionReward: 0,
        successBonus: 0,
        total: soloWoodReward,
        selected: true,
        isSoloWorkout: true,
      ));
    }

    if (soloIronReward > 0 && soloStrengthData != null) {
      finalRewards.add(ChallengeRewardDetail(
        challengeId: 'solo_strength_$settlementDate',
        challengeName: '개인 헬스 (${soloStrengthData.totalScore.toStringAsFixed(0)}점)',
        currencyType: RewardCurrencyType.iron,
        isSuccess: true,
        personalReward: soloIronReward,
        contributionReward: 0,
        successBonus: 0,
        total: soloIronReward,
        selected: true,
        isSoloWorkout: true,
      ));
    }

    // 10. 정산 기록 생성
    final settlement = WoodSettlementEntity(
      settlementDate: settlementDate,
      settledAt: now,
      selectedChallengeId: selectedWoodReward?.challengeId,
      selectedIronChallengeId: selectedIronReward?.challengeId,
      totalWoodAwarded: totalWood,
      totalIronAwarded: totalIron,
      challenges: finalRewards,
      hasSoloWoodReward: soloWoodReward > 0,
      hasSoloIronReward: soloIronReward > 0,
    );

    // 11. 재화 지급 및 정산 기록 저장
    if (totalWood > 0) {
      await _repository.addWood(userId, totalWood, settlementDate);
    }
    if (totalIron > 0) {
      await _repository.addIron(userId, totalIron, settlementDate);
    }
    await _repository.saveSettlement(userId, settlement);

    return settlement;
  }

  /// 개인 달리기 운동 보상 계산
  int _calculateSoloRunningReward(double distanceKm) {
    final baseReward = WoodRewardConstants.soloWorkoutBase;
    final distanceReward = (distanceKm * WoodRewardConstants.soloWorkoutPerKm).round();
    final total = baseReward + distanceReward;
    return min(total, WoodRewardConstants.soloWorkoutMaxReward);
  }

  /// 개인 헬스 운동 보상 계산
  int _calculateSoloStrengthReward(double score) {
    final baseReward = IronRewardConstants.soloWorkoutBase;
    final scoreReward = (score * IronRewardConstants.soloWorkoutScoreToIron).round();
    final total = baseReward + scoreReward;
    return min(total, IronRewardConstants.soloWorkoutMaxReward);
  }
}
