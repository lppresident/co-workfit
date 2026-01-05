import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';

/// 일일 정산 기록 엔티티
///
/// Firestore: users/{userId}/settlements/{settlementDate}
/// 모든 재화 정산을 하나의 문서에서 관리
class SettlementEntity extends Equatable {
  /// 정산 대상 날짜 (yyyy-MM-dd 형식)
  final String settlementDate;

  /// 정산 실행 시각
  final DateTime settledAt;

  /// 재화별 획득량
  final Map<CurrencyType, int> rewards;

  /// 선택된 챌린지 ID (1개만)
  final String? selectedChallengeId;

  /// 챌린지별 보상 상세
  final List<ChallengeReward> challengeRewards;

  /// 운동별 보상 상세
  final List<SoloWorkoutReward> workoutRewards;

  const SettlementEntity({
    required this.settlementDate,
    required this.settledAt,
    required this.rewards,
    this.selectedChallengeId,
    required this.challengeRewards,
    required this.workoutRewards,
  });

  /// 특정 재화 획득량
  int getReward(CurrencyType type) => rewards[type] ?? 0;

  /// 총 획득량 (모든 재화 합계)
  int get totalRewards => rewards.values.fold(0, (sum, v) => sum + v);

  /// 보상이 있는지 확인
  bool get hasRewards => rewards.values.any((v) => v > 0);

  /// 선택된 챌린지
  ChallengeReward? get selectedChallenge {
    if (selectedChallengeId == null) return null;
    try {
      return challengeRewards.firstWhere((c) => c.challengeId == selectedChallengeId);
    } catch (_) {
      return null;
    }
  }

  /// 선택되지 않은 챌린지 목록
  List<ChallengeReward> get forsakenChallenges {
    return challengeRewards.where((c) => !c.selected).toList();
  }

  @override
  List<Object?> get props => [
        settlementDate,
        settledAt,
        rewards,
        selectedChallengeId,
        challengeRewards,
        workoutRewards,
      ];
}

/// 챌린지 보상 상세
class ChallengeReward extends Equatable {
  /// 챌린지 ID
  final String challengeId;

  /// 챌린지 이름
  final String challengeName;

  /// 보상 재화 타입
  final CurrencyType currencyType;

  /// 챌린지 성공 여부
  final bool isSuccess;

  /// 성공 보너스 (완료 + MVP + 협력 + 마일스톤)
  final int successBonus;

  /// 총 보상
  final int total;

  /// 선택 여부
  final bool selected;

  /// MVP 여부
  final bool isMvp;

  /// 마일스톤 이름
  final String? milestoneName;

  const ChallengeReward({
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

  @override
  List<Object?> get props => [
        challengeId,
        challengeName,
        currencyType,
        isSuccess,
        successBonus,
        total,
        selected,
        isMvp,
        milestoneName,
      ];
}

/// 개인 운동 보상 상세
class SoloWorkoutReward extends Equatable {
  /// 보상 재화 타입
  final CurrencyType currencyType;

  /// 운동 수치 (거리 km 또는 점수)
  final double value;

  /// 단위 표시 (km, 점)
  final String unit;

  /// 총 보상
  final int total;

  const SoloWorkoutReward({
    required this.currencyType,
    required this.value,
    required this.unit,
    required this.total,
  });

  /// 표시용 이름
  String get displayName {
    final valueStr = unit == 'km' 
        ? value.toStringAsFixed(1) 
        : value.toStringAsFixed(0);
    return '개인 운동 ($valueStr$unit)';
  }

  @override
  List<Object?> get props => [currencyType, value, unit, total];
}


