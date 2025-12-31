import 'package:co_workfit/features/wood/domain/entities/wood_reward_constants.dart';

/// 개인 운동 보상 계산 UseCase
///
/// 보상 체계:
/// - 기본: 5개
/// - 거리: 거리(km) × 2
/// - 일일 첫 운동: +3개
class CalculatePersonalReward {
  /// 개인 운동 보상 계산
  ///
  /// [distanceKm] 운동 거리 (km)
  /// [isFirstWorkoutOfDay] 해당 날짜의 첫 운동인지 여부
  PersonalRewardResult call({
    required double distanceKm,
    required bool isFirstWorkoutOfDay,
  }) {
    // 기본 보상
    final baseReward = WoodRewardConstants.personalBase;

    // 거리 보상
    final distanceReward = (distanceKm * WoodRewardConstants.personalPerKm).round();

    // 일일 첫 운동 보너스
    final firstWorkoutBonus =
        isFirstWorkoutOfDay ? WoodRewardConstants.dailyFirstWorkoutBonus : 0;

    // 총 보상
    final total = baseReward + distanceReward + firstWorkoutBonus;

    return PersonalRewardResult(
      baseReward: baseReward,
      distanceReward: distanceReward,
      firstWorkoutBonus: firstWorkoutBonus,
      total: total,
    );
  }
}

/// 개인 운동 보상 결과
class PersonalRewardResult {
  /// 기본 보상
  final int baseReward;

  /// 거리 보상
  final int distanceReward;

  /// 일일 첫 운동 보너스
  final int firstWorkoutBonus;

  /// 총 보상
  final int total;

  const PersonalRewardResult({
    required this.baseReward,
    required this.distanceReward,
    required this.firstWorkoutBonus,
    required this.total,
  });

  @override
  String toString() {
    return 'PersonalReward(base: $baseReward, distance: $distanceReward, '
        'firstBonus: $firstWorkoutBonus, total: $total)';
  }
}

