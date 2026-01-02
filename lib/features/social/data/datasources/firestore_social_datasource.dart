import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/config/firebase_config.dart';
import 'package:co_workfit/features/social/data/models/friend_request_model.dart';
import 'package:co_workfit/features/social/domain/entities/friend_request_entity.dart';
import 'package:co_workfit/features/social/domain/entities/friendship_entity.dart';
import 'package:co_workfit/features/social/domain/entities/friends_data_entity.dart';
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

      // 양방향 친구 관계 생성 + 친구 요청 삭제를 batch로 처리
      final batch = _firestore.batch();

      // 친구 요청 삭제 (accepted 상태로 유지할 필요 없음)
      batch.delete(requestDoc.reference);

      // 보낸 사람 -> 받은 사람
      final senderFriendship =
          _firestore.collection(FirebaseConfig.friendsCollection).doc();

      batch.set(senderFriendship, {
        'userId': request.senderId,
        'friendId': request.receiverId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 받은 사람 -> 보낸 사람
      final receiverFriendship =
          _firestore.collection(FirebaseConfig.friendsCollection).doc();

      batch.set(receiverFriendship, {
        'userId': request.receiverId,
        'friendId': request.senderId,
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
      // 거절된 요청은 바로 삭제 (rejected 상태로 유지할 필요 없음)
      await _firestore
          .collection(FirebaseConfig.friendRequestsCollection)
          .doc(requestId)
          .delete();

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

  /// 친구 데이터 통합 조회 (친구 목록 + 받은 요청)
  /// 친구와 요청자의 상세 정보도 함께 조회
  Future<Either<String, FriendsDataEntity>> getFriendsData(
    String userId,
  ) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      AppLogger.info('FirestoreSocialDataSource', 'getFriendsData 시작 - userId: $userId');

      // 두 쿼리를 병렬로 실행
      final results = await Future.wait([
        // 1. 친구 목록 조회
        _firestore
            .collection(FirebaseConfig.friendsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get(),
        // 2. 받은 친구 요청 조회 (pending만)
        _firestore
            .collection(FirebaseConfig.friendRequestsCollection)
            .where('receiverId', isEqualTo: userId)
            .where('status', isEqualTo: FriendRequestStatus.pending.name)
            .orderBy('createdAt', descending: true)
            .get(),
      ]);

      final friendsSnapshot = results[0];
      final requestsSnapshot = results[1];

      AppLogger.info('FirestoreSocialDataSource', 'friends 개수: ${friendsSnapshot.docs.length}');
      AppLogger.info('FirestoreSocialDataSource', 'requests 개수: ${requestsSnapshot.docs.length}');

      // 친구들과 요청자들의 userId 수집
      final friendIds = friendsSnapshot.docs
          .map((doc) => doc.data()['friendId'] as String)
          .toList();
      final senderIds = requestsSnapshot.docs
          .map((doc) => doc.data()['senderId'] as String)
          .toList();

      // 모든 관련 사용자 ID 합치기 (중복 제거)
      final allUserIds = {...friendIds, ...senderIds}.toList();

      // 사용자 정보 조회 (10개씩 배치 - Firestore 제한)
      final Map<String, Map<String, dynamic>> usersMap = {};
      for (int i = 0; i < allUserIds.length; i += 10) {
        final batch = allUserIds.skip(i).take(10).toList();
        if (batch.isNotEmpty) {
          final usersSnapshot = await _firestore
              .collection(FirebaseConfig.usersCollection)
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          for (final doc in usersSnapshot.docs) {
            usersMap[doc.id] = doc.data();
          }
        }
      }

      // Friends 파싱 (사용자 정보 포함)
      final friends = friendsSnapshot.docs.map((doc) {
        final data = doc.data();
        final friendId = data['friendId'] as String;
        final friendData = usersMap[friendId];

        return FriendshipEntity(
          id: doc.id,
          userId: data['userId'] as String,
          friendId: friendId,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          friendName: friendData?['displayName'] as String?,
          friendNickname: friendData?['nickname'] as String?,
          friendEmail: friendData?['email'] as String?,
          friendPhotoUrl: friendData?['photoUrl'] as String?,
        );
      }).toList();

      // Requests 파싱 (보낸 사람 정보 포함)
      final requests = requestsSnapshot.docs.map((doc) {
        final senderId = doc.data()['senderId'] as String;
        final senderData = usersMap[senderId] ?? {};
        return FriendRequestModel.fromFirestoreWithSender(doc, senderData);
      }).toList();

      return Right(FriendsDataEntity(
        friends: friends,
        pendingRequests: requests,
        requestCount: requests.length,
      ));
    } catch (e) {
      AppLogger.error('FirestoreSocialDataSource', '친구 데이터 조회 실패', e);
      return Left('친구 데이터 조회에 실패했습니다: $e');
    }
  }

  /// 친구 목록 가져오기 (친구 정보 포함)
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

      if (snapshot.docs.isEmpty) {
        return const Right([]);
      }

      // 친구들의 userId 수집
      final friendIds = snapshot.docs
          .map((doc) => doc.data()['friendId'] as String)
          .toList();

      // 사용자 정보 조회 (10개씩 배치 - Firestore 제한)
      final Map<String, Map<String, dynamic>> usersMap = {};
      for (int i = 0; i < friendIds.length; i += 10) {
        final batch = friendIds.skip(i).take(10).toList();
        if (batch.isNotEmpty) {
          final usersSnapshot = await _firestore
              .collection(FirebaseConfig.usersCollection)
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          for (final doc in usersSnapshot.docs) {
            usersMap[doc.id] = doc.data();
          }
        }
      }

      final friends = snapshot.docs.map((doc) {
        final data = doc.data();
        final friendId = data['friendId'] as String;
        final friendData = usersMap[friendId];

        return FriendshipEntity(
          id: doc.id,
          userId: data['userId'] as String,
          friendId: friendId,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          friendName: friendData?['displayName'] as String?,
          friendNickname: friendData?['nickname'] as String?,
          friendEmail: friendData?['email'] as String?,
          friendPhotoUrl: friendData?['photoUrl'] as String?,
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
          nickname: data['nickname'] as String?,
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
                nickname: data['nickname'] as String?,
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
              nickname: userData['nickname'] as String?,
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

  /// 사용자 검색 (닉네임으로)
  Future<Either<String, List<Map<String, dynamic>>>> searchUsersByNickname(
    String nickname,
  ) async {
    if (!_initialized) {
      return const Left('Firebase가 초기화되지 않았습니다. Firebase 설정을 확인해주세요.');
    }

    try {
      if (nickname.isEmpty) {
        return const Right([]);
      }

      // Firestore range query for autocomplete
      final snapshot = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .where('nickname', isGreaterThanOrEqualTo: nickname)
          .where('nickname', isLessThan: nickname + 'z')
          .limit(10)
          .get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'email': data['email'],
          'displayName': data['displayName'],
          'nickname': data['nickname'],
          'photoUrl': data['photoUrl'],
          'totalScore': data['totalScore'],
          'workoutCount': data['workoutCount'],
          'createdAt': data['createdAt'],
          'lastActiveAt': data['lastActiveAt'],
        };
      }).toList();

      return Right(users);
    } catch (e) {
      return Left('사용자 검색에 실패했습니다: $e');
    }
  }
}
