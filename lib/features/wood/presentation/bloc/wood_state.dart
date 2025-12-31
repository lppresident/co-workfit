import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_summary_entity.dart';
import 'package:co_workfit/features/wood/domain/usecases/check_pending_settlements.dart';

/// Wood BLoC 상태
class WoodState extends Equatable {
  /// 통나무 보유 현황
  final WoodSummaryEntity? summary;

  /// 정산 내역 목록
  final List<WoodSettlementEntity> settlements;

  /// 새로운 정산 결과 (다이얼로그 표시용)
  final SettlementSummary? pendingSettlementResult;

  /// 로딩 상태
  final bool isLoading;

  /// 에러 메시지
  final String? errorMessage;

  const WoodState({
    this.summary,
    this.settlements = const [],
    this.pendingSettlementResult,
    this.isLoading = false,
    this.errorMessage,
  });

  /// 초기 상태
  factory WoodState.initial() {
    return const WoodState();
  }

  /// 현재 보유 통나무 개수
  int get totalWood => summary?.totalWood ?? 0;

  /// 총 획득 통나무 개수
  int get lifetimeEarned => summary?.lifetimeEarned ?? 0;

  /// 정산 다이얼로그 표시 여부
  bool get shouldShowSettlementDialog =>
      pendingSettlementResult != null &&
      pendingSettlementResult!.hasSettlements;

  WoodState copyWith({
    WoodSummaryEntity? summary,
    List<WoodSettlementEntity>? settlements,
    SettlementSummary? pendingSettlementResult,
    bool? clearPendingResult,
    bool? isLoading,
    String? errorMessage,
    bool? clearError,
  }) {
    return WoodState(
      summary: summary ?? this.summary,
      settlements: settlements ?? this.settlements,
      pendingSettlementResult: clearPendingResult == true
          ? null
          : (pendingSettlementResult ?? this.pendingSettlementResult),
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearError == true ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        summary,
        settlements,
        pendingSettlementResult,
        isLoading,
        errorMessage,
      ];
}

