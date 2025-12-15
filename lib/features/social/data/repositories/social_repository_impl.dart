import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/auth/data/models/user_model.dart';
import 'package:co_workfit/features/social/domain/entities/friend_request_entity.dart';
import 'package:co_workfit/features/social/domain/entities/friendship_entity.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';
import 'package:co_workfit/features/social/data/datasources/firestore_social_datasource.dart';

class SocialRepositoryImpl implements SocialRepository {
  final FirestoreSocialDataSource dataSource;

  SocialRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, void>> sendFriendRequest({
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String receiverId,
  }) async {
    try {
      final result = await dataSource.sendFriendRequest(
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        receiverId: receiverId,
      );
      return result.fold(
        (error) => Left(ServerFailure(error)),
        (_) => const Right(null),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getReceivedFriendRequests(
    String userId,
  ) async {
    try {
      final result = await dataSource.getReceivedFriendRequests(userId);
      return result.fold(
        (error) => Left(ServerFailure(error)),
        (requests) => Right(requests),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> getSentFriendRequests(
    String userId,
  ) async {
    try {
      final result = await dataSource.getSentFriendRequests(userId);
      return result.fold(
        (error) => Left(ServerFailure(error)),
        (requests) => Right(requests),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptFriendRequest(String requestId) async {
    try {
      final result = await dataSource.acceptFriendRequest(requestId);
      return result.fold(
        (error) => Left(ServerFailure(error)),
        (_) => const Right(null),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectFriendRequest(String requestId) async {
    try {
      final result = await dataSource.rejectFriendRequest(requestId);
      return result.fold(
        (error) => Left(ServerFailure(error)),
        (_) => const Right(null),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelFriendRequest(String requestId) async {
    try {
      final result = await dataSource.cancelFriendRequest(requestId);
      return result.fold(
        (error) => Left(ServerFailure(error)),
        (_) => const Right(null),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FriendshipEntity>>> getFriends(
    String userId,
  ) async {
    try {
      final result = await dataSource.getFriends(userId);
      return result.fold(
        (error) => Left(ServerFailure(error)),
        (friends) => Right(friends),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      final result = await dataSource.removeFriend(
        userId: userId,
        friendId: friendId,
      );
      return result.fold(
        (error) => Left(ServerFailure(error)),
        (_) => const Right(null),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LeaderboardEntryEntity>>> getLeaderboard({
    required LeaderboardType type,
    int limit = 50,
  }) async {
    try {
      final result = await dataSource.getLeaderboard(
        type: type,
        limit: limit,
      );
      return result.fold(
        (error) => Left(ServerFailure(error)),
        (entries) => Right(entries),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LeaderboardEntryEntity>>> getFriendsLeaderboard({
    required String userId,
    required LeaderboardType type,
  }) async {
    try {
      final result = await dataSource.getFriendsLeaderboard(
        userId: userId,
        type: type,
      );
      return result.fold(
        (error) => Left(ServerFailure(error)),
        (entries) => Right(entries),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> searchUsersByEmail(
    String email,
  ) async {
    try {
      final result = await dataSource.searchUsersByEmail(email);
      return result.fold(
        (error) => Left(ServerFailure(error)),
        (usersData) {
          final users = usersData.map((data) {
            return UserModel(
              id: data['id'] as String,
              email: data['email'] as String,
              displayName: data['displayName'] as String,
              photoUrl: data['photoUrl'] as String?,
              totalScore: (data['totalScore'] as num?)?.toInt() ?? 0,
              workoutCount: (data['workoutCount'] as num?)?.toInt() ?? 0,
              createdAt: data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.parse(data['createdAt'] as String),
              lastActiveAt: data['lastActiveAt'] != null
                  ? (data['lastActiveAt'] is Timestamp
                      ? (data['lastActiveAt'] as Timestamp).toDate()
                      : DateTime.parse(data['lastActiveAt'] as String))
                  : null,
            );
          }).toList();
          return Right(users);
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
