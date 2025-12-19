import 'package:equatable/equatable.dart';

/// 닉네임 관련 상태
abstract class NicknameState extends Equatable {
  const NicknameState();

  @override
  List<Object?> get props => [];
}

/// 초기 상태
class NicknameInitial extends NicknameState {
  const NicknameInitial();
}

/// 닉네임 중복 확인 중
class NicknameCheckingAvailability extends NicknameState {
  const NicknameCheckingAvailability();
}

/// 닉네임 사용 가능 여부 확인 완료
class NicknameAvailabilityChecked extends NicknameState {
  final bool isAvailable;
  final String nickname;

  const NicknameAvailabilityChecked({
    required this.isAvailable,
    required this.nickname,
  });

  @override
  List<Object?> get props => [isAvailable, nickname];
}

/// 닉네임 확인 중 에러 발생
class NicknameCheckError extends NicknameState {
  final String message;

  const NicknameCheckError(this.message);

  @override
  List<Object?> get props => [message];
}
