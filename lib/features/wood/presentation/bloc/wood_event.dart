import 'package:equatable/equatable.dart';

/// Wood BLoC 이벤트
abstract class WoodEvent extends Equatable {
  const WoodEvent();

  @override
  List<Object?> get props => [];
}

/// 통나무 현황 조회
class LoadWoodSummary extends WoodEvent {
  const LoadWoodSummary();
}

/// 미정산 보상 확인 및 정산
class CheckPendingSettlementsEvent extends WoodEvent {
  const CheckPendingSettlementsEvent();
}

/// 정산 내역 조회
class LoadSettlementHistory extends WoodEvent {
  final int limit;

  const LoadSettlementHistory({this.limit = 30});

  @override
  List<Object?> get props => [limit];
}

/// 정산 다이얼로그 확인 (닫기)
class DismissSettlementDialog extends WoodEvent {
  const DismissSettlementDialog();
}

/// 통나무 사용 (제작 시)
class UseWood extends WoodEvent {
  final int amount;

  const UseWood({required this.amount});

  @override
  List<Object?> get props => [amount];
}

