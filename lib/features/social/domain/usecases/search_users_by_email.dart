import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';

class SearchUsersByEmail {
  final SocialRepository repository;

  SearchUsersByEmail(this.repository);

  Future<Either<Failure, List<UserEntity>>> call(String email) async {
    return await repository.searchUsersByEmail(email);
  }
}
