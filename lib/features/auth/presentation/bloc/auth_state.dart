import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';

/// Auth 상태
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// 초기 상태
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// 로딩 중
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// 인증됨 (로그인 성공)
class Authenticated extends AuthState {
  final UserEntity user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// 인증되지 않음 (로그아웃 상태)
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// 에러 상태
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 닉네임 확인 결과
class NicknameAvailabilityChecked extends AuthState {
  final bool isAvailable;
  final String nickname;

  const NicknameAvailabilityChecked({
    required this.isAvailable,
    required this.nickname,
  });

  @override
  List<Object?> get props => [isAvailable, nickname];
}

/// 닉네임 업데이트 성공
class NicknameUpdated extends AuthState {
  final UserEntity user;

  const NicknameUpdated(this.user);

  @override
  List<Object?> get props => [user];
}
