import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/social/domain/entities/friends_data_entity.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';

class GetFriendsData {
  final SocialRepository repository;

  GetFriendsData(this.repository);

  Future<Either<Failure, FriendsDataEntity>> call(String userId) async {
    return await repository.getFriendsData(userId);
  }
}
