import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/features/currency/domain/repositories/currency_repository.dart';
import 'package:co_workfit/features/currency/domain/usecases/check_pending_settlements.dart';
import 'package:co_workfit/features/currency/presentation/bloc/currency_event.dart';
import 'package:co_workfit/features/currency/presentation/bloc/currency_state.dart';

/// 통합 재화 BLoC
class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  final CurrencyRepository _repository;
  final CheckPendingSettlements _checkPendingSettlements;

  // TODO: AuthRepository에서 가져오도록 변경
  String _userId = 'current_user';

  CurrencyBloc({
    required CurrencyRepository repository,
    required CheckPendingSettlements checkPendingSettlements,
  })  : _repository = repository,
        _checkPendingSettlements = checkPendingSettlements,
        super(const CurrencyInitial()) {
    on<LoadCurrencySummaryEvent>(_onLoadCurrencySummary);
    on<CheckPendingSettlementsEvent>(_onCheckPendingSettlements);
    on<LoadSettlementHistoryEvent>(_onLoadSettlementHistory);
    on<DismissSettlementDialogEvent>(_onDismissSettlementDialog);
  }

  /// 사용자 ID 설정
  void setUserId(String userId) {
    _userId = userId;
  }

  Future<void> _onLoadCurrencySummary(
    LoadCurrencySummaryEvent event,
    Emitter<CurrencyState> emit,
  ) async {
    emit(const CurrencyLoading());

    try {
      final summary = await _repository.getCurrencySummary(_userId);

      emit(CurrencyLoaded(summary: summary));
      AppLogger.info('CurrencyBloc', 'Currency summary loaded');
    } catch (e) {
      AppLogger.error('CurrencyBloc', 'Failed to load currency summary', e);
      emit(CurrencyError('재화 정보를 불러오는데 실패했습니다: $e'));
    }
  }

  Future<void> _onCheckPendingSettlements(
    CheckPendingSettlementsEvent event,
    Emitter<CurrencyState> emit,
  ) async {
    // 현재 상태 유지하면서 정산 진행
    final currentState = state;

    try {
      // 미정산 보상 확인 및 정산
      final settlements = await _checkPendingSettlements(_userId);

      // 정산 후 최신 summary 조회
      final summary = await _repository.getCurrencySummary(_userId);

      if (settlements.isNotEmpty) {
        AppLogger.info(
          'CurrencyBloc',
          'Settled ${settlements.length} pending dates',
        );

        emit(CurrencyLoaded(
          summary: summary,
          newSettlements: settlements,
          settlementHistory: currentState is CurrencyLoaded
              ? currentState.settlementHistory
              : [],
        ));
      } else {
        emit(CurrencyLoaded(
          summary: summary,
          settlementHistory: currentState is CurrencyLoaded
              ? currentState.settlementHistory
              : [],
        ));
      }
    } catch (e) {
      AppLogger.error('CurrencyBloc', 'Failed to check pending settlements', e);
      // 에러 발생해도 기존 상태 유지
      if (currentState is CurrencyLoaded) {
        emit(currentState);
      } else {
        emit(CurrencyError('정산 확인 실패: $e'));
      }
    }
  }

  Future<void> _onLoadSettlementHistory(
    LoadSettlementHistoryEvent event,
    Emitter<CurrencyState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CurrencyLoaded) {
      return;
    }

    try {
      final history = await _repository.getSettlements(
        _userId,
        limit: event.limit,
      );

      emit(currentState.withHistory(history));
      AppLogger.info('CurrencyBloc', 'Settlement history loaded: ${history.length}');
    } catch (e) {
      AppLogger.error('CurrencyBloc', 'Failed to load settlement history', e);
    }
  }

  Future<void> _onDismissSettlementDialog(
    DismissSettlementDialogEvent event,
    Emitter<CurrencyState> emit,
  ) async {
    final currentState = state;
    if (currentState is CurrencyLoaded) {
      emit(currentState.dismissSettlements());
    }
  }
}


