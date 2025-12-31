import 'package:equatable/equatable.dart';

/// 사용자의 통나무 보유 현황 엔티티
///
/// Firestore: users/{userId}/wood_summary
class WoodSummaryEntity extends Equatable {
  /// 현재 보유 통나무 개수
  final int totalWood;

  /// 총 획득 통나무 개수 (누적)
  final int lifetimeEarned;

  /// 마지막 정산 날짜 (yyyy-MM-dd 형식)
  final String? lastSettlementDate;

  const WoodSummaryEntity({
    required this.totalWood,
    required this.lifetimeEarned,
    this.lastSettlementDate,
  });

  /// 초기 상태
  factory WoodSummaryEntity.initial() {
    return const WoodSummaryEntity(
      totalWood: 0,
      lifetimeEarned: 0,
      lastSettlementDate: null,
    );
  }

  /// 통나무 추가
  WoodSummaryEntity addWood(int amount) {
    return WoodSummaryEntity(
      totalWood: totalWood + amount,
      lifetimeEarned: lifetimeEarned + amount,
      lastSettlementDate: lastSettlementDate,
    );
  }

  /// 통나무 사용 (제작 등)
  WoodSummaryEntity useWood(int amount) {
    if (amount > totalWood) {
      throw Exception('통나무가 부족합니다. 보유: $totalWood, 필요: $amount');
    }
    return WoodSummaryEntity(
      totalWood: totalWood - amount,
      lifetimeEarned: lifetimeEarned,
      lastSettlementDate: lastSettlementDate,
    );
  }

  /// 정산 날짜 업데이트
  WoodSummaryEntity updateSettlementDate(String date) {
    return WoodSummaryEntity(
      totalWood: totalWood,
      lifetimeEarned: lifetimeEarned,
      lastSettlementDate: date,
    );
  }

  @override
  List<Object?> get props => [totalWood, lifetimeEarned, lastSettlementDate];
}

