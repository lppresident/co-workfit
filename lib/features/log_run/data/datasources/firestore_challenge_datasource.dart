import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/data/models/challenge_model.dart';
import 'package:co_workfit/features/log_run/data/models/contribution_model.dart';
import 'package:co_workfit/features/log_run/data/models/participant_stats_model.dart';
import 'package:co_workfit/features/log_run/data/models/challenge_invite_model.dart';
import 'package:co_workfit/features/log_run/data/models/challenge_archive_model.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/participant_stats_entity.dart';
import 'package:co_workfit/features/log_run/domain/utils/invite_code_generator.dart';
import 'package:co_workfit/features/log_run/domain/utils/workout_converter.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/core/utils/logger.dart';

class FirestoreChallengeDataSource {
  final FirebaseFirestore firestore;
  static const String _challengesCollection = 'challenges';
  static const String _contributionsSubcollection = 'contributions';
  static const String _invitesCollection = 'challenge_invites';

  FirestoreChallengeDataSource({required this.firestore});

  /// 챌린지 생성 (단일 날짜)
  Future<ChallengeModel> createChallenge({
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
    return ChallengeModel.fromFirestore(doc);
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
  Future<ContributionModel> submitWorkout({
    required String challengeId,
    required String userId,
    required String userNickname,
    required WorkoutEntity workout,
  }) async {
    return await firestore.runTransaction<ContributionModel>((transaction) async {
      final challengeRef = firestore.collection(_challengesCollection).doc(challengeId);
      final challengeDoc = await transaction.get(challengeRef);
      if (!challengeDoc.exists) throw Exception('챌린지를 찾을 수 없습니다');

      final challenge = ChallengeModel.fromFirestore(challengeDoc);

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
        updateData['isSuccess'] = true; // 완료 = 성공
        // TTL: 7일 후 자동 삭제를 위한 expireAt 필드 설정
        updateData['expireAt'] = Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        );
      }

      transaction.update(challengeRef, updateData);

      // 기여 기록 추가
      // workout 상세는 /workouts/{workoutId}에서 조회 가능
      // workoutType, workoutDate는 피드 표시용 캐시
      final contributionRef = challengeRef.collection(_contributionsSubcollection).doc();
      final now = DateTime.now();
      transaction.set(contributionRef, {
        'challengeId': challengeId,
        'userId': userId,
        'userNickname': userNickname,
        'workoutId': workout.id,
        'contributionValue': contributionKg,
        'workoutType': workout.type.toString().split('.').last,
        'workoutDate': Timestamp.fromDate(workout.startTime),
        'submittedAt': Timestamp.fromDate(now),
        'percentage': percentage,
      });

      // 완료 시 재화는 앱 실행 시 정산 시스템에서 처리됨

      return ContributionModel(
        id: contributionRef.id,
        challengeId: challengeId,
        userId: userId,
        userNickname: userNickname,
        workoutId: workout.id,
        contributionValue: contributionKg,
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

      final challenge = ChallengeModel.fromFirestore(challengeDoc);
      final contribution = ContributionModel.fromFirestore(contributionDoc);

      // 본인 기록만 삭제 가능 (또는 방장)
      if (contribution.userId != userId && challenge.createdBy != userId) {
        throw Exception('본인의 기록만 삭제할 수 있습니다');
      }

      // 이미 완료된 챌린지의 기록은 삭제 불가
      if (challenge.isCompleted) {
        throw Exception('완료된 챌린지의 기록은 삭제할 수 없습니다');
      }

      // 챌린지 무게 업데이트
      final newCurrentWeight = (challenge.currentWeight - contribution.contributionValue).clamp(0.0, double.infinity);
      final newRemainingWeight = challenge.targetWeight - newCurrentWeight;

      // ParticipantStats 업데이트
      final contributorId = contribution.userId;
      final isRunning = contribution.workoutType == WorkoutType.running;
      final currentStats = challenge.participantStats[contributorId] ?? ParticipantStatsEntity.empty(contributorId);
      final updatedStats = currentStats.removeContribution(
        contributionKg: contribution.contributionValue,
        isRunning: isRunning,
      );
      final updatedStatsMap = Map<String, Map<String, dynamic>>.from(
        challenge.participantStats.map((key, value) => MapEntry(key, ParticipantStatsModel.fromEntity(value).toJson())),
      );
      updatedStatsMap[contributorId] = ParticipantStatsModel.fromEntity(updatedStats).toJson();

      transaction.update(challengeRef, {
        'currentWeight': newCurrentWeight,
        'remainingWeight': newRemainingWeight,
        'participantStats': updatedStatsMap,
      });

      // 기여 기록 삭제
      transaction.delete(contributionRef);
    });
  }

  /// 모든 챌린지 목록 조회 (활성, 완료, 만료 모두 포함)
  /// 만료된 active 챌린지는 자동으로 expired 상태로 업데이트
  Future<List<ChallengeModel>> getAllChallenges(String userId) async {
    AppLogger.info('LogRunDataSource', '=== 전체 챌린지 조회 시작 ===');
    
    // 사용자가 참여한 모든 챌린지 조회 (status 필터 없이)
    final query = await firestore
        .collection(_challengesCollection)
        .where('participants', arrayContains: userId)
        .get();
    
    AppLogger.info('LogRunDataSource', '조회된 전체 챌린지 수: ${query.docs.length}');
    
    final challenges = <ChallengeModel>[];
    
    for (final doc in query.docs) {
      var challenge = ChallengeModel.fromFirestore(doc);
      
      // active 상태인데 만료된 경우 → expired로 업데이트
      if (challenge.status == ChallengeStatus.active && challenge.isExpired) {
        AppLogger.info('LogRunDataSource', '만료 처리: ${challenge.id}');
        await _markChallengeAsExpired(challenge);
        // 업데이트된 상태로 챌린지 재생성 (성공 여부 포함)
        final isSuccess = challenge.currentWeight >= challenge.targetWeight;
        challenge = challenge.copyWith(
          status: ChallengeStatus.expired,
          isSuccess: isSuccess,
        );
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
  
  /// 챌린지를 만료 상태로 변경하고 성공 여부 저장
  Future<void> _markChallengeAsExpired(ChallengeModel challenge) async {
    try {
      // 성공 여부 계산: currentWeight >= targetWeight
      final isSuccess = challenge.currentWeight >= challenge.targetWeight;

      await firestore.collection(_challengesCollection).doc(challenge.id).update({
        'status': ChallengeStatus.expired.toFirestore(),
        'isSuccess': isSuccess,
      });

      AppLogger.info(
        'LogRunDataSource',
        '챌린지 만료 처리 완료: ${challenge.id} (성공: $isSuccess, ${challenge.currentWeight}/${challenge.targetWeight}kg)',
      );
    } catch (e) {
      AppLogger.error('LogRunDataSource', '챌린지 만료 처리 실패', e);
    }
  }

  /// 챌린지 상세 조회
  Future<ChallengeModel> getChallengeById(String challengeId) async {
    final doc = await firestore.collection(_challengesCollection).doc(challengeId).get();
    if (!doc.exists) throw Exception('챌린지를 찾을 수 없습니다');
    return ChallengeModel.fromFirestore(doc);
  }

  /// 초대 코드로 챌린지 조회
  Future<ChallengeModel> getChallengeByInviteCode(String inviteCode) async {
    final query = await firestore
        .collection(_challengesCollection)
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('초대 코드가 유효하지 않습니다');
    }

    return ChallengeModel.fromFirestore(query.docs.first);
  }

  /// 챌린지 기여 내역 조회
  Future<List<ContributionModel>> getChallengeContributions(String challengeId) async {
    final query = await firestore
        .collection(_challengesCollection)
        .doc(challengeId)
        .collection(_contributionsSubcollection)
        .orderBy('submittedAt', descending: true)
        .get();
    return query.docs.map((doc) => ContributionModel.fromFirestore(doc)).toList();
  }

  /// 챌린지 실시간 감시
  Stream<ChallengeModel> watchChallenge(String challengeId) {
    return firestore
        .collection(_challengesCollection)
        .doc(challengeId)
        .snapshots()
        .map((doc) => ChallengeModel.fromFirestore(doc));
  }

  /// 기여 내역 실시간 감시
  Stream<List<ContributionModel>> watchContributions(String challengeId) {
    return firestore
        .collection(_challengesCollection)
        .doc(challengeId)
        .collection(_contributionsSubcollection)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ContributionModel.fromFirestore(doc)).toList());
  }

  /// 챌린지 삭제 (방장만 가능)
  Future<void> deleteChallenge({
    required String challengeId,
    required String userId,
  }) async {
    final challengeRef = firestore.collection(_challengesCollection).doc(challengeId);
    final challengeDoc = await challengeRef.get();
    if (!challengeDoc.exists) throw Exception('챌린지를 찾을 수 없습니다');

    final challenge = ChallengeModel.fromFirestore(challengeDoc);
    if (challenge.createdBy != userId) {
      throw Exception('방장만 챌린지를 삭제할 수 있습니다');
    }

    // 기여 내역 모두 삭제
    final contributions = await challengeRef.collection(_contributionsSubcollection).get();
    for (final doc in contributions.docs) {
      await doc.reference.delete();
    }

    // 해당 챌린지 관련 초대 모두 삭제
    final invites = await firestore
        .collection(_invitesCollection)
        .where('challengeId', isEqualTo: challengeId)
        .get();
    for (final doc in invites.docs) {
      await doc.reference.delete();
    }

    // 챌린지 삭제
    await challengeRef.delete();

    AppLogger.info('FirestoreChallengeDataSource', '챌린지 및 관련 초대 삭제 완료: $challengeId (기여: ${contributions.docs.length}개, 초대: ${invites.docs.length}개)');
  }

  /// 특정 운동이 제출된 챌린지 목록 조회
  /// Collection Group Query를 사용하여 모든 챌린지의 contributions에서 검색
  /// 반환: 해당 운동이 제출된 챌린지 ID 목록
  Future<List<String>> getChallengesByWorkoutId(String workoutId) async {
    try {
      // Collection Group Query: 모든 challenges의 contributions 서브컬렉션에서 검색
      final query = await firestore
          .collectionGroup(_contributionsSubcollection)
          .where('workoutId', isEqualTo: workoutId)
          .get();

      // 중복 제거하여 챌린지 ID 목록 반환
      final challengeIds = <String>{};
      for (final doc in query.docs) {
        // 경로: challenges/{challengeId}/contributions/{contributionId}
        final pathSegments = doc.reference.path.split('/');
        if (pathSegments.length >= 2) {
          final challengeId = pathSegments[1]; // challenges 다음 세그먼트
          challengeIds.add(challengeId);
        }
      }

      AppLogger.info('FirestoreChallengeDataSource', 
        '운동 $workoutId가 제출된 챌린지: ${challengeIds.length}개');
      return challengeIds.toList();
    } catch (e) {
      AppLogger.error('FirestoreChallengeDataSource', 
        'getChallengesByWorkoutId 실패', e);
      rethrow;
    }
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
      final challengeId = doc.id;

      // 기여 내역 삭제
      final contributions = await challengeRef.collection(_contributionsSubcollection).get();
      for (final contribDoc in contributions.docs) {
        await contribDoc.reference.delete();
      }

      // 해당 챌린지 관련 초대 삭제
      final invites = await firestore
          .collection(_invitesCollection)
          .where('challengeId', isEqualTo: challengeId)
          .get();
      for (final inviteDoc in invites.docs) {
        await inviteDoc.reference.delete();
      }

      // 챌린지 삭제
      await challengeRef.delete();
      deletedCount++;
    }

    if (deletedCount > 0) {
      AppLogger.info('FirestoreChallengeDataSource', '보관 기간이 지난 챌린지 $deletedCount개 삭제됨 (초대 포함)');
    }

    return deletedCount;
  }

