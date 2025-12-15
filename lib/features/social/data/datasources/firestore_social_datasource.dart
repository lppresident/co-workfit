import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/config/firebase_config.dart';
import 'package:co_workfit/features/social/data/models/friend_request_model.dart';
import 'package:co_workfit/features/social/domain/entities/friend_request_entity.dart';
import 'package:co_workfit/features/social/domain/entities/friendship_entity.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// Firestore 소셜 데이터소스
class FirestoreSocialDataSource {
  late final FirebaseFirestore _firestore;
  bool _initialized = false;

  FirestoreSocialDataSource({FirebaseFirestore? firestore}) {
    try {
      _firestore = firestore ?? FirebaseFirestore.instance;
      _initialized = true;
    } catch (e) {
      AppLogger.warning('FirestoreSocialDataSource', 'Firebase not initialized: $e');
      _initialized = false;
    }
  }

  /// Firebase 초기화 여부 확인
  bool get isInitialized => _initialized;

  // ========== 친구 요청 관련 ==========

  /// 친구 요청 보내기
  Future<Either<String, void>> sendFriendRequest({
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String receiverId,
  }) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      // 이미 친구 요청이 있는지 확인
      final existingRequest = await _firestore
          .collection(FirebaseConfig.friendRequestsCollection)
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: FriendRequestStatus.pending.name)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        return const Left('이미 친구 요청을 보냈습니다.');
      }

      // 이미 친구인지 확인
      final friendship = await _firestore
          .collection(FirebaseConfig.friendsCollection)
          .where('userId', isEqualTo: senderId)
          .where('friendId', isEqualTo: receiverId)
          .get();

      if (friendship.docs.isNotEmpty) {
        return const Left('이미 친구입니다.');
      }

      // 친구 요청 생성
      final request = FriendRequestModel(
        id: '',
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        receiverId: receiverId,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(FirebaseConfig.friendRequestsCollection)
          .add(request.toFirestore());

      return const Right(null);
    } catch (e) {
      return Left('친구 요청 전송에 실패했습니다: $e');
    }
  }

  /// 받은 친구 요청 목록 가져오기
  Future<Either<String, List<FriendRequestEntity>>> getReceivedFriendRequests(
    String userId,
  ) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      final snapshot = await _firestore
          .collection(FirebaseConfig.friendRequestsCollection)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: FriendRequestStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      final requests = snapshot.docs
          .map((doc) => FriendRequestModel.fromFirestore(doc))
          .toList();

      return Right(requests);
    } catch (e) {
      return Left('친구 요청 목록을 가져오는데 실패했습니다: $e');
    }
  }

  /// 보낸 친구 요청 목록 가져오기
  Future<Either<String, List<FriendRequestEntity>>> getSentFriendRequests(
    String userId,
  ) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      final snapshot = await _firestore
          .collection(FirebaseConfig.friendRequestsCollection)
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: FriendRequestStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      final requests = snapshot.docs
          .map((doc) => FriendRequestModel.fromFirestore(doc))
          .toList();

      return Right(requests);
    } catch (e) {
      return Left('보낸 친구 요청 목록을 가져오는데 실패했습니다: $e');
    }
  }

  /// 친구 요청 수락
  Future<Either<String, void>> acceptFriendRequest(
    String requestId,
  ) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      // 친구 요청 가져오기
      final requestDoc = await _firestore
          .collection(FirebaseConfig.friendRequestsCollection)
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        return const Left('친구 요청을 찾을 수 없습니다.');
      }

      final request = FriendRequestModel.fromFirestore(requestDoc);

      // 친구 요청 상태 업데이트
      await _firestore
          .collection(FirebaseConfig.friendRequestsCollection)
          .doc(requestId)
          .update({
        'status': FriendRequestStatus.accepted.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // 양방향 친구 관계 생성
      final batch = _firestore.batch();

      // 보낸 사람 -> 받은 사람
      final senderFriendship =
          _firestore.collection(FirebaseConfig.friendsCollection).doc();

      // 받은 사람 정보 가져오기
      final receiverDoc = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .doc(request.receiverId)
          .get();

      final receiverData = receiverDoc.data() as Map<String, dynamic>;

      batch.set(senderFriendship, {
        'userId': request.senderId,
        'friendId': request.receiverId,
        'friendName': receiverData['displayName'],
        'friendEmail': receiverData['email'],
        'friendPhotoUrl': receiverData['photoUrl'],
        'friendTotalScore': receiverData['totalScore'] ?? 0,
        'friendWorkoutCount': receiverData['workoutCount'] ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 받은 사람 -> 보낸 사람
      final receiverFriendship =
          _firestore.collection(FirebaseConfig.friendsCollection).doc();

      batch.set(receiverFriendship, {
        'userId': request.receiverId,
        'friendId': request.senderId,
        'friendName': request.senderName,
        'friendEmail': '', // 보낸 사람 이메일은 요청에 포함되지 않음
        'friendPhotoUrl': request.senderPhotoUrl,
        'friendTotalScore': 0,
        'friendWorkoutCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return const Right(null);
    } catch (e) {
      return Left('친구 요청 수락에 실패했습니다: $e');
    }
  }

  /// 친구 요청 거절
  Future<Either<String, void>> rejectFriendRequest(String requestId) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      await _firestore
          .collection(FirebaseConfig.friendRequestsCollection)
          .doc(requestId)
          .update({
        'status': FriendRequestStatus.rejected.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      return const Right(null);
    } catch (e) {
      return Left('친구 요청 거절에 실패했습니다: $e');
    }
  }

  /// 친구 요청 취소
  Future<Either<String, void>> cancelFriendRequest(String requestId) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      await _firestore
          .collection(FirebaseConfig.friendRequestsCollection)
          .doc(requestId)
          .delete();

      return const Right(null);
    } catch (e) {
      return Left('친구 요청 취소에 실패했습니다: $e');
    }
  }

  // ========== 친구 관계 관련 ==========

  /// 친구 목록 가져오기
  Future<Either<String, List<FriendshipEntity>>> getFriends(
    String userId,
  ) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      final snapshot = await _firestore
          .collection(FirebaseConfig.friendsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final friends = snapshot.docs.map((doc) {
        final data = doc.data();
        return FriendshipEntity(
          id: doc.id,
          userId: data['userId'] as String,
          friendId: data['friendId'] as String,
          friendName: data['friendName'] as String,
          friendEmail: data['friendEmail'] as String,
          friendPhotoUrl: data['friendPhotoUrl'] as String?,
          friendTotalScore: (data['friendTotalScore'] as num?)?.toInt() ?? 0,
          friendWorkoutCount:
              (data['friendWorkoutCount'] as num?)?.toInt() ?? 0,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      return Right(friends);
    } catch (e) {
      return Left('친구 목록을 가져오는데 실패했습니다: $e');
    }
  }

  /// 친구 삭제
  Future<Either<String, void>> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      // 양방향 친구 관계 삭제
      final batch = _firestore.batch();

      // userId -> friendId 관계 삭제
      final friendship1 = await _firestore
          .collection(FirebaseConfig.friendsCollection)
          .where('userId', isEqualTo: userId)
          .where('friendId', isEqualTo: friendId)
          .get();

      for (final doc in friendship1.docs) {
        batch.delete(doc.reference);
      }

      // friendId -> userId 관계 삭제
      final friendship2 = await _firestore
          .collection(FirebaseConfig.friendsCollection)
          .where('userId', isEqualTo: friendId)
          .where('friendId', isEqualTo: userId)
          .get();

      for (final doc in friendship2.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      return const Right(null);
    } catch (e) {
      return Left('친구 삭제에 실패했습니다: $e');
    }
  }

  // ========== 리더보드 관련 ==========

  /// 전체 리더보드 가져오기
  Future<Either<String, List<LeaderboardEntryEntity>>> getLeaderboard({
    required LeaderboardType type,
    int limit = 50,
  }) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      Query query = _firestore.collection(FirebaseConfig.usersCollection);

      // 타입에 따라 필터링 (현재는 all-time만 구현)
      // weekly, monthly는 별도 컬렉션이나 필터링 로직 필요

      // 점수 기준 내림차순 정렬
      query = query.orderBy('totalScore', descending: true).limit(limit);

      final snapshot = await query.get();

      final entries = snapshot.docs.asMap().entries.map((entry) {
        final index = entry.key;
        final doc = entry.value;
        final data = doc.data() as Map<String, dynamic>;

        return LeaderboardEntryEntity(
          userId: doc.id,
          displayName: data['displayName'] as String,
          photoUrl: data['photoUrl'] as String?,
          totalScore: (data['totalScore'] as num?)?.toInt() ?? 0,
          workoutCount: (data['workoutCount'] as num?)?.toInt() ?? 0,
          rank: index + 1,
          type: type,
          updatedAt: DateTime.now(),
        );
      }).toList();

      return Right(entries);
    } catch (e) {
      return Left('리더보드를 가져오는데 실패했습니다: $e');
    }
  }

  /// 친구 리더보드 가져오기
  Future<Either<String, List<LeaderboardEntryEntity>>> getFriendsLeaderboard({
    required String userId,
    required LeaderboardType type,
  }) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      // 친구 목록 가져오기
      final friendsResult = await getFriends(userId);

      return friendsResult.fold(
        (error) => Left(error),
        (friends) async {
          if (friends.isEmpty) {
            return const Right([]);
          }

          // 친구들의 점수 정보 가져오기
          final friendIds = friends.map((f) => f.friendId).toList();

          // Firestore는 'in' 쿼리가 10개로 제한되므로 나눠서 가져오기
          final List<LeaderboardEntryEntity> entries = [];

          for (int i = 0; i < friendIds.length; i += 10) {
            final batch =
                friendIds.skip(i).take(10).toList();

            final snapshot = await _firestore
                .collection(FirebaseConfig.usersCollection)
                .where(FieldPath.documentId, whereIn: batch)
                .get();

            final batchEntries = snapshot.docs.map((doc) {
              final data = doc.data();
              return LeaderboardEntryEntity(
                userId: doc.id,
                displayName: data['displayName'] as String,
                photoUrl: data['photoUrl'] as String?,
                totalScore: (data['totalScore'] as num?)?.toInt() ?? 0,
                workoutCount: (data['workoutCount'] as num?)?.toInt() ?? 0,
                rank: 0, // 나중에 설정
                type: type,
                updatedAt: DateTime.now(),
              );
            }).toList();

            entries.addAll(batchEntries);
          }

          // 본인 추가
          final userDoc = await _firestore
              .collection(FirebaseConfig.usersCollection)
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            entries.add(LeaderboardEntryEntity(
              userId: userId,
              displayName: userData['displayName'] as String,
              photoUrl: userData['photoUrl'] as String?,
              totalScore: (userData['totalScore'] as num?)?.toInt() ?? 0,
              workoutCount: (userData['workoutCount'] as num?)?.toInt() ?? 0,
              rank: 0,
              type: type,
              updatedAt: DateTime.now(),
            ));
          }

          // 점수 기준 정렬 및 순위 부여
          entries.sort((a, b) => b.totalScore.compareTo(a.totalScore));
          final rankedEntries = entries
              .asMap()
              .entries
              .map((e) => e.value.copyWith(rank: e.key + 1))
              .toList();

          return Right(rankedEntries);
        },
      );
    } catch (e) {
      return Left('친구 리더보드를 가져오는데 실패했습니다: $e');
    }
  }

  /// 사용자 검색 (이메일로)
  Future<Either<String, List<Map<String, dynamic>>>> searchUsersByEmail(
    String email,
  ) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      if (email.isEmpty) {
        return const Right([]);
      }

      final snapshot = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .where('email', isEqualTo: email)
          .limit(10)
          .get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'email': data['email'],
          'displayName': data['displayName'],
          'photoUrl': data['photoUrl'],
        };
      }).toList();

      return Right(users);
    } catch (e) {
      return Left('사용자 검색에 실패했습니다: $e');
    }
  }
}
