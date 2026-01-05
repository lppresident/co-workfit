import 'package:equatable/equatable.dart';

/// 재화 관련 이벤트
abstract class CurrencyEvent extends Equatable {
  const CurrencyEvent();

  @override
  List<Object?> get props => [];
}

/// 재화 보유 현황 조회
class LoadCurrencySummaryEvent extends CurrencyEvent {
  const LoadCurrencySummaryEvent();
}

/// 미정산 보상 확인 및 정산
class CheckPendingSettlementsEvent extends CurrencyEvent {
  const CheckPendingSettlementsEvent();
}

/// 정산 기록 조회
class LoadSettlementHistoryEvent extends CurrencyEvent {
  final int limit;

  const LoadSettlementHistoryEvent({this.limit = 7});

  @override
  List<Object?> get props => [limit];
}

/// 정산 다이얼로그 닫기
class DismissSettlementDialogEvent extends CurrencyEvent {
  const DismissSettlementDialogEvent();
}


