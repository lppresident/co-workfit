import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_summary_entity.dart';
import 'package:co_workfit/features/currency/domain/entities/settlement_entity.dart';

/// 재화 상태
abstract class CurrencyState extends Equatable {
  const CurrencyState();

  @override
  List<Object?> get props => [];
}

/// 초기 상태
class CurrencyInitial extends CurrencyState {
  const CurrencyInitial();
}

/// 로딩 중
class CurrencyLoading extends CurrencyState {
  const CurrencyLoading();
}

/// 재화 로드 완료
class CurrencyLoaded extends CurrencyState {
  /// 재화 보유 현황
  final CurrencySummaryEntity summary;

  /// 새로 정산된 보상 (다이얼로그 표시용)
  final List<SettlementEntity>? newSettlements;

  /// 정산 기록
  final List<SettlementEntity> settlementHistory;

  const CurrencyLoaded({
    required this.summary,
    this.newSettlements,
    this.settlementHistory = const [],
  });

  /// 특정 재화 보유량
  int getAmount(CurrencyType type) => summary.getAmount(type);

  /// 특정 재화 누적 획득량
  int getLifetimeEarned(CurrencyType type) => summary.getLifetimeEarned(type);

  /// 새 정산이 있는지 확인
  bool get hasNewSettlements =>
      newSettlements != null && newSettlements!.isNotEmpty;

  /// 새 정산의 총 보상
  Map<CurrencyType, int> get newRewardsTotal {
    if (newSettlements == null) return {};

    final totals = <CurrencyType, int>{};
    for (final settlement in newSettlements!) {
      for (final type in CurrencyType.values) {
        totals[type] = (totals[type] ?? 0) + settlement.getReward(type);
      }
    }
    return totals;
  }

  /// 정산 다이얼로그 닫기
  CurrencyLoaded dismissSettlements() {
    return CurrencyLoaded(
      summary: summary,
      newSettlements: null,
      settlementHistory: settlementHistory,
    );
  }

  /// 정산 기록 업데이트
  CurrencyLoaded withHistory(List<SettlementEntity> history) {
    return CurrencyLoaded(
      summary: summary,
      newSettlements: newSettlements,
      settlementHistory: history,
    );
  }

  @override
  List<Object?> get props => [summary, newSettlements, settlementHistory];
}

/// 에러 상태
class CurrencyError extends CurrencyState {
  final String message;

  const CurrencyError(this.message);

  @override
  List<Object?> get props => [message];
}