  // ========== Challenge Invite Methods ==========

  /// 챌린지 초대 생성 (친구에게 직접 초대)
  Future<void> createChallengeInvites({
    required String challengeId,
    required String challengeName,
    required String inviterId,
    required String inviterNickname,
    required List<String> inviteeIds,
    required double targetWeight,
    required DateTime startDate,
    required DateTime endDate,
    required int participantCount,
  }) async {
    final batch = firestore.batch();
    final now = DateTime.now();

    for (final inviteeId in inviteeIds) {
      final inviteRef = firestore.collection(_invitesCollection).doc();

      batch.set(inviteRef, {
        'challengeId': challengeId,
        'challengeName': challengeName,
        'inviterId': inviterId,
        'inviterNickname': inviterNickname,
        'inviteeId': inviteeId,
        'createdAt': Timestamp.fromDate(now),
        'status': 'pending',
        'targetWeight': targetWeight,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'participantCount': participantCount,
      });
    }

    await batch.commit();
    AppLogger.info('FirestoreChallengeDataSource', '챌린지 초대 ${inviteeIds.length}개 생성 완료');
  }

  /// 내가 받은 챌린지 초대 목록 조회
  Future<List<ChallengeInviteModel>> getMyInvites(String userId) async {
    final query = await firestore
        .collection(_invitesCollection)
        .where('inviteeId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => ChallengeInviteModel.fromFirestore(doc)).toList();
  }

  /// 특정 챌린지의 초대된 사용자 ID 목록 조회
  Future<List<String>> getChallengeInvitedUserIds(String challengeId) async {
    final query = await firestore
        .collection(_invitesCollection)
        .where('challengeId', isEqualTo: challengeId)
        .where('status', isEqualTo: 'pending')
        .get();

    return query.docs
        .map((doc) => (doc.data()['inviteeId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// 내가 받은 챌린지 초대 실시간 스트림
  Stream<List<ChallengeInviteModel>> watchMyInvites(String userId) {
    return firestore
        .collection(_invitesCollection)
        .where('inviteeId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          // Firestore에서 가져온 후 메모리에서 정렬
          final invites = snapshot.docs
              .map((doc) => ChallengeInviteModel.fromFirestore(doc))
              .toList();
          invites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return invites;
        });
  }

  /// 챌린지 초대 수락
  Future<void> acceptInvite({
    required String inviteId,
    required String userId,
    required String userNickname,
  }) async {
    // 초대 정보 조회
    final inviteDoc = await firestore.collection(_invitesCollection).doc(inviteId).get();

    if (!inviteDoc.exists) {
      throw Exception('초대를 찾을 수 없습니다');
    }

    final invite = ChallengeInviteModel.fromFirestore(inviteDoc);

    // 트랜잭션으로 챌린지 참가 + 초대 삭제
    await firestore.runTransaction((transaction) async {
      final challengeRef = firestore.collection(_challengesCollection).doc(invite.challengeId);
      final challengeDoc = await transaction.get(challengeRef);

      if (!challengeDoc.exists) {
        throw Exception('챌린지를 찾을 수 없습니다');
      }

      // 챌린지에 참가자 추가
      transaction.update(challengeRef, {
        'participants': FieldValue.arrayUnion([userId]),
        'participantNicknames.$userId': userNickname,
      });

      // 초대 삭제 (accepted 상태로 변경하지 않음)
      transaction.delete(inviteDoc.reference);
    });

    AppLogger.info('FirestoreChallengeDataSource', '챌린지 초대 수락: $inviteId');
  }

  /// 챌린지 초대 거절
  Future<void> rejectInvite({
    required String inviteId,
  }) async {
    // 거절 시 초대 문서 삭제
    await firestore.collection(_invitesCollection).doc(inviteId).delete();

    AppLogger.info('FirestoreChallengeDataSource', '챌린지 초대 거절 및 삭제: $inviteId');
  }

  // ========== Private Methods ==========

  /// 사용자의 만료된 챌린지들을 일괄 처리
  /// 정산 전에 호출하여 정산 시 올바른 isSuccess 값을 사용할 수 있도록 함
  /// 만료된 챌린지의 초대도 함께 정리함
  /// 7일 이상 지난 챌린지는 아카이브로 변환 후 삭제함
  Future<int> markExpiredChallenges(String userId) async {
    try {
      AppLogger.info('LogRunDataSource', '=== 만료된 챌린지 일괄 처리 시작 ===');

      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // 1. 사용자가 참여한 active 상태 챌린지 조회
      final activeQuery = await firestore
          .collection(_challengesCollection)
          .where('participants', arrayContains: userId)
          .where('status', isEqualTo: 'active')
          .get();

      int expiredCount = 0;
      int deletedInvitesCount = 0;
      final expiredChallengeIds = <String>[];

      for (final doc in activeQuery.docs) {
        final challenge = ChallengeModel.fromFirestore(doc);

        // 만료된 챌린지만 처리
        if (challenge.isExpired) {
          final isSuccess = challenge.currentWeight >= challenge.targetWeight;

          await firestore.collection(_challengesCollection).doc(challenge.id).update({
            'status': ChallengeStatus.expired.toFirestore(),
            'isSuccess': isSuccess,
          });

          expiredCount++;
          expiredChallengeIds.add(challenge.id);
          AppLogger.info(
            'LogRunDataSource',
            '챌린지 만료 처리: ${challenge.id} (성공: $isSuccess, ${challenge.currentWeight}/${challenge.targetWeight}kg)',
          );
        }
      }

      // 2. 만료된 챌린지의 초대 삭제
      if (expiredChallengeIds.isNotEmpty) {
        for (final challengeId in expiredChallengeIds) {
          final invites = await firestore
              .collection(_invitesCollection)
              .where('challengeId', isEqualTo: challengeId)
              .get();

          for (final inviteDoc in invites.docs) {
            await inviteDoc.reference.delete();
            deletedInvitesCount++;
          }
        }
      }

      // 3. 7일 이상 지난 완료/만료 챌린지를 아카이브로 변환 후 삭제
      final oldChallengesQuery = await firestore
          .collection(_challengesCollection)
          .where('participants', arrayContains: userId)
          .where('endDate', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      int archivedCount = 0;
      for (final doc in oldChallengesQuery.docs) {
        final challenge = ChallengeModel.fromFirestore(doc);

        // completed 또는 expired 상태만 아카이브
        if (challenge.status == ChallengeStatus.completed ||
            challenge.status == ChallengeStatus.expired) {

          // 아카이브 문서 생성 (users/{userId}/challenge_archives/{challengeId})
          // Note: 달성량, 참가자 수, 기여도는 workout 기록에서 조회 가능하므로 저장하지 않음
          await firestore
              .collection('users')
              .doc(userId)
              .collection('challenge_archives')
              .doc(challenge.id)
              .set({
            'challengeId': challenge.id,
            'isSuccess': challenge.isSuccess ?? (challenge.currentWeight >= challenge.targetWeight),
            'targetWeight': challenge.targetWeight,
            'endDate': Timestamp.fromDate(challenge.endDate),
            'archivedAt': FieldValue.serverTimestamp(),
          });

          // 기여 기록 삭제
          final contributions = await firestore
              .collection(_challengesCollection)
              .doc(challenge.id)
              .collection('contributions')
              .get();

          for (final contribDoc in contributions.docs) {
            await contribDoc.reference.delete();
          }

          // 초대 삭제
          final invites = await firestore
              .collection(_invitesCollection)
              .where('challengeId', isEqualTo: challenge.id)
              .get();

          for (final inviteDoc in invites.docs) {
            await inviteDoc.reference.delete();
          }

          // 챌린지 삭제
          await firestore.collection(_challengesCollection).doc(challenge.id).delete();

          archivedCount++;
          AppLogger.info(
            'LogRunDataSource',
            '챌린지 아카이브: ${challenge.id} (${challenge.currentWeight}/${challenge.targetWeight}kg)',
          );
        }
      }

      AppLogger.info(
        'LogRunDataSource',
        '=== 만료된 챌린지 일괄 처리 완료: 만료 $expiredCount개, 아카이브 $archivedCount개 (초대 $deletedInvitesCount개 정리) ===',
      );

      return expiredCount;
    } catch (e, stackTrace) {
      AppLogger.error('LogRunDataSource', '만료된 챌린지 일괄 처리 실패', e, stackTrace);
      rethrow;
    }
  }

  /// 사용자의 챌린지 아카이브 조회
  Future<List<ChallengeArchiveModel>> getChallengeArchives(String userId) async {
    try {
      final archivesSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('challenge_archives')
          .orderBy('endDate', descending: true)
          .get();

      final archives = archivesSnapshot.docs
          .map((doc) => ChallengeArchiveModel.fromFirestore(doc.data()))
          .toList();

      AppLogger.info('LogRunDataSource', '챌린지 아카이브 조회: ${archives.length}개');
      return archives;
    } catch (e, stackTrace) {
      AppLogger.error('LogRunDataSource', '챌린지 아카이브 조회 실패', e, stackTrace);
      rethrow;
    }
  }

  // ========== Private Methods ==========

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }
}
