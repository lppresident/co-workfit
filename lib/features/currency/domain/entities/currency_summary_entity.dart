import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';

/// 재화 보유 현황 엔티티
/// 
/// Firestore: users/{userId}
/// 모든 재화를 하나의 문서에서 관리
class CurrencySummaryEntity extends Equatable {
  /// 재화별 현재 보유량
  final Map<CurrencyType, int> amounts;
  
  /// 재화별 누적 획득량
  final Map<CurrencyType, int> lifetimeEarned;
  
  /// 마지막 정산 날짜 (모든 재화 통합)
  final DateTime? lastSettlementDate;

  const CurrencySummaryEntity({
    required this.amounts,
    required this.lifetimeEarned,
    this.lastSettlementDate,
  });
  
  /// 빈 상태 생성
  factory CurrencySummaryEntity.empty() {
    return CurrencySummaryEntity(
      amounts: {for (final type in CurrencyType.values) type: 0},
      lifetimeEarned: {for (final type in CurrencyType.values) type: 0},
    );
  }
  
  /// 특정 재화 보유량
  int getAmount(CurrencyType type) => amounts[type] ?? 0;
  
  /// 특정 재화 누적 획득량
  int getLifetimeEarned(CurrencyType type) => lifetimeEarned[type] ?? 0;
  
  /// 재화 추가
  CurrencySummaryEntity addCurrency(CurrencyType type, int amount) {
    final newAmounts = Map<CurrencyType, int>.from(amounts);
    final newLifetime = Map<CurrencyType, int>.from(lifetimeEarned);
    
    newAmounts[type] = (newAmounts[type] ?? 0) + amount;
    newLifetime[type] = (newLifetime[type] ?? 0) + amount;
    
    return CurrencySummaryEntity(
      amounts: newAmounts,
      lifetimeEarned: newLifetime,
      lastSettlementDate: lastSettlementDate,
    );
  }
  
  /// 재화 사용
  CurrencySummaryEntity useCurrency(CurrencyType type, int amount) {
    final currentAmount = amounts[type] ?? 0;
    if (currentAmount < amount) {
      throw Exception('${type.displayName} 부족: 보유 $currentAmount, 필요 $amount');
    }
    
    final newAmounts = Map<CurrencyType, int>.from(amounts);
    newAmounts[type] = currentAmount - amount;
    
    return CurrencySummaryEntity(
      amounts: newAmounts,
      lifetimeEarned: lifetimeEarned,
      lastSettlementDate: lastSettlementDate,
    );
  }
  
  /// 정산 날짜 업데이트
  CurrencySummaryEntity withSettlementDate(DateTime date) {
    return CurrencySummaryEntity(
      amounts: amounts,
      lifetimeEarned: lifetimeEarned,
      lastSettlementDate: date,
    );
  }

  @override
  List<Object?> get props => [amounts, lifetimeEarned, lastSettlementDate];
}


