import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/domain/entities/settlement_entity.dart';

/// 정산 기록 Firestore 모델
class SettlementModel {
  final String settlementDate;
  final DateTime settledAt;
  final Map<CurrencyType, int> rewards;
  final Map<CurrencyType, String?> selectedChallengeIds;
  final List<ChallengeRewardModel> challengeRewards;
  final List<SoloWorkoutRewardModel> soloWorkoutRewards;

  const SettlementModel({
    required this.settlementDate,
    required this.settledAt,
    required this.rewards,
    required this.selectedChallengeIds,
    required this.challengeRewards,
    required this.soloWorkoutRewards,
  });

  factory SettlementModel.fromFirestore(Map<String, dynamic> data) {
    // rewards 파싱
    final rewards = <CurrencyType, int>{};
    final rewardsData = data['rewards'] as Map<String, dynamic>? ?? {};
    for (final type in CurrencyType.values) {
      rewards[type] = (rewardsData[type.name] as int?) ?? 0;
    }

    // selectedChallengeIds 파싱
    final selectedIds = <CurrencyType, String?>{};
    final selectedData = data['selectedChallengeIds'] as Map<String, dynamic>? ?? {};
    for (final type in CurrencyType.values) {
      selectedIds[type] = selectedData[type.name] as String?;
    }

    // challengeRewards 파싱
    final challengeRewardsList = (data['challengeRewards'] as List<dynamic>? ?? [])
        .map((e) => ChallengeRewardModel.fromFirestore(e as Map<String, dynamic>))
        .toList();

    // soloWorkoutRewards 파싱
    final soloRewardsList = (data['soloWorkoutRewards'] as List<dynamic>? ?? [])
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
      selectedChallengeIds: selectedIds,
      challengeRewards: challengeRewardsList,
      soloWorkoutRewards: soloRewardsList,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'settlementDate': settlementDate,
      'settledAt': Timestamp.fromDate(settledAt),
      'rewards': {
        for (final entry in rewards.entries) entry.key.name: entry.value,
      },
      'selectedChallengeIds': {
        for (final entry in selectedChallengeIds.entries)
          entry.key.name: entry.value,
      },
      'challengeRewards': challengeRewards.map((e) => e.toFirestore()).toList(),
      'soloWorkoutRewards': soloWorkoutRewards.map((e) => e.toFirestore()).toList(),
    };
  }

  SettlementEntity toEntity() {
    return SettlementEntity(
      settlementDate: settlementDate,
      settledAt: settledAt,
      rewards: rewards,
      selectedChallengeIds: selectedChallengeIds,
      challengeRewards: challengeRewards.map((e) => e.toEntity()).toList(),
      soloWorkoutRewards: soloWorkoutRewards.map((e) => e.toEntity()).toList(),
    );
  }

  factory SettlementModel.fromEntity(SettlementEntity entity) {
    return SettlementModel(
      settlementDate: entity.settlementDate,
      settledAt: entity.settledAt,
      rewards: entity.rewards,
      selectedChallengeIds: entity.selectedChallengeIds,
      challengeRewards: entity.challengeRewards
          .map((e) => ChallengeRewardModel.fromEntity(e))
          .toList(),
      soloWorkoutRewards: entity.soloWorkoutRewards
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
  final int personalReward;
  final int contributionReward;
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
    required this.personalReward,
    required this.contributionReward,
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
      personalReward: data['personalReward'] as int? ?? 0,
      contributionReward: data['contributionReward'] as int? ?? 0,
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
      'personalReward': personalReward,
      'contributionReward': contributionReward,
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
      personalReward: personalReward,
      contributionReward: contributionReward,
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
      personalReward: entity.personalReward,
      contributionReward: entity.contributionReward,
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


