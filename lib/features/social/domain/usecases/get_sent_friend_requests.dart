import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/social/domain/entities/friend_request_entity.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';

class GetSentFriendRequests {
  final SocialRepository repository;

  GetSentFriendRequests(this.repository);

  Future<Either<Failure, List<FriendRequestEntity>>> call(String userId) async {
    return await repository.getSentFriendRequests(userId);
  }
}
