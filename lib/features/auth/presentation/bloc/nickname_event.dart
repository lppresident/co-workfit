import 'package:equatable/equatable.dart';

/// 닉네임 관련 이벤트
abstract class NicknameEvent extends Equatable {
  const NicknameEvent();

  @override
  List<Object?> get props => [];
}

/// 닉네임 사용 가능 여부 확인 요청
class CheckNicknameAvailabilityRequested extends NicknameEvent {
  final String nickname;

  const CheckNicknameAvailabilityRequested(this.nickname);

  @override
  List<Object?> get props => [nickname];
}

/// 닉네임 중복 확인 상태 초기화
class ResetNicknameCheck extends NicknameEvent {
  const ResetNicknameCheck();
}
