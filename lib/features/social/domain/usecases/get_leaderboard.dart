import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';

class GetLeaderboard {
  final SocialRepository repository;

  GetLeaderboard(this.repository);

  Future<Either<Failure, List<LeaderboardEntryEntity>>> call({
    required LeaderboardType type,
    int limit = 50,
  }) async {
    return await repository.getLeaderboard(type: type, limit: limit);
  }
}
