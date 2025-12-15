import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/social/domain/entities/friendship_entity.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';

class GetFriends {
  final SocialRepository repository;

  GetFriends(this.repository);

  Future<Either<Failure, List<FriendshipEntity>>> call(String userId) async {
    return await repository.getFriends(userId);
  }
}
