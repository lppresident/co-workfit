import 'package:bloc/bloc.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/profile/domain/usecases/get_profile_data.dart';
import 'package:co_workfit/features/profile/domain/usecases/logout_user.dart';
import 'package:co_workfit/features/profile/domain/usecases/update_display_name.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileData getProfileData;
  final UpdateDisplayName updateDisplayName;
  final LogoutUser logoutUser;

  ProfileBloc({
    required this.getProfileData,
    required this.updateDisplayName,
    required this.logoutUser,
  }) : super(ProfileInitial()) {
    on<FetchProfileData>(_onFetchProfileData);
    on<UpdateDisplayName>(_onUpdateDisplayName);
    on<LogoutButtonPressed>(_onLogoutButtonPressed);
  }

  Future<void> _onFetchProfileData(
    FetchProfileData event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await getProfileData();
    result.fold(
      (failure) => emit(ProfileLoadFailure(_mapFailureToMessage(failure))),
      (user) => emit(ProfileLoadSuccess(user)),
    );
  }

  Future<void> _onUpdateDisplayName(
    UpdateDisplayName event,
    Emitter<ProfileState> emit,
  ) async {
    // Optionally emit a loading state or just update the current success state.
    // For simplicity, we'll refetch data after update to ensure consistency.
    // If there's a current success state, emit it to avoid unnecessary loading indicators.
    final currentState = state;
    if (currentState is ProfileLoadSuccess) {
      // Emit success state with current user to maintain UI responsiveness
      // and show an overlay or temporary message during update.
    } else {
      emit(ProfileLoading());
    }

    final result = await updateDisplayName(event.newDisplayName);
    await result.fold(
      (failure) => emit(ProfileLoadFailure(_mapFailureToMessage(failure))),
      (_) async {
        // After successful update, refetch profile data to update UI.
        final refetchResult = await getProfileData();
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
    emit(ProfileLoading()); // Can be a specific LogoutLoading state if needed
    final result = await logoutUser();
    await result.fold(
      (failure) => emit(ProfileLoadFailure(_mapFailureToMessage(failure))),
      (_) => emit(ProfileInitial()), // Or a specific LogoutSuccess state
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
