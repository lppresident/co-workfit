import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/auth/domain/repositories/auth_repository.dart';

/// 이메일/비밀번호로 회원가입하는 Use Case
class SignUpWithEmail {
  final AuthRepository _repository;

  SignUpWithEmail(this._repository);

  Future<Either<String, UserEntity>> call({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // 입력 검증
    if (email.isEmpty) {
      return const Left('이메일을 입력해주세요.');
    }
    if (password.isEmpty) {
      return const Left('비밀번호를 입력해주세요.');
    }
    if (password.length < 6) {
      return const Left('비밀번호는 최소 6자 이상이어야 합니다.');
    }
    if (displayName.isEmpty) {
      return const Left('닉네임을 입력해주세요.');
    }

    return await _repository.signUpWithEmailPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
