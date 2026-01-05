import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/domain/entities/settlement_entity.dart';

/// 정산 기록 Firestore 모델
class SettlementModel {
  final String settlementDate;
  final DateTime settledAt;
  final Map<CurrencyType, int> rewards;
  final String? selectedChallengeId;
  final List<ChallengeRewardModel> challengeRewards;
  final List<SoloWorkoutRewardModel> workoutRewards;

  const SettlementModel({
    required this.settlementDate,
    required this.settledAt,
    required this.rewards,
    this.selectedChallengeId,
    required this.challengeRewards,
    required this.workoutRewards,
  });

  factory SettlementModel.fromFirestore(Map<String, dynamic> data) {
    // rewards 파싱
    final rewards = <CurrencyType, int>{};
    final rewardsData = data['rewards'] as Map<String, dynamic>? ?? {};
    for (final type in CurrencyType.values) {
      rewards[type] = (rewardsData[type.name] as int?) ?? 0;
    }

    // challengeRewards 파싱
    final challengeRewardsList = (data['challengeRewards'] as List<dynamic>? ?? [])
        .map((e) => ChallengeRewardModel.fromFirestore(e as Map<String, dynamic>))
        .toList();

    // workoutRewards 파싱 (하위 호환성: soloWorkoutRewards도 지원)
    final workoutRewardsList = (data['workoutRewards'] as List<dynamic>? ??
            data['soloWorkoutRewards'] as List<dynamic>? ??
            [])
        .map((e) => SoloWorkoutRewardModel.fromFirestore(e as Map<String, dynamic>))
        .toList();

    // settledAt 파싱
    DateTime settledAt;
    final settledAtData = data['settledAt'];
    if (settledAtData is Timestamp) {
      settledAt = settledAtData.toDate();
    } else if (settledAtData is String) {
      settledAt = DateTime.parse(settledAtData);
    } else {
      settledAt = DateTime.now();
    }

    return SettlementModel(
      settlementDate: data['settlementDate'] as String,
      settledAt: settledAt,
      rewards: rewards,
      selectedChallengeId: data['selectedChallengeId'] as String?,
      challengeRewards: challengeRewardsList,
      workoutRewards: workoutRewardsList,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'settlementDate': settlementDate,
      'settledAt': Timestamp.fromDate(settledAt),
      'rewards': {
        for (final entry in rewards.entries) entry.key.name: entry.value,
      },
      'selectedChallengeId': selectedChallengeId,
      'challengeRewards': challengeRewards.map((e) => e.toFirestore()).toList(),
      'workoutRewards': workoutRewards.map((e) => e.toFirestore()).toList(),
    };
  }

  SettlementEntity toEntity() {
    return SettlementEntity(
      settlementDate: settlementDate,
      settledAt: settledAt,
      rewards: rewards,
      selectedChallengeId: selectedChallengeId,
      challengeRewards: challengeRewards.map((e) => e.toEntity()).toList(),
      workoutRewards: workoutRewards.map((e) => e.toEntity()).toList(),
    );
  }

  factory SettlementModel.fromEntity(SettlementEntity entity) {
    return SettlementModel(
      settlementDate: entity.settlementDate,
      settledAt: entity.settledAt,
      rewards: entity.rewards,
      selectedChallengeId: entity.selectedChallengeId,
      challengeRewards: entity.challengeRewards
          .map((e) => ChallengeRewardModel.fromEntity(e))
          .toList(),
      workoutRewards: entity.workoutRewards
          .map((e) => SoloWorkoutRewardModel.fromEntity(e))
          .toList(),
    );
  }
}

class ChallengeRewardModel {
  final String challengeId;
  final String challengeName;
  final CurrencyType currencyType;
  final bool isSuccess;
  final int successBonus;
  final int total;
  final bool selected;
  final bool isMvp;
  final String? milestoneName;

  const ChallengeRewardModel({
    required this.challengeId,
    required this.challengeName,
    required this.currencyType,
    required this.isSuccess,
    required this.successBonus,
    required this.total,
    required this.selected,
    this.isMvp = false,
    this.milestoneName,
  });

  factory ChallengeRewardModel.fromFirestore(Map<String, dynamic> data) {
    return ChallengeRewardModel(
      challengeId: data['challengeId'] as String,
      challengeName: data['challengeName'] as String,
      currencyType: CurrencyType.values.firstWhere(
        (e) => e.name == data['currencyType'],
        orElse: () => CurrencyType.wood,
      ),
      isSuccess: data['isSuccess'] as bool? ?? false,
      successBonus: data['successBonus'] as int? ?? 0,
      total: data['total'] as int? ?? 0,
      selected: data['selected'] as bool? ?? false,
      isMvp: data['isMvp'] as bool? ?? false,
      milestoneName: data['milestoneName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'challengeName': challengeName,
      'currencyType': currencyType.name,
      'isSuccess': isSuccess,
      'successBonus': successBonus,
      'total': total,
      'selected': selected,
      'isMvp': isMvp,
      'milestoneName': milestoneName,
    };
  }

  ChallengeReward toEntity() {
    return ChallengeReward(
      challengeId: challengeId,
      challengeName: challengeName,
      currencyType: currencyType,
      isSuccess: isSuccess,
      successBonus: successBonus,
      total: total,
      selected: selected,
      isMvp: isMvp,
      milestoneName: milestoneName,
    );
  }

  factory ChallengeRewardModel.fromEntity(ChallengeReward entity) {
    return ChallengeRewardModel(
      challengeId: entity.challengeId,
      challengeName: entity.challengeName,
      currencyType: entity.currencyType,
      isSuccess: entity.isSuccess,
      successBonus: entity.successBonus,
      total: entity.total,
      selected: entity.selected,
      isMvp: entity.isMvp,
      milestoneName: entity.milestoneName,
    );
  }
}

class SoloWorkoutRewardModel {
  final CurrencyType currencyType;
  final double value;
  final String unit;
  final int total;

  const SoloWorkoutRewardModel({
    required this.currencyType,
    required this.value,
    required this.unit,
    required this.total,
  });

  factory SoloWorkoutRewardModel.fromFirestore(Map<String, dynamic> data) {
    return SoloWorkoutRewardModel(
      currencyType: CurrencyType.values.firstWhere(
        (e) => e.name == data['currencyType'],
        orElse: () => CurrencyType.wood,
      ),
      value: (data['value'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] as String? ?? '',
      total: data['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currencyType': currencyType.name,
      'value': value,
      'unit': unit,
      'total': total,
    };
  }

  SoloWorkoutReward toEntity() {
    return SoloWorkoutReward(
      currencyType: currencyType,
      value: value,
      unit: unit,
      total: total,
    );
  }

  factory SoloWorkoutRewardModel.fromEntity(SoloWorkoutReward entity) {
    return SoloWorkoutRewardModel(
      currencyType: entity.currencyType,
      value: entity.value,
      unit: entity.unit,
      total: entity.total,
    );
  }
}


