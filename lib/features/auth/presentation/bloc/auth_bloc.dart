import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/auth/domain/usecases/get_current_user.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_out.dart';
import 'package:co_workfit/features/auth/domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser _getCurrentUser;
  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;
  final SignOut _signOut;
  final AuthRepository _authRepository;

  StreamSubscription? _authStateSubscription;

  AuthBloc({
    required GetCurrentUser getCurrentUser,
    required SignInWithGoogle signInWithGoogle,
    required SignInWithApple signInWithApple,
    required SignOut signOut,
    required AuthRepository authRepository,
  })  : _getCurrentUser = getCurrentUser,
        _signInWithGoogle = signInWithGoogle,
        _signInWithApple = signInWithApple,
        _signOut = signOut,
        _authRepository = authRepository,
        super(const AuthInitial()) {
    // 이벤트 핸들러 등록
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignInWithAppleRequested>(_onSignInWithAppleRequested);
    on<UpdateNicknameRequested>(_onUpdateNicknameRequested);
    on<SignOutRequested>(_onSignOutRequested);

    // Firebase Auth 상태 변경 리스너
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (firebaseUser) {
        if (firebaseUser != null) {
          add(const AuthCheckRequested());
        } else {
          emit(const Unauthenticated());
        }
      },
    );
  }

  /// 인증 상태 확인
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _getCurrentUser();

    result.fold(
      (error) => emit(AuthError(error)),
      (user) {
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const Unauthenticated());
        }
      },
    );
  }

  /// Google로 로그인
  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signInWithGoogle();

    result.fold(
      (error) => emit(AuthError(error)),
      (user) => emit(Authenticated(user)),
    );
  }

  /// Apple로 로그인
  Future<void> _onSignInWithAppleRequested(
    SignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signInWithApple();

    result.fold(
      (error) => emit(AuthError(error)),
      (user) => emit(Authenticated(user)),
    );
  }

  /// 닉네임 업데이트
  Future<void> _onUpdateNicknameRequested(
    UpdateNicknameRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.updateProfile(
      userId: event.userId,
      nickname: event.nickname,
    );

    result.fold(
      (error) => emit(AuthError(error)),
      (user) {
        // 닉네임 업데이트 성공 후 Authenticated 상태로 전환
        emit(Authenticated(user));
      },
    );
  }

  /// 로그아웃
  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signOut();

    result.fold(
      (error) => emit(AuthError(error)),
      (_) => emit(const Unauthenticated()),
    );
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
