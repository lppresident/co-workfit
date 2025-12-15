import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';

class AcceptFriendRequest {
  final SocialRepository repository;

  AcceptFriendRequest(this.repository);

  Future<Either<Failure, void>> call(String requestId) async {
    return await repository.acceptFriendRequest(requestId);
  }
}
