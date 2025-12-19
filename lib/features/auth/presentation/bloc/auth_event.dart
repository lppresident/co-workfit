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

/// Google로 로그인
class SignInWithGoogleRequested extends AuthEvent {
  const SignInWithGoogleRequested();
}

/// Apple로 로그인
class SignInWithAppleRequested extends AuthEvent {
  const SignInWithAppleRequested();
}

/// 로그아웃
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
