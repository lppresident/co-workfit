import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';

class SendFriendRequest {
  final SocialRepository repository;

  SendFriendRequest(this.repository);

  Future<Either<Failure, void>> call({
    required String senderId,
    required String receiverId,
  }) async {
    return await repository.sendFriendRequest(
      senderId: senderId,
      receiverId: receiverId,
    );
  }
}
