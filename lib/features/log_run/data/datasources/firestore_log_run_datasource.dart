import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/data/models/log_run_challenge_model.dart';
import 'package:co_workfit/features/log_run/data/models/log_run_contribution_model.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// Firestore 통나무런 DataSource
class FirestoreLogRunDataSource {
  final FirebaseFirestore firestore;

  static const String _challengesCollection = 'log_run_challenges';
  static const String _contributionsSubcollection = 'contributions';
  static const String _workoutsCollection = 'workouts';

  FirestoreLogRunDataSource({required this.firestore});

  /// 챌린지 생성
  Future<LogRunChallengeModel> createChallenge({
    required String userId,
    required String userName,
    required double targetWeight,
    int? recordTimeLimit,
    bool? allowFutureRecordsOnly,
    DateTime? expiresAt,
  }) async {
    try {
      final now = DateTime.now();
      final challengeRef = firestore.collection(_challengesCollection).doc();

      final challengeData = {
        'createdBy': userId,
        'creatorName': userName,
        'targetWeight': targetWeight,
        'targetDistance': targetWeight, // 1kg = 1km
        'currentDistance': 0.0,
        'remainingWeight': targetWeight,
        'participants': [userId],
        'participantNames': {userId: userName},
        'status': ChallengeStatus.active.toFirestore(),
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'recordTimeLimit': recordTimeLimit ?? 7,
        'allowFutureRecordsOnly': allowFutureRecordsOnly ?? false,
      };

      await challengeRef.set(challengeData);

      final doc = await challengeRef.get();
      AppLogger.info('FirestoreLogRunDataSource', 'Challenge created: ${challengeRef.id}');
      return LogRunChallengeModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('FirestoreLogRunDataSource', 'Error creating challenge: $e');
      rethrow;
    }
  }

  /// 챌린지 참가
  Future<void> joinChallenge({
    required String challengeId,
    required String userId,
    required String userName,
  }) async {
    try {
      final challengeRef = firestore.collection(_challengesCollection).doc(challengeId);

      await challengeRef.update({
        'participants': FieldValue.arrayUnion([userId]),
        'participantNames.$userId': userName,
      });

      AppLogger.info('FirestoreLogRunDataSource', 'User $userId joined challenge $challengeId');
    } catch (e) {
      AppLogger.error('FirestoreLogRunDataSource', 'Error joining challenge: $e');
      rethrow;
    }
  }

  /// 챌린지 탈퇴
  Future<void> leaveChallenge({
    required String challengeId,
    required String userId,
  }) async {
    try {
      final challengeRef = firestore.collection(_challengesCollection).doc(challengeId);

      await challengeRef.update({
        'participants': FieldValue.arrayRemove([userId]),
        'participantNames.$userId': FieldValue.delete(),
      });

      AppLogger.info('FirestoreLogRunDataSource', 'User $userId left challenge $challengeId');
    } catch (e) {
      AppLogger.error('FirestoreLogRunDataSource', 'Error leaving challenge: $e');
      rethrow;
    }
  }

  /// 운동 기록 제출
  Future<LogRunContributionModel> submitWorkout({
    required String challengeId,
    required String userId,
    required String userName,
    required String workoutId,
    required double distance,
    required String workoutType,
    required DateTime workoutDate,
  }) async {
    try {
      return await firestore.runTransaction<LogRunContributionModel>((transaction) async {
        // 1. 챌린지 조회
        final challengeRef = firestore.collection(_challengesCollection).doc(challengeId);
        final challengeDoc = await transaction.get(challengeRef);

        if (!challengeDoc.exists) {
          throw Exception('Challenge not found');
        }

        final challenge = LogRunChallengeModel.fromFirestore(challengeDoc);

        // 2. 중복 제출 검증 (이미 사용된 workout인지 확인)
        final workoutRef = firestore.collection(_workoutsCollection).doc(workoutId);
        final workoutDoc = await transaction.get(workoutRef);

        if (workoutDoc.exists) {
          final usedChallenges = List<String>.from(
            (workoutDoc.data()?['usedInChallenges'] as List?) ?? [],
          );

          if (usedChallenges.contains(challengeId)) {
            throw Exception('이 운동 기록은 이미 이 챌린지에 제출되었습니다');
          }
        }

        // 3. 시간 제한 검증
        final daysSinceWorkout = DateTime.now().difference(workoutDate).inDays;
        if (daysSinceWorkout > challenge.recordTimeLimit) {
          throw Exception('너무 오래된 기록입니다 (${challenge.recordTimeLimit}일 이내만 허용)');
        }

        // 4. 방 생성 이후 기록만 허용하는 경우
        if (challenge.allowFutureRecordsOnly && workoutDate.isBefore(challenge.createdAt)) {
          throw Exception('방 생성 이후의 기록만 제출 가능합니다');
        }

        // 5. 기여도 계산
        final newCurrentDistance = challenge.currentDistance + distance;
        final newRemainingWeight = (challenge.targetWeight - newCurrentDistance).clamp(0.0, challenge.targetWeight);
        final percentage = distance / challenge.targetDistance;

        // 6. 챌린지 업데이트
        transaction.update(challengeRef, {
          'currentDistance': newCurrentDistance,
          'remainingWeight': newRemainingWeight,
          'status': newCurrentDistance >= challenge.targetDistance
              ? ChallengeStatus.completed.toFirestore()
              : ChallengeStatus.active.toFirestore(),
        });

        // 7. 기여 내역 추가
        final contributionRef = challengeRef
            .collection(_contributionsSubcollection)
            .doc();

        final now = DateTime.now();
        final contributionData = {
          'challengeId': challengeId,
          'userId': userId,
          'userName': userName,
          'workoutId': workoutId,
          'distance': distance,
          'workoutType': workoutType,
          'workoutDate': Timestamp.fromDate(workoutDate),
          'submittedAt': Timestamp.fromDate(now),
          'percentage': percentage,
        };

        transaction.set(contributionRef, contributionData);

        // 8. workout의 usedInChallenges 배열 업데이트
        if (workoutDoc.exists) {
          transaction.update(workoutRef, {
            'usedInChallenges': FieldValue.arrayUnion([challengeId]),
          });
        }

        AppLogger.info('FirestoreLogRunDataSource', 'Workout submitted to challenge $challengeId');

        return LogRunContributionModel(
          id: contributionRef.id,
          challengeId: challengeId,
          userId: userId,
          userName: userName,
          workoutId: workoutId,
          distance: distance,
          workoutType: WorkoutTypeExtension.fromFirestore(workoutType),
          workoutDate: workoutDate,
          submittedAt: now,
          percentage: percentage,
        );
      });
    } catch (e) {
      AppLogger.error('FirestoreLogRunDataSource', 'Error submitting workout: $e');
      rethrow;
    }
  }

