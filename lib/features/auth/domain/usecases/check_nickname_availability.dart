import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/auth/domain/repositories/auth_repository.dart';

/// 닉네임 사용 가능 여부 확인 UseCase
class CheckNicknameAvailability {
  final AuthRepository _repository;

  CheckNicknameAvailability(this._repository);

  /// 닉네임이 사용 가능한지 확인
  ///
  /// [nickname] 확인할 닉네임
  ///
  /// Returns:
  /// - Right(true): 사용 가능한 닉네임
  /// - Right(false): 이미 사용 중인 닉네임
  /// - Left(String): 에러 메시지
  Future<Either<String, bool>> call(String nickname) async {
    // 닉네임 유효성 검사
    final validationError = _validateNickname(nickname);
    if (validationError != null) {
      return Left(validationError);
    }

    return await _repository.checkNicknameAvailability(nickname);
  }

  /// 닉네임 유효성 검사
  String? _validateNickname(String nickname) {
    // 길이 검사 (2-20자)
    if (nickname.length < 2) {
      return '닉네임은 2자 이상이어야 합니다.';
    }
    if (nickname.length > 20) {
      return '닉네임은 20자 이하여야 합니다.';
    }

    // 허용 문자 검사: 한글, 영문, 숫자, 언더스코어, 하이픈만 허용
    final RegExp validCharacters = RegExp(r'^[가-힣a-zA-Z0-9_-]+$');
    if (!validCharacters.hasMatch(nickname)) {
      return '닉네임은 한글, 영문, 숫자, 언더스코어(_), 하이픈(-)만 사용할 수 있습니다.';
    }

    // 공백 확인
    if (nickname.contains(' ')) {
      return '닉네임에 공백을 포함할 수 없습니다.';
    }

    return null;
  }
}
