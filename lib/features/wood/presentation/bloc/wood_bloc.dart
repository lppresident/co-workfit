import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/features/wood/domain/usecases/check_pending_settlements.dart';
import 'package:co_workfit/features/wood/domain/usecases/get_settlement_history.dart';
import 'package:co_workfit/features/wood/domain/usecases/get_wood_summary.dart';
import 'package:co_workfit/features/wood/domain/repositories/wood_repository.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_event.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_state.dart';

/// Wood BLoC
class WoodBloc extends Bloc<WoodEvent, WoodState> {
  final GetWoodSummary _getWoodSummary;
  final CheckPendingSettlements _checkPendingSettlements;
  final GetSettlementHistory _getSettlementHistory;
  final WoodRepository _repository;

  String? _currentUserId;

  WoodBloc({
    required GetWoodSummary getWoodSummary,
    required CheckPendingSettlements checkPendingSettlements,
    required GetSettlementHistory getSettlementHistory,
    required WoodRepository repository,
  })  : _getWoodSummary = getWoodSummary,
        _checkPendingSettlements = checkPendingSettlements,
        _getSettlementHistory = getSettlementHistory,
        _repository = repository,
        super(WoodState.initial()) {
    on<LoadWoodSummary>(_onLoadWoodSummary);
    on<CheckPendingSettlementsEvent>(_onCheckPendingSettlements);
    on<LoadSettlementHistory>(_onLoadSettlementHistory);
    on<DismissSettlementDialog>(_onDismissSettlementDialog);
    on<UseWood>(_onUseWood);
  }

  /// 사용자 ID 설정
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// 통나무 현황 조회
  Future<void> _onLoadWoodSummary(
    LoadWoodSummary event,
    Emitter<WoodState> emit,
  ) async {
    if (_currentUserId == null) {
      emit(state.copyWith(errorMessage: '로그인이 필요합니다'));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final summary = await _getWoodSummary(_currentUserId!);
      emit(state.copyWith(
        summary: summary,
        isLoading: false,
      ));
    } catch (e) {
      AppLogger.error('WoodBloc', '통나무 현황 조회 실패', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '통나무 현황을 불러오는데 실패했습니다',
      ));
    }
  }

  /// 미정산 보상 확인 및 정산
  Future<void> _onCheckPendingSettlements(
    CheckPendingSettlementsEvent event,
    Emitter<WoodState> emit,
  ) async {
    if (_currentUserId == null) {
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final settlements = await _checkPendingSettlements(_currentUserId!);
      final summary = SettlementSummary.fromSettlements(settlements);

      // 정산 후 현황 갱신
      final updatedSummary = await _getWoodSummary(_currentUserId!);

      emit(state.copyWith(
        summary: updatedSummary,
        pendingSettlementResult: summary.hasSettlements ? summary : null,
        isLoading: false,
      ));

      if (summary.hasSettlements) {
        AppLogger.info(
          'WoodBloc',
          '정산 완료: ${summary.settledDays}일, ${summary.totalWoodAwarded}개 획득',
        );
      }
    } catch (e) {
      AppLogger.error('WoodBloc', '정산 실패', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '정산 처리 중 오류가 발생했습니다',
      ));
    }
  }

  /// 정산 내역 조회
  Future<void> _onLoadSettlementHistory(
    LoadSettlementHistory event,
    Emitter<WoodState> emit,
  ) async {
    if (_currentUserId == null) {
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final settlements = await _getSettlementHistory(
        _currentUserId!,
        limit: event.limit,
      );
      emit(state.copyWith(
        settlements: settlements,
        isLoading: false,
      ));
    } catch (e) {
      AppLogger.error('WoodBloc', '정산 내역 조회 실패', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '정산 내역을 불러오는데 실패했습니다',
      ));
    }
  }

  /// 정산 다이얼로그 닫기
  void _onDismissSettlementDialog(
    DismissSettlementDialog event,
    Emitter<WoodState> emit,
  ) {
    emit(state.copyWith(clearPendingResult: true));
  }

  /// 통나무 사용
  Future<void> _onUseWood(
    UseWood event,
    Emitter<WoodState> emit,
  ) async {
    if (_currentUserId == null) {
      emit(state.copyWith(errorMessage: '로그인이 필요합니다'));
      return;
    }

    if (state.totalWood < event.amount) {
      emit(state.copyWith(errorMessage: '통나무가 부족합니다'));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _repository.useWood(_currentUserId!, event.amount);
      final updatedSummary = await _getWoodSummary(_currentUserId!);
      emit(state.copyWith(
        summary: updatedSummary,
        isLoading: false,
      ));
    } catch (e) {
      AppLogger.error('WoodBloc', '통나무 사용 실패', e);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '통나무 사용에 실패했습니다',
      ));
    }
  }
}