  /// 활성 챌린지 목록 조회
  Future<List<LogRunChallengeModel>> getActiveChallenges(String userId) async {
    try {
      final query = await firestore
          .collection(_challengesCollection)
          .where('participants', arrayContains: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => LogRunChallengeModel.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('FirestoreLogRunDataSource', 'Error getting active challenges: $e');
      rethrow;
    }
  }

  /// 완료된 챌린지 목록 조회
  Future<List<LogRunChallengeModel>> getCompletedChallenges(String userId) async {
    try {
      final query = await firestore
          .collection(_challengesCollection)
          .where('participants', arrayContains: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => LogRunChallengeModel.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('FirestoreLogRunDataSource', 'Error getting completed challenges: $e');
      rethrow;
    }
  }

  /// 챌린지 상세 조회
  Future<LogRunChallengeModel> getChallengeById(String challengeId) async {
    try {
      final doc = await firestore.collection(_challengesCollection).doc(challengeId).get();

      if (!doc.exists) {
        throw Exception('Challenge not found');
      }

      return LogRunChallengeModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('FirestoreLogRunDataSource', 'Error getting challenge: $e');
      rethrow;
    }
  }

  /// 챌린지 기여 내역 조회
  Future<List<LogRunContributionModel>> getChallengeContributions(String challengeId) async {
    try {
      final query = await firestore
          .collection(_challengesCollection)
          .doc(challengeId)
          .collection(_contributionsSubcollection)
          .orderBy('submittedAt', descending: true)
          .get();

      return query.docs.map((doc) => LogRunContributionModel.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('FirestoreLogRunDataSource', 'Error getting contributions: $e');
      rethrow;
    }
  }

  /// 챌린지 실시간 스트림
  Stream<LogRunChallengeModel> watchChallenge(String challengeId) {
    return firestore
        .collection(_challengesCollection)
        .doc(challengeId)
        .snapshots()
        .map((doc) => LogRunChallengeModel.fromFirestore(doc));
  }

  /// 기여 내역 실시간 스트림
  Stream<List<LogRunContributionModel>> watchContributions(String challengeId) {
    return firestore
        .collection(_challengesCollection)
        .doc(challengeId)
        .collection(_contributionsSubcollection)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => LogRunContributionModel.fromFirestore(doc)).toList());
  }

  /// 챌린지 삭제 (방장만 가능)
  Future<void> deleteChallenge({
    required String challengeId,
    required String userId,
  }) async {
    try {
      final challengeRef = firestore.collection(_challengesCollection).doc(challengeId);
      final challengeDoc = await challengeRef.get();

      if (!challengeDoc.exists) {
        throw Exception('Challenge not found');
      }

      final challenge = LogRunChallengeModel.fromFirestore(challengeDoc);

      if (challenge.createdBy != userId) {
        throw Exception('Only the creator can delete this challenge');
      }

      // 기여 내역도 함께 삭제
      final contributions = await challengeRef.collection(_contributionsSubcollection).get();
      for (final doc in contributions.docs) {
        await doc.reference.delete();
      }

      await challengeRef.delete();

      AppLogger.info('FirestoreLogRunDataSource', 'Challenge deleted: $challengeId');
    } catch (e) {
      AppLogger.error('FirestoreLogRunDataSource', 'Error deleting challenge: $e');
      rethrow;
    }
  }
}
