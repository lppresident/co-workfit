import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/auth/domain/repositories/auth_repository.dart';

/// Google로 로그인하는 Use Case
class SignInWithGoogle {
  final AuthRepository _repository;

  SignInWithGoogle(this._repository);

  Future<Either<String, UserEntity>> call() async {
    return await _repository.signInWithGoogle();
  }
}
