import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';

class RejectFriendRequest {
  final SocialRepository repository;

  RejectFriendRequest(this.repository);

  Future<Either<Failure, void>> call(String requestId) async {
    return await repository.rejectFriendRequest(requestId);
  }
}
