import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';

class GetFriendsLeaderboard {
  final SocialRepository repository;

  GetFriendsLeaderboard(this.repository);

  Future<Either<Failure, List<LeaderboardEntryEntity>>> call({
    required String userId,
    required LeaderboardType type,
  }) async {
    return await repository.getFriendsLeaderboard(
      userId: userId,
      type: type,
    );
  }
}
