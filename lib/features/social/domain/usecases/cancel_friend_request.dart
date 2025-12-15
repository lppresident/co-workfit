import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';

class CancelFriendRequest {
  final SocialRepository repository;

  CancelFriendRequest(this.repository);

  Future<Either<Failure, void>> call(String requestId) async {
    return await repository.cancelFriendRequest(requestId);
  }
}
