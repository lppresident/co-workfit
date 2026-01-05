import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/data/models/log_run_challenge_model.dart';
import 'package:co_workfit/features/log_run/data/models/log_run_contribution_model.dart';
import 'package:co_workfit/features/log_run/data/models/participant_stats_model.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/participant_stats_entity.dart';
import 'package:co_workfit/features/log_run/domain/utils/invite_code_generator.dart';
import 'package:co_workfit/features/log_run/domain/utils/workout_converter.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/core/utils/logger.dart';

class FirestoreLogRunDataSource {
  final FirebaseFirestore firestore;
  static const String _challengesCollection = 'challenges';
  static const String _contributionsSubcollection = 'contributions';

  FirestoreLogRunDataSource({required this.firestore});

  /// 챌린지 생성 (단일 날짜)
  Future<LogRunChallengeModel> createChallenge({
    required String userId,
    required String userNickname,
    required double targetWeight,
    required DateTime challengeDate,
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

    // 단일 날짜: startDate와 endDate를 같은 날로 설정
    final startDate = DateTime(challengeDate.year, challengeDate.month, challengeDate.day);
    final endDate = DateTime(challengeDate.year, challengeDate.month, challengeDate.day, 23, 59, 59);

    await challengeRef.set({
      'createdBy': userId,
      'creatorNickname': userNickname,
      'targetWeight': targetWeight,
      'currentWeight': 0.0,
      'remainingWeight': targetWeight,
      'participants': [userId],
      'participantNicknames': {userId: userNickname},
      'participantStats': {}, // 빈 Map으로 초기화
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
    required WorkoutEntity workout,
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
          .where('workoutId', isEqualTo: workout.id)
          .limit(1)
          .get();

      if (existingContributions.docs.isNotEmpty) {
        throw Exception('이미 제출한 운동 기록입니다');
      }

      // 기간 검증: 운동 날짜가 시작일~종료일 사이인지 확인
      if (!challenge.isWorkoutDateValid(workout.startTime)) {
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

      // WorkoutConverter를 사용하여 kg 변환
      final contributionKg = WorkoutConverter.fromWorkout(workout);
      final isRunning = workout.type == WorkoutType.running;

      // 현재 무게 업데이트
      final newCurrentWeight = challenge.currentWeight + contributionKg;
      final newRemainingWeight = (challenge.targetWeight - newCurrentWeight).clamp(0.0, challenge.targetWeight);
      final percentage = contributionKg / challenge.targetWeight;
      final isNowCompleted = newCurrentWeight >= challenge.targetWeight;

      // ParticipantStats 업데이트
      final currentStats = challenge.participantStats[userId] ?? ParticipantStatsEntity.empty(userId);
      final updatedStats = currentStats.addContribution(
        contributionKg: contributionKg,
        isRunning: isRunning,
      );
      final updatedStatsMap = Map<String, Map<String, dynamic>>.from(
        challenge.participantStats.map((key, value) => MapEntry(key, ParticipantStatsModel.fromEntity(value).toJson())),
      );
      updatedStatsMap[userId] = ParticipantStatsModel.fromEntity(updatedStats).toJson();

      // 챌린지 업데이트
      final updateData = <String, dynamic>{
        'currentWeight': newCurrentWeight,
        'remainingWeight': newRemainingWeight,
        'participantStats': updatedStatsMap,
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
        'workoutId': workout.id,
        'contributionKg': contributionKg,
        'workoutType': workout.type.toString().split('.').last,
        'workoutDate': Timestamp.fromDate(workout.startTime),
        'submittedAt': Timestamp.fromDate(now),
        'percentage': percentage,
      });

      // 완료 시 재화는 앱 실행 시 정산 시스템에서 처리됨

      return LogRunContributionModel(
        id: contributionRef.id,
        challengeId: challengeId,
        userId: userId,
        userNickname: userNickname,
        workoutId: workout.id,
        distance: contributionKg, // 호환성을 위해 distance 필드에 kg 저장
        workoutType: workout.type,
        workoutDate: workout.startTime,
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

      // 챌린지 무게 업데이트
      final newCurrentWeight = (challenge.currentWeight - contribution.distance).clamp(0.0, double.infinity);
      final newRemainingWeight = challenge.targetWeight - newCurrentWeight;

      transaction.update(challengeRef, {
        'currentWeight': newCurrentWeight,
        'remainingWeight': newRemainingWeight,
      });

      // 기여 기록 삭제
      transaction.delete(contributionRef);
    });
  }

  /// 모든 챌린지 목록 조회 (활성, 완료, 만료 모두 포함)
  /// 만료된 active 챌린지는 자동으로 expired 상태로 업데이트
  Future<List<LogRunChallengeModel>> getAllChallenges(String userId) async {
    AppLogger.info('LogRunDataSource', '=== 전체 챌린지 조회 시작 ===');
    
    // 사용자가 참여한 모든 챌린지 조회 (status 필터 없이)
    final query = await firestore
        .collection(_challengesCollection)
        .where('participants', arrayContains: userId)
        .get();
    
    AppLogger.info('LogRunDataSource', '조회된 전체 챌린지 수: ${query.docs.length}');
    
    final challenges = <LogRunChallengeModel>[];
    
    for (final doc in query.docs) {
      var challenge = LogRunChallengeModel.fromFirestore(doc);
      
      // active 상태인데 만료된 경우 → expired로 업데이트
      if (challenge.status == ChallengeStatus.active && challenge.isExpired) {
        AppLogger.info('LogRunDataSource', '만료 처리: ${challenge.id}');
        await _markChallengeAsExpired(challenge.id);
        // 업데이트된 상태로 챌린지 재생성
        challenge = challenge.copyWith(status: ChallengeStatus.expired);
      }
      
      challenges.add(challenge);
    }
    
    // 정렬: active → completed → expired, 각 그룹 내에서는 최신순
    challenges.sort((a, b) {
      final statusOrder = {
        ChallengeStatus.active: 0,
        ChallengeStatus.completed: 1,
        ChallengeStatus.expired: 2,
      };
      final statusCompare = statusOrder[a.status]!.compareTo(statusOrder[b.status]!);
      if (statusCompare != 0) return statusCompare;
      return b.createdAt.compareTo(a.createdAt); // 최신순
    });
    
    AppLogger.info('LogRunDataSource', '=== 전체 챌린지 조회 완료: ${challenges.length}개 ===');
    return challenges;
  }
  
  /// 챌린지를 만료 상태로 변경
  Future<void> _markChallengeAsExpired(String challengeId) async {
    try {
      await firestore.collection(_challengesCollection).doc(challengeId).update({
        'status': ChallengeStatus.expired.toFirestore(),
      });
      AppLogger.info('LogRunDataSource', '챌린지 만료 처리 완료: $challengeId');
    } catch (e) {
      AppLogger.error('LogRunDataSource', '챌린지 만료 처리 실패', e);
    }
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
}
