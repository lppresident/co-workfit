import 'package:equatable/equatable.dart';

/// 일일 정산 기록 엔티티
///
/// Firestore: users/{userId}/wood_settlements/{settlementDate}
/// 최근 7일치만 보관, 0개 정산은 저장하지 않음
class WoodSettlementEntity extends Equatable {
  /// 정산 대상 날짜 (챌린지 종료일, yyyy-MM-dd 형식)
  final String settlementDate;

  /// 정산 실행 시각
  final DateTime settledAt;

  /// 선택된 챌린지 ID (가장 높은 보상)
  final String? selectedChallengeId;

  /// 총 획득 통나무 개수
  final int totalWoodAwarded;

  /// 챌린지별 보상 상세
  final List<ChallengeRewardDetail> challenges;

  const WoodSettlementEntity({
    required this.settlementDate,
    required this.settledAt,
    this.selectedChallengeId,
    required this.totalWoodAwarded,
    required this.challenges,
  });

  /// 선택된 챌린지 상세 정보
  ChallengeRewardDetail? get selectedChallenge {
    if (selectedChallengeId == null || challenges.isEmpty) return null;
    try {
      return challenges.firstWhere(
        (c) => c.challengeId == selectedChallengeId,
      );
    } catch (_) {
      return challenges.isNotEmpty ? challenges.first : null;
    }
  }

  /// 포기된 챌린지 목록 (선택되지 않은 것들)
  List<ChallengeRewardDetail> get forsakenChallenges {
    return challenges.where((c) => !c.selected).toList();
  }

  @override
  List<Object?> get props => [
        settlementDate,
        settledAt,
        selectedChallengeId,
        totalWoodAwarded,
        challenges,
      ];
}

/// 챌린지별 보상 상세
class ChallengeRewardDetail extends Equatable {
  /// 챌린지 ID
  final String challengeId;

  /// 챌린지 이름 (목표 거리 기반)
  final String challengeName;

  /// 챌린지 성공 여부
  final bool isSuccess;

  /// 개인 운동 보상
  final int personalReward;

  /// 챌린지 기여 보상
  final int contributionReward;

  /// 성공 보너스 (완료, MVP, 협력, 마일스톤 포함)
  final int successBonus;

  /// 총 보상
  final int total;

  /// 선택 여부 (이 챌린지가 정산에 선택되었는지)
  final bool selected;

  /// MVP 여부
  final bool isMvp;

  /// 마일스톤 타입 (null, 'half', 'full')
  final String? milestoneType;

  const ChallengeRewardDetail({
    required this.challengeId,
    required this.challengeName,
    required this.isSuccess,
    required this.personalReward,
    required this.contributionReward,
    required this.successBonus,
    required this.total,
    required this.selected,
    this.isMvp = false,
    this.milestoneType,
  });

  @override
  List<Object?> get props => [
        challengeId,
        challengeName,
        isSuccess,
        personalReward,
        contributionReward,
        successBonus,
        total,
        selected,
        isMvp,
        milestoneType,
      ];
}
