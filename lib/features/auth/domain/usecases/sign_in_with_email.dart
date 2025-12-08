import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/auth/domain/repositories/auth_repository.dart';

/// 이메일/비밀번호로 로그인하는 Use Case
class SignInWithEmail {
  final AuthRepository _repository;

  SignInWithEmail(this._repository);

  Future<Either<String, UserEntity>> call({
    required String email,
    required String password,
  }) async {
    // 입력 검증
    if (email.isEmpty) {
      return const Left('이메일을 입력해주세요.');
    }
    if (password.isEmpty) {
      return const Left('비밀번호를 입력해주세요.');
    }

    return await _repository.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }
}
