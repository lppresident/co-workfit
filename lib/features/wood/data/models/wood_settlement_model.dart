import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';

/// WoodSettlementEntity의 Firestore 데이터 모델
class WoodSettlementModel extends WoodSettlementEntity {
  const WoodSettlementModel({
    required super.settlementDate,
    required super.settledAt,
    super.selectedChallengeId,
    required super.totalWoodAwarded,
    required super.challenges,
    super.expiredChallenges,
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

    // 만료 챌린지 파싱
    final expiredData = data['expiredChallenges'] as List<dynamic>? ?? [];
    final expiredChallenges = expiredData
        .map((e) => ExpiredChallengeInfoModel.fromMap(e as Map<String, dynamic>))
        .toList();

    return WoodSettlementModel(
      settlementDate: docId,
      settledAt: (data['settledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      selectedChallengeId: data['selectedChallengeId'] as String?,
      totalWoodAwarded: (data['totalWoodAwarded'] as num?)?.toInt() ?? 0,
      challenges: challenges,
      expiredChallenges: expiredChallenges,
    );
  }

  /// Entity에서 생성
  factory WoodSettlementModel.fromEntity(WoodSettlementEntity entity) {
    return WoodSettlementModel(
      settlementDate: entity.settlementDate,
      settledAt: entity.settledAt,
      selectedChallengeId: entity.selectedChallengeId,
      totalWoodAwarded: entity.totalWoodAwarded,
      challenges: entity.challenges,
      expiredChallenges: entity.expiredChallenges,
    );
  }

  /// Firestore 저장용 Map
  Map<String, dynamic> toFirestore() {
    return {
      'settledAt': Timestamp.fromDate(settledAt),
      'selectedChallengeId': selectedChallengeId,
      'totalWoodAwarded': totalWoodAwarded,
      'challenges': challenges
          .map((c) => ChallengeRewardDetailModel.fromDetail(c).toMap())
          .toList(),
      'expiredChallenges': expiredChallenges
          .map((e) => ExpiredChallengeInfoModel.fromInfo(e).toMap())
          .toList(),
    };
  }
}

/// ChallengeRewardDetail의 데이터 모델
class ChallengeRewardDetailModel extends ChallengeRewardDetail {
  const ChallengeRewardDetailModel({
    required super.challengeId,
    required super.challengeName,
    required super.isSuccess,
    required super.personalReward,
    required super.contributionReward,
    required super.successBonus,
    required super.total,
    required super.selected,
    super.isMvp,
    super.milestoneType,
  });

  factory ChallengeRewardDetailModel.fromMap(Map<String, dynamic> data) {
    return ChallengeRewardDetailModel(
      challengeId: data['challengeId'] as String? ?? '',
      challengeName: data['challengeName'] as String? ?? '',
      isSuccess: data['isSuccess'] as bool? ?? false,
      personalReward: (data['personalReward'] as num?)?.toInt() ?? 0,
      contributionReward: (data['contributionReward'] as num?)?.toInt() ?? 0,
      successBonus: (data['successBonus'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      selected: data['selected'] as bool? ?? false,
      isMvp: data['isMvp'] as bool? ?? false,
      milestoneType: data['milestoneType'] as String?,
    );
  }

  factory ChallengeRewardDetailModel.fromDetail(ChallengeRewardDetail detail) {
    return ChallengeRewardDetailModel(
      challengeId: detail.challengeId,
      challengeName: detail.challengeName,
      isSuccess: detail.isSuccess,
      personalReward: detail.personalReward,
      contributionReward: detail.contributionReward,
      successBonus: detail.successBonus,
      total: detail.total,
      selected: detail.selected,
      isMvp: detail.isMvp,
      milestoneType: detail.milestoneType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'challengeName': challengeName,
      'isSuccess': isSuccess,
      'personalReward': personalReward,
      'contributionReward': contributionReward,
      'successBonus': successBonus,
      'total': total,
      'selected': selected,
      'isMvp': isMvp,
      'milestoneType': milestoneType,
    };
  }
}

/// ExpiredChallengeInfo의 데이터 모델
class ExpiredChallengeInfoModel extends ExpiredChallengeInfo {
  const ExpiredChallengeInfoModel({
    required super.challengeId,
    required super.challengeName,
    required super.endDate,
    required super.estimatedReward,
  });

  factory ExpiredChallengeInfoModel.fromMap(Map<String, dynamic> data) {
    return ExpiredChallengeInfoModel(
      challengeId: data['challengeId'] as String? ?? '',
      challengeName: data['challengeName'] as String? ?? '',
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedReward: (data['estimatedReward'] as num?)?.toInt() ?? 0,
    );
  }

  factory ExpiredChallengeInfoModel.fromInfo(ExpiredChallengeInfo info) {
    return ExpiredChallengeInfoModel(
      challengeId: info.challengeId,
      challengeName: info.challengeName,
      endDate: info.endDate,
      estimatedReward: info.estimatedReward,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'challengeName': challengeName,
      'endDate': Timestamp.fromDate(endDate),
      'estimatedReward': estimatedReward,
    };
  }
}

