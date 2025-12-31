import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';

/// WoodSettlementEntity의 Firestore 데이터 모델
class WoodSettlementModel extends WoodSettlementEntity {
  const WoodSettlementModel({
    required super.settlementDate,
    required super.settledAt,
    super.selectedChallengeId,
    super.selectedIronChallengeId,
    required super.totalWoodAwarded,
    super.totalIronAwarded,
    required super.challenges,
    super.hasSoloWoodReward,
    super.hasSoloIronReward,
  });

  /// Firestore 문서에서 생성
  factory WoodSettlementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WoodSettlementModel.fromMap(data, doc.id);
  }

  /// Map에서 생성
  factory WoodSettlementModel.fromMap(Map<String, dynamic> data, String docId) {
    // 챌린지 상세 파싱
    final challengesData = data['challenges'] as List<dynamic>? ?? [];
    final challenges = challengesData
        .map((c) => ChallengeRewardDetailModel.fromMap(c as Map<String, dynamic>))
        .toList();

    return WoodSettlementModel(
      settlementDate: docId,
      settledAt: (data['settledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      selectedChallengeId: data['selectedChallengeId'] as String?,
      selectedIronChallengeId: data['selectedIronChallengeId'] as String?,
      totalWoodAwarded: (data['totalWoodAwarded'] as num?)?.toInt() ?? 0,
      totalIronAwarded: (data['totalIronAwarded'] as num?)?.toInt() ?? 0,
      challenges: challenges,
      hasSoloWoodReward: data['hasSoloWoodReward'] as bool? ?? false,
      hasSoloIronReward: data['hasSoloIronReward'] as bool? ?? false,
    );
  }

  /// Entity에서 생성
  factory WoodSettlementModel.fromEntity(WoodSettlementEntity entity) {
    return WoodSettlementModel(
      settlementDate: entity.settlementDate,
      settledAt: entity.settledAt,
      selectedChallengeId: entity.selectedChallengeId,
      selectedIronChallengeId: entity.selectedIronChallengeId,
      totalWoodAwarded: entity.totalWoodAwarded,
      totalIronAwarded: entity.totalIronAwarded,
      challenges: entity.challenges,
      hasSoloWoodReward: entity.hasSoloWoodReward,
      hasSoloIronReward: entity.hasSoloIronReward,
    );
  }

  /// Firestore 저장용 Map
  Map<String, dynamic> toFirestore() {
    return {
      'settledAt': Timestamp.fromDate(settledAt),
      'selectedChallengeId': selectedChallengeId,
      'selectedIronChallengeId': selectedIronChallengeId,
      'totalWoodAwarded': totalWoodAwarded,
      'totalIronAwarded': totalIronAwarded,
      'challenges': challenges
          .map((c) => ChallengeRewardDetailModel.fromDetail(c).toMap())
          .toList(),
      'hasSoloWoodReward': hasSoloWoodReward,
      'hasSoloIronReward': hasSoloIronReward,
    };
  }
}

/// ChallengeRewardDetail의 데이터 모델
class ChallengeRewardDetailModel extends ChallengeRewardDetail {
  const ChallengeRewardDetailModel({
    required super.challengeId,
    required super.challengeName,
    super.currencyType,
    required super.isSuccess,
    required super.personalReward,
    required super.contributionReward,
    required super.successBonus,
    required super.total,
    required super.selected,
    super.isMvp,
    super.milestoneType,
    super.isSoloWorkout,
  });

  factory ChallengeRewardDetailModel.fromMap(Map<String, dynamic> data) {
    // currencyType 파싱
    final currencyTypeStr = data['currencyType'] as String? ?? 'wood';
    final currencyType = currencyTypeStr == 'iron' 
        ? RewardCurrencyType.iron 
        : RewardCurrencyType.wood;
    
    return ChallengeRewardDetailModel(
      challengeId: data['challengeId'] as String? ?? '',
      challengeName: data['challengeName'] as String? ?? '',
      currencyType: currencyType,
      isSuccess: data['isSuccess'] as bool? ?? false,
      personalReward: (data['personalReward'] as num?)?.toInt() ?? 0,
      contributionReward: (data['contributionReward'] as num?)?.toInt() ?? 0,
      successBonus: (data['successBonus'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      selected: data['selected'] as bool? ?? false,
      isMvp: data['isMvp'] as bool? ?? false,
      milestoneType: data['milestoneType'] as String?,
      isSoloWorkout: data['isSoloWorkout'] as bool? ?? false,
    );
  }

  factory ChallengeRewardDetailModel.fromDetail(ChallengeRewardDetail detail) {
    return ChallengeRewardDetailModel(
      challengeId: detail.challengeId,
      challengeName: detail.challengeName,
      currencyType: detail.currencyType,
      isSuccess: detail.isSuccess,
      personalReward: detail.personalReward,
      contributionReward: detail.contributionReward,
      successBonus: detail.successBonus,
      total: detail.total,
      selected: detail.selected,
      isMvp: detail.isMvp,
      milestoneType: detail.milestoneType,
      isSoloWorkout: detail.isSoloWorkout,
    );
  }

  Map<String, dynamic> toMap() {
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
      'milestoneType': milestoneType,
      'isSoloWorkout': isSoloWorkout,
    };
  }
}
