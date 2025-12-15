import 'package:bloc/bloc.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/profile/domain/usecases/get_profile_data.dart';
import 'package:co_workfit/features/profile/domain/usecases/logout_user.dart';
import 'package:co_workfit/features/profile/domain/usecases/update_display_name.dart' as usecases;

import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileData _getProfileDataUseCase;
  final usecases.UpdateDisplayName _updateDisplayNameUseCase;
  final LogoutUser _logoutUserUseCase;

  ProfileBloc({
    required GetProfileData getProfileData,
    required usecases.UpdateDisplayName updateDisplayName,
    required LogoutUser logoutUser,
  })  : _getProfileDataUseCase = getProfileData,
        _updateDisplayNameUseCase = updateDisplayName,
        _logoutUserUseCase = logoutUser,
        super(ProfileInitial()) {
    on<FetchProfileData>(_onFetchProfileData);
    on<UpdateDisplayName>(_onUpdateDisplayName);
    on<LogoutButtonPressed>(_onLogoutButtonPressed);
  }

  Future<void> _onFetchProfileData(
    FetchProfileData event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await _getProfileDataUseCase.call();
    result.fold(
      (failure) => emit(ProfileLoadFailure(_mapFailureToMessage(failure))),
      (user) => emit(ProfileLoadSuccess(user)),
    );
  }

  Future<void> _onUpdateDisplayName(
    UpdateDisplayName event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoadSuccess) {
      emit(ProfileLoading());
    }

    final result = await _updateDisplayNameUseCase.call(event.newDisplayName);
    result.fold(
      (failure) => emit(ProfileLoadFailure(_mapFailureToMessage(failure))),
      (_) async {
        final refetchResult = await _getProfileDataUseCase.call();
        refetchResult.fold(
          (failure) => emit(ProfileLoadFailure(_mapFailureToMessage(failure))),
          (user) => emit(ProfileLoadSuccess(user)),
        );
      },
    );
  }

  Future<void> _onLogoutButtonPressed(
    LogoutButtonPressed event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await _logoutUserUseCase.call();
    result.fold(
      (failure) => emit(ProfileLoadFailure(_mapFailureToMessage(failure))),
      (_) => emit(ProfileInitial()),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Server Error: ${failure.message}';
    } else if (failure is CacheFailure) {
      return 'Cache Error: ${failure.message}';
    } else if (failure is AuthFailure) {
      return 'Authentication Error: ${failure.message}';
    }
    return 'Unexpected Error';
  }
}

