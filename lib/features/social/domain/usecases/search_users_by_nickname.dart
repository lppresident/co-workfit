import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';

class SearchUsersByNickname {
  final SocialRepository repository;

  SearchUsersByNickname(this.repository);

  Future<Either<Failure, List<UserEntity>>> call(String nickname) async {
    return await repository.searchUsersByNickname(nickname);
  }
}
