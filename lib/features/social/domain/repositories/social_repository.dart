import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/social/domain/entities/friend_request_entity.dart';
import 'package:co_workfit/features/social/domain/entities/friendship_entity.dart';
import 'package:co_workfit/features/social/domain/entities/friends_data_entity.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';

abstract class SocialRepository {
  // Friend Request Methods
  Future<Either<Failure, void>> sendFriendRequest({
    required String senderId,
    required String receiverId,
  });

  Future<Either<Failure, List<FriendRequestEntity>>> getReceivedFriendRequests(
    String userId,
  );

  Future<Either<Failure, List<FriendRequestEntity>>> getSentFriendRequests(
    String userId,
  );

  Future<Either<Failure, void>> acceptFriendRequest(String requestId);

  Future<Either<Failure, void>> rejectFriendRequest(String requestId);

  // Friend Management Methods
  /// 친구 데이터 통합 조회 (친구 목록 + 받은 요청)
  Future<Either<Failure, FriendsDataEntity>> getFriendsData(String userId);

  Future<Either<Failure, List<FriendshipEntity>>> getFriends(String userId);

  Future<Either<Failure, void>> removeFriend({
    required String userId,
    required String friendId,
  });

  // Leaderboard Methods
  Future<Either<Failure, List<LeaderboardEntryEntity>>> getLeaderboard({
    required LeaderboardType type,
    int limit = 50,
  });

  Future<Either<Failure, List<LeaderboardEntryEntity>>> getFriendsLeaderboard({
    required String userId,
    required LeaderboardType type,
  });

  // User Search
  Future<Either<Failure, List<UserEntity>>> searchUsersByNickname(String nickname);
}
