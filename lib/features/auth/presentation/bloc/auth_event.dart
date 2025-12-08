import 'package:equatable/equatable.dart';

/// Auth 이벤트
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// 앱 시작 시 인증 상태 확인
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// 이메일/비밀번호로 로그인
class SignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// 이메일/비밀번호로 회원가입
class SignUpWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const SignUpWithEmailRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Google로 로그인
class SignInWithGoogleRequested extends AuthEvent {
  const SignInWithGoogleRequested();
}

/// 로그아웃
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

/// 비밀번호 재설정 이메일 전송
class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
