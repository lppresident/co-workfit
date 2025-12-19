import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/auth/domain/usecases/check_nickname_availability.dart';
import 'nickname_event.dart';
import 'nickname_state.dart';

/// 닉네임 관련 BLoC
class NicknameBloc extends Bloc<NicknameEvent, NicknameState> {
  final CheckNicknameAvailability _checkNicknameAvailability;

  NicknameBloc({
    required CheckNicknameAvailability checkNicknameAvailability,
  })  : _checkNicknameAvailability = checkNicknameAvailability,
        super(const NicknameInitial()) {
    on<CheckNicknameAvailabilityRequested>(_onCheckNicknameAvailabilityRequested);
    on<ResetNicknameCheck>(_onResetNicknameCheck);
  }

  /// 닉네임 사용 가능 여부 확인
  Future<void> _onCheckNicknameAvailabilityRequested(
    CheckNicknameAvailabilityRequested event,
    Emitter<NicknameState> emit,
  ) async {
    emit(const NicknameCheckingAvailability());

    final result = await _checkNicknameAvailability(event.nickname);

    result.fold(
      (error) => emit(NicknameCheckError(error)),
      (isAvailable) => emit(NicknameAvailabilityChecked(
        isAvailable: isAvailable,
        nickname: event.nickname,
      )),
    );
  }

  /// 닉네임 중복 확인 상태 초기화
  Future<void> _onResetNicknameCheck(
    ResetNicknameCheck event,
    Emitter<NicknameState> emit,
  ) async {
    emit(const NicknameInitial());
  }
}
