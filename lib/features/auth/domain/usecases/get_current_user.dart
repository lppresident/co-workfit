import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/auth/domain/repositories/auth_repository.dart';

/// 현재 로그인된 사용자를 가져오는 Use Case
class GetCurrentUser {
  final AuthRepository _repository;

  GetCurrentUser(this._repository);

  Future<Either<String, UserEntity?>> call() async {
    return await _repository.getCurrentUser();
  }
}
