import 'package:co_workfit/features/wood/domain/entities/wood_reward_constants.dart';

/// 챌린지 성공 보너스 계산 UseCase
///
/// 보상 체계 (성공 시만):
/// - 완료 보너스: 30개 (모든 참가자)
/// - MVP 보너스: +20개 (기여도 1위)
/// - 협력 보너스: 참가자 수 × 3 (최대 30개)
/// - 마일스톤:
///   - 10km 이상: +10개
///   - 21.0975km 이상 (하프): +30개
///   - 42.195km 이상 (풀): +50개
class CalculateSuccessBonus {
  /// 챌린지 성공 보너스 계산
  ///
  /// [isSuccess] 챌린지 성공 여부
  /// [isMvp] 사용자가 MVP인지 (기여도 1위)
  /// [participantCount] 참가자 수
  /// [targetDistanceKm] 목표 거리 (km)
  SuccessBonusResult call({
    required bool isSuccess,
    required bool isMvp,
    required int participantCount,
    required double targetDistanceKm,
  }) {
    // 실패 시 보너스 없음
    if (!isSuccess) {
      return const SuccessBonusResult(
        completionBonus: 0,
        mvpBonus: 0,
        cooperationBonus: 0,
        milestoneBonus: 0,
        milestoneType: null,
        total: 0,
      );
    }

    // 완료 보너스
    final completionBonus = WoodRewardConstants.completionBonus;

    // MVP 보너스
    final mvpBonus = isMvp ? WoodRewardConstants.mvpBonus : 0;

    // 협력 보너스 (참가자 수 × 3, 최대 30)
    final rawCooperationBonus =
        participantCount * WoodRewardConstants.cooperationPerParticipant;
    final cooperationBonus =
        rawCooperationBonus.clamp(0, WoodRewardConstants.maxCooperationBonus);

    // 마일스톤 보너스
    final milestone = MilestoneTypeExtension.fromDistance(targetDistanceKm);
    final milestoneBonus = milestone?.bonusAmount ?? 0;

    // 총 보너스
    final total = completionBonus + mvpBonus + cooperationBonus + milestoneBonus;

    return SuccessBonusResult(
      completionBonus: completionBonus,
      mvpBonus: mvpBonus,
      cooperationBonus: cooperationBonus,
      milestoneBonus: milestoneBonus,
      milestoneType: milestone,
      total: total,
    );
  }
}

/// 챌린지 성공 보너스 결과
class SuccessBonusResult {
  /// 완료 보너스
  final int completionBonus;

  /// MVP 보너스
  final int mvpBonus;

  /// 협력 보너스
  final int cooperationBonus;

  /// 마일스톤 보너스
  final int milestoneBonus;

  /// 마일스톤 타입
  final MilestoneType? milestoneType;

  /// 총 보너스
  final int total;

  const SuccessBonusResult({
    required this.completionBonus,
    required this.mvpBonus,
    required this.cooperationBonus,
    required this.milestoneBonus,
    required this.milestoneType,
    required this.total,
  });

  @override
  String toString() {
    return 'SuccessBonus(completion: $completionBonus, mvp: $mvpBonus, '
        'cooperation: $cooperationBonus, milestone: $milestoneBonus ($milestoneType), '
        'total: $total)';
  }
}

