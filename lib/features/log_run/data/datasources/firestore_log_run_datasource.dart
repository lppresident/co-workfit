import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/data/models/log_run_challenge_model.dart';
import 'package:co_workfit/features/log_run/data/models/log_run_contribution_model.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/utils/invite_code_generator.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/core/config/firebase_config.dart';

class FirestoreLogRunDataSource {
  final FirebaseFirestore firestore;
  static const String _challengesCollection = 'log_run_challenges';
  static const String _contributionsSubcollection = 'contributions';

  FirestoreLogRunDataSource({required this.firestore});

  /// 챌린지 생성
  Future<LogRunChallengeModel> createChallenge({
    required String userId,
    required String userNickname,
    required double targetWeight,
    required DateTime startDate,
    required DateTime endDate,
    int? maxParticipants,
  }) async {
    final now = DateTime.now();
    final challengeRef = firestore.collection(_challengesCollection).doc();

    // 고유한 초대 코드 생성 (중복 체크)
    String inviteCode;
    bool isUnique = false;
    int attempts = 0;
    const maxAttempts = 10;

    do {
      inviteCode = InviteCodeGenerator.generate();
      final existingChallenge = await firestore
          .collection(_challengesCollection)
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      isUnique = existingChallenge.docs.isEmpty;
      attempts++;
    } while (!isUnique && attempts < maxAttempts);

    if (!isUnique) {
      throw Exception('초대 코드 생성에 실패했습니다. 다시 시도해주세요.');
    }

    await challengeRef.set({
      'createdBy': userId,
      'creatorNickname': userNickname,
      'targetWeight': targetWeight,
      'targetDistance': targetWeight,
      'currentDistance': 0.0,
      'remainingWeight': targetWeight,
      'participants': [userId],
      'participantNicknames': {userId: userNickname},
      'status': ChallengeStatus.active.toFirestore(),
      'createdAt': Timestamp.fromDate(now),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'inviteCode': inviteCode,
      'completedAt': null,
      'maxParticipants': maxParticipants,
    });

    final doc = await challengeRef.get();
    return LogRunChallengeModel.fromFirestore(doc);
  }

  /// 챌린지 참가
  Future<void> joinChallenge({
    required String challengeId,
    required String userId,
    required String userNickname,
  }) async {
    await firestore.collection(_challengesCollection).doc(challengeId).update({
      'participants': FieldValue.arrayUnion([userId]),
      'participantNicknames.$userId': userNickname,
    });
  }

  /// 챌린지 탈퇴
  Future<void> leaveChallenge({
    required String challengeId,
    required String userId,
  }) async {
    await firestore.collection(_challengesCollection).doc(challengeId).update({
      'participants': FieldValue.arrayRemove([userId]),
      'participantNicknames.$userId': FieldValue.delete(),
    });
  }

