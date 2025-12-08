import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/auth/domain/usecases/get_current_user.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_out.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:co_workfit/features/auth/domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser _getCurrentUser;
  final SignInWithEmail _signInWithEmail;
  final SignUpWithEmail _signUpWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final SignOut _signOut;
  final AuthRepository _authRepository;

  StreamSubscription? _authStateSubscription;

  AuthBloc({
    required GetCurrentUser getCurrentUser,
    required SignInWithEmail signInWithEmail,
    required SignUpWithEmail signUpWithEmail,
    required SignInWithGoogle signInWithGoogle,
    required SignOut signOut,
    required AuthRepository authRepository,
  })  : _getCurrentUser = getCurrentUser,
        _signInWithEmail = signInWithEmail,
        _signUpWithEmail = signUpWithEmail,
        _signInWithGoogle = signInWithGoogle,
        _signOut = signOut,
        _authRepository = authRepository,
        super(const AuthInitial()) {
    // 이벤트 핸들러 등록
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<SignUpWithEmailRequested>(_onSignUpWithEmailRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);

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

  /// 이메일/비밀번호로 로그인
  Future<void> _onSignInWithEmailRequested(
    SignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signInWithEmail(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (error) => emit(AuthError(error)),
      (user) => emit(Authenticated(user)),
    );
  }

  /// 이메일/비밀번호로 회원가입
  Future<void> _onSignUpWithEmailRequested(
    SignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _signUpWithEmail(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );

    result.fold(
      (error) => emit(AuthError(error)),
      (user) => emit(Authenticated(user)),
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

  /// 비밀번호 재설정 이메일 전송
  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.sendPasswordResetEmail(event.email);

    result.fold(
      (error) => emit(AuthError(error)),
      (_) => emit(const PasswordResetEmailSent()),
    );
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
