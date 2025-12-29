import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';

class RemoveFriend {
  final SocialRepository repository;

  RemoveFriend(this.repository);

  Future<Either<Failure, void>> call({
    required String userId,
    required String friendId,
  }) async {
    return await repository.removeFriend(
      userId: userId,
      friendId: friendId,
    );
  }
}