  /// 운동 기록 제출 (기간 검증 포함)
  Future<LogRunContributionModel> submitWorkout({
    required String challengeId,
    required String userId,
    required String userNickname,
    required String workoutId,
    required double distance,
    required String workoutType,
    required DateTime workoutDate,
  }) async {
    return await firestore.runTransaction<LogRunContributionModel>((transaction) async {
      final challengeRef = firestore.collection(_challengesCollection).doc(challengeId);
      final challengeDoc = await transaction.get(challengeRef);
      if (!challengeDoc.exists) throw Exception('챌린지를 찾을 수 없습니다');

      final challenge = LogRunChallengeModel.fromFirestore(challengeDoc);

      // 중복 제출 검증: 동일 사용자가 동일 workoutId로 이미 제출했는지 확인
      final existingContributions = await challengeRef
          .collection(_contributionsSubcollection)
          .where('userId', isEqualTo: userId)
          .where('workoutId', isEqualTo: workoutId)
          .limit(1)
          .get();

      if (existingContributions.docs.isNotEmpty) {
        throw Exception('이미 제출한 운동 기록입니다');
      }

      // 기간 검증: 운동 날짜가 시작일~종료일 사이인지 확인
      if (!challenge.isWorkoutDateValid(workoutDate)) {
        throw Exception('해당 운동은 챌린지 기간(${_formatDate(challenge.startDate)} ~ ${_formatDate(challenge.endDate)}) 내의 기록이 아닙니다');
      }

      // 챌린지가 이미 완료되었는지 확인
      if (challenge.isCompleted) {
        throw Exception('이미 완료된 챌린지입니다');
      }

      // 챌린지 종료일이 지났는지 확인
      if (challenge.isExpired) {
        throw Exception('챌린지 기간이 종료되었습니다');
      }

      final newCurrentDistance = challenge.currentDistance + distance;
      final newRemainingWeight = (challenge.targetWeight - newCurrentDistance).clamp(0.0, challenge.targetWeight);
      final percentage = distance / challenge.targetDistance;
      final isNowCompleted = newCurrentDistance >= challenge.targetDistance;

      // 챌린지 업데이트
      final updateData = <String, dynamic>{
        'currentDistance': newCurrentDistance,
        'remainingWeight': newRemainingWeight,
      };

      if (isNowCompleted) {
        updateData['status'] = ChallengeStatus.completed.toFirestore();
        updateData['completedAt'] = FieldValue.serverTimestamp();
        // TTL: 7일 후 자동 삭제를 위한 expireAt 필드 설정
        updateData['expireAt'] = Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        );
      }

      transaction.update(challengeRef, updateData);

      // 기여 기록 추가
      final contributionRef = challengeRef.collection(_contributionsSubcollection).doc();
      final now = DateTime.now();
      transaction.set(contributionRef, {
        'challengeId': challengeId,
        'userId': userId,
        'userNickname': userNickname,
        'workoutId': workoutId,
        'distance': distance,
        'workoutType': workoutType,
        'workoutDate': Timestamp.fromDate(workoutDate),
        'submittedAt': Timestamp.fromDate(now),
        'percentage': percentage,
      });

      // 완료 시 참가자들에게 점수 부여
      if (isNowCompleted) {
        await _awardCompletionScores(
          transaction: transaction,
          challenge: challenge,
          contributionDistance: distance,
          contributorId: userId,
        );
      }

      return LogRunContributionModel(
        id: contributionRef.id,
        challengeId: challengeId,
        userId: userId,
        userNickname: userNickname,
        workoutId: workoutId,
        distance: distance,
        workoutType: _parseWorkoutType(workoutType),
        workoutDate: workoutDate,
        submittedAt: now,
        percentage: percentage,
      );
    });
  }

  /// 기여 기록 삭제
  Future<void> deleteContribution({
    required String challengeId,
    required String contributionId,
    required String userId,
  }) async {
    await firestore.runTransaction((transaction) async {
      final challengeRef = firestore.collection(_challengesCollection).doc(challengeId);
      final contributionRef = challengeRef.collection(_contributionsSubcollection).doc(contributionId);

      final challengeDoc = await transaction.get(challengeRef);
      final contributionDoc = await transaction.get(contributionRef);

      if (!challengeDoc.exists) throw Exception('챌린지를 찾을 수 없습니다');
      if (!contributionDoc.exists) throw Exception('기록을 찾을 수 없습니다');

      final challenge = LogRunChallengeModel.fromFirestore(challengeDoc);
      final contribution = LogRunContributionModel.fromFirestore(contributionDoc);

      // 본인 기록만 삭제 가능 (또는 방장)
      if (contribution.userId != userId && challenge.createdBy != userId) {
        throw Exception('본인의 기록만 삭제할 수 있습니다');
      }

      // 이미 완료된 챌린지의 기록은 삭제 불가
      if (challenge.isCompleted) {
        throw Exception('완료된 챌린지의 기록은 삭제할 수 없습니다');
      }

      // 챌린지 거리 업데이트
      final newCurrentDistance = (challenge.currentDistance - contribution.distance).clamp(0.0, double.infinity);
      final newRemainingWeight = challenge.targetWeight - newCurrentDistance;

      transaction.update(challengeRef, {
        'currentDistance': newCurrentDistance,
        'remainingWeight': newRemainingWeight,
      });

      // 기여 기록 삭제
      transaction.delete(contributionRef);
    });
  }

  /// 활성 챌린지 목록 조회
  Future<List<LogRunChallengeModel>> getActiveChallenges(String userId) async {
    final query = await firestore
        .collection(_challengesCollection)
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) => LogRunChallengeModel.fromFirestore(doc)).toList();
  }

  /// 완료 챌린지 목록 조회 (expireAt이 아직 지나지 않은 것만)
  /// TTL 정책으로 7일 후 자동 삭제되므로, expireAt > now인 것만 조회
  Future<List<LogRunChallengeModel>> getCompletedChallenges(String userId) async {
    final now = DateTime.now();
    final query = await firestore
        .collection(_challengesCollection)
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: 'completed')
        .where('expireAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expireAt', descending: false)
        .get();

    return query.docs.map((doc) => LogRunChallengeModel.fromFirestore(doc)).toList();
  }

  /// 챌린지 상세 조회
  Future<LogRunChallengeModel> getChallengeById(String challengeId) async {
    final doc = await firestore.collection(_challengesCollection).doc(challengeId).get();
    if (!doc.exists) throw Exception('챌린지를 찾을 수 없습니다');
    return LogRunChallengeModel.fromFirestore(doc);
  }

  /// 초대 코드로 챌린지 조회
  Future<LogRunChallengeModel> getChallengeByInviteCode(String inviteCode) async {
    final query = await firestore
        .collection(_challengesCollection)
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('초대 코드가 유효하지 않습니다');
    }

    return LogRunChallengeModel.fromFirestore(query.docs.first);
  }

  /// 챌린지 기여 내역 조회
  Future<List<LogRunContributionModel>> getChallengeContributions(String challengeId) async {
    final query = await firestore
        .collection(_challengesCollection)
        .doc(challengeId)
        .collection(_contributionsSubcollection)
        .orderBy('submittedAt', descending: true)
        .get();
    return query.docs.map((doc) => LogRunContributionModel.fromFirestore(doc)).toList();
  }

  /// 챌린지 실시간 감시
  Stream<LogRunChallengeModel> watchChallenge(String challengeId) {
    return firestore
        .collection(_challengesCollection)
        .doc(challengeId)
        .snapshots()
        .map((doc) => LogRunChallengeModel.fromFirestore(doc));
  }

  /// 기여 내역 실시간 감시
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
    final challengeRef = firestore.collection(_challengesCollection).doc(challengeId);
    final challengeDoc = await challengeRef.get();
    if (!challengeDoc.exists) throw Exception('챌린지를 찾을 수 없습니다');

    final challenge = LogRunChallengeModel.fromFirestore(challengeDoc);
    if (challenge.createdBy != userId) {
      throw Exception('방장만 챌린지를 삭제할 수 있습니다');
    }

    // 기여 내역 모두 삭제
    final contributions = await challengeRef.collection(_contributionsSubcollection).get();
    for (final doc in contributions.docs) {
      await doc.reference.delete();
    }

    // 챌린지 삭제
    await challengeRef.delete();
  }

  /// 보관 기간이 지난 완료 챌린지 정리 (백그라운드 작업용)
  Future<int> cleanupExpiredChallenges() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final query = await firestore
        .collection(_challengesCollection)
        .where('status', isEqualTo: 'completed')
        .where('completedAt', isLessThan: Timestamp.fromDate(sevenDaysAgo))
        .get();

    int deletedCount = 0;
    for (final doc in query.docs) {
      final challengeRef = doc.reference;

      // 기여 내역 삭제
      final contributions = await challengeRef.collection(_contributionsSubcollection).get();
      for (final contribDoc in contributions.docs) {
        await contribDoc.reference.delete();
      }

      // 챌린지 삭제
      await challengeRef.delete();
      deletedCount++;
    }

    if (deletedCount > 0) {
      AppLogger.info('FirestoreLogRunDataSource', '보관 기간이 지난 챌린지 $deletedCount개 삭제됨');
    }

    return deletedCount;
  }

  // ========== Private Methods ==========

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }

  /// 운동 타입 파싱
  WorkoutType _parseWorkoutType(String value) {
    switch (value) {
      case 'running':
        return WorkoutType.running;
      case 'cycling':
        return WorkoutType.cycling;
      case 'walking':
        return WorkoutType.walking;
      case 'swimming':
        return WorkoutType.swimming;
      case 'weightTraining':
        return WorkoutType.weightTraining;
      case 'yoga':
        return WorkoutType.yoga;
      case 'hiking':
        return WorkoutType.hiking;
      default:
        return WorkoutType.other;
    }
  }

  /// 완료 시 참가자들에게 점수 부여
  ///
  /// 점수 시스템:
  /// - 기본 점수: 개인 기여 거리(km) × 10점
  /// - 완료 보너스: 목표 달성 시 전원 +50점
  /// - 협력 보너스: 참가자 수 × 10점 (최대 40점, 4명까지)
  /// - 속도 보너스: 기간의 50% 내 완료 시 +30점
  Future<void> _awardCompletionScores({
    required Transaction transaction,
    required LogRunChallengeModel challenge,
    required double contributionDistance,
    required String contributorId,
  }) async {
    try {
      // 모든 기여 내역 조회
      final contributionsSnapshot = await firestore
          .collection(_challengesCollection)
          .doc(challenge.id)
          .collection(_contributionsSubcollection)
          .get();

      // 참가자별 기여 거리 합산
      final Map<String, double> userDistances = {};
      for (final doc in contributionsSnapshot.docs) {
        final data = doc.data();
        final oderId = data['userId'] as String;
        final distance = (data['distance'] as num).toDouble();
        userDistances[oderId] = (userDistances[oderId] ?? 0) + distance;
      }

      // 마지막 기여자의 기여도 추가 (아직 DB에 반영 안됨)
      userDistances[contributorId] = (userDistances[contributorId] ?? 0) + contributionDistance;

      // 협력 보너스 계산 (참가자 수 × 10, 최대 40점)
      final participantCount = challenge.participants.length;
      final cooperationBonus = (participantCount * 10).clamp(0, 40);

      // 속도 보너스 계산 (기간의 50% 내 완료 시 30점)
      final now = DateTime.now();
      final totalDuration = challenge.endDate.difference(challenge.startDate);
      final elapsedDuration = now.difference(challenge.startDate);
      final isEarlyCompletion = elapsedDuration.inSeconds < (totalDuration.inSeconds * 0.5);
      final speedBonus = isEarlyCompletion ? 30 : 0;

      // 각 참가자에게 점수 부여
      for (final oderId in challenge.participants) {
        final userDistance = userDistances[oderId] ?? 0;

        // 기여하지 않은 참가자는 점수 없음
        if (userDistance <= 0) continue;

        // 점수 계산
        final baseScore = (userDistance * 10).round(); // 기본 점수
        const completionBonus = 50; // 완료 보너스
        final totalScore = baseScore + completionBonus + cooperationBonus + speedBonus;

        // users 컬렉션의 logRunScore 필드 업데이트
        final userRef = firestore.collection(FirebaseConfig.usersCollection).doc(oderId);
        transaction.update(userRef, {
          'logRunScore': FieldValue.increment(totalScore),
          'logRunCompletedCount': FieldValue.increment(1),
        });

        AppLogger.info(
          'FirestoreLogRunDataSource',
          '통나무런 점수 부여: userId=$oderId, 기본=$baseScore, 완료=$completionBonus, 협력=$cooperationBonus, 속도=$speedBonus, 총=$totalScore',
        );
      }
    } catch (e) {
      AppLogger.error('FirestoreLogRunDataSource', '점수 부여 실패', e);
      // 점수 부여 실패해도 챌린지 완료는 진행
    }
  }
}
