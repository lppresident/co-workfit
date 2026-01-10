import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/bloc/refresh_event.dart';
import 'package:co_workfit/core/bloc/refresh_state.dart';

/// 페이지 새로고침을 관리하는 가벼운 BLoC
///
/// 같은 탭을 다시 클릭했을 때 해당 페이지에 새로고침을 알림
class RefreshBloc extends Bloc<RefreshEvent, RefreshState> {
  RefreshBloc() : super(const RefreshInitial()) {
    on<RefreshPageRequested>(_onRefreshPageRequested);
  }

  void _onRefreshPageRequested(
    RefreshPageRequested event,
    Emitter<RefreshState> emit,
  ) {
    // 타임스탬프를 포함하여 매번 새로운 상태로 emit
    emit(RefreshTriggered(event.pageIndex, DateTime.now()));
  }
}
