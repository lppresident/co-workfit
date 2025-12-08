import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/auth/domain/repositories/auth_repository.dart';

/// 로그아웃하는 Use Case
class SignOut {
  final AuthRepository _repository;

  SignOut(this._repository);

  Future<Either<String, void>> call() async {
    return await _repository.signOut();
  }
}
