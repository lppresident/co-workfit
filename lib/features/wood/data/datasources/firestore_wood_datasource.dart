import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/features/wood/data/models/wood_settlement_model.dart';
import 'package:co_workfit/features/wood/data/models/wood_summary_model.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_reward_constants.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';
import 'package:co_workfit/features/wood/domain/repositories/wood_repository.dart';
import 'package:intl/intl.dart';

/// Firestore 통나무 재화 DataSource
class FirestoreWoodDataSource {
  final FirebaseFirestore firestore;

  // Collection 경로
  static const String _usersCollection = 'users';
  static const String _woodSettlementsCollection = 'wood_settlements';
  static const String _challengesCollection = 'log_run_challenges';
  static const String _contributionsSubcollection = 'contributions';
  static const String _workoutsCollection = 'workouts';

  FirestoreWoodDataSource({required this.firestore});

  // ========== Wood Summary ==========

  /// 통나무 보유 현황 조회 (사용자 문서에서 직접 조회)
  Future<WoodSummaryModel> getWoodSummary(String userId) async {
    try {
      final doc = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return WoodSummaryModel.initial();
      }

      final data = doc.data()!;
      return WoodSummaryModel(
        totalWood: (data['woodAmount'] as num?)?.toInt() ?? 0,
        lifetimeEarned: (data['woodLifetimeEarned'] as num?)?.toInt() ?? 0,
        lastSettlementDate: data['lastWoodSettlementDate'] as String?,
      );
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '통나무 현황 조회 실패', e);
      return WoodSummaryModel.initial();
    }
  }

  /// 통나무 보유 현황 업데이트 (사용자 문서에 직접 저장)
  Future<void> updateWoodSummary(String userId, WoodSummaryModel summary) async {
    try {
      await firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
            'woodAmount': summary.totalWood,
            'woodLifetimeEarned': summary.lifetimeEarned,
            'lastWoodSettlementDate': summary.lastSettlementDate,
          });
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '통나무 현황 업데이트 실패', e);
      rethrow;
    }
  }

  /// 통나무 추가 (정산 시) - 사용자 문서에 직접 저장
  Future<void> addWood(String userId, int amount, String settlementDate) async {
    try {
      final userRef = firestore.collection(_usersCollection).doc(userId);
      
      await userRef.update({
        'woodAmount': FieldValue.increment(amount),
        'woodLifetimeEarned': FieldValue.increment(amount),
        'lastWoodSettlementDate': settlementDate,
      });

      AppLogger.info(
        'FirestoreWoodDataSource',
        '통나무 $amount개 추가 (userId: $userId, date: $settlementDate)',
      );
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '통나무 추가 실패', e);
      rethrow;
    }
  }

  /// 통나무 사용 (제작 시)
  Future<void> useWood(String userId, int amount) async {
    try {
      await firestore.runTransaction((transaction) async {
        final userRef = firestore.collection(_usersCollection).doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('사용자 정보가 없습니다');
        }

        final currentAmount = (userDoc.data()?['woodAmount'] as num?)?.toInt() ?? 0;
        if (currentAmount < amount) {
          throw Exception(
              '통나무가 부족합니다. 보유: $currentAmount, 필요: $amount');
        }

        transaction.update(userRef, {
          'woodAmount': FieldValue.increment(-amount),
        });
      });

      AppLogger.info(
        'FirestoreWoodDataSource',
        '통나무 $amount개 사용 (userId: $userId)',
      );
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '통나무 사용 실패', e);
      rethrow;
    }
  }

  // ========== Wood Settlements ==========

  /// 정산 기록 저장
  Future<void> saveSettlement(
      String userId, WoodSettlementModel settlement) async {
    try {
      await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_woodSettlementsCollection)
          .doc(settlement.settlementDate)
          .set(WoodSettlementModel.fromEntity(settlement).toFirestore());

      AppLogger.info(
        'FirestoreWoodDataSource',
        '정산 기록 저장 (userId: $userId, date: ${settlement.settlementDate})',
      );
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '정산 기록 저장 실패', e);
      rethrow;
    }
  }

  /// 특정 날짜의 정산 기록 조회
  Future<WoodSettlementModel?> getSettlement(String userId, String date) async {
    try {
      final doc = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_woodSettlementsCollection)
          .doc(date)
          .get();

      if (!doc.exists) {
        return null;
      }

      return WoodSettlementModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '정산 기록 조회 실패', e);
      return null;
    }
  }

  /// 정산 기록 목록 조회
  Future<List<WoodSettlementModel>> getSettlements(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final snapshot = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_woodSettlementsCollection)
          .orderBy('settledAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => WoodSettlementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '정산 기록 목록 조회 실패', e);
      return [];
    }
  }

  // ========== Pending Settlement Dates ==========

  /// 미정산 날짜 목록 조회
  Future<List<String>> getPendingSettlementDates(String userId) async {
    try {
      final summary = await getWoodSummary(userId);
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day - 1);

      // 마지막 정산일 파싱
      DateTime? lastSettlementDate;
      if (summary.lastSettlementDate != null) {
        try {
          lastSettlementDate = DateFormat('yyyy-MM-dd').parse(summary.lastSettlementDate!);
        } catch (e) {
          AppLogger.warning('FirestoreWoodDataSource', '마지막 정산일 파싱 실패: ${summary.lastSettlementDate}');
        }
      }

      // 정산 시작일 결정
      DateTime startDate;
      if (lastSettlementDate == null) {
        // 첫 정산: 30일 전부터 확인
        startDate = yesterday.subtract(const Duration(days: 30));
      } else {
        // 마지막 정산일 다음 날부터
        startDate = lastSettlementDate.add(const Duration(days: 1));
      }

      // 정산할 날짜가 없으면 빈 리스트 반환
      if (startDate.isAfter(yesterday)) {
        return [];
      }

      // 날짜 목록 생성
      final List<String> pendingDates = [];
      for (DateTime date = startDate;
          !date.isAfter(yesterday);
          date = date.add(const Duration(days: 1))) {
        pendingDates.add(DateFormat('yyyy-MM-dd').format(date));
      }

      return pendingDates;
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '미정산 날짜 조회 실패', e);
      return [];
    }
  }

  // ========== Challenge Data ==========

  /// 특정 날짜에 종료된 챌린지 목록 조회
  Future<List<ChallengeSettlementData>> getChallengesEndedOn(
    String userId,
    String date,
  ) async {
    try {
      final targetDate = DateFormat('yyyy-MM-dd').parse(date);
      final dayStart = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      // 해당 날짜에 완료된 챌린지들 조회 (사용자가 참여한 것만)
      final challengesSnapshot = await firestore
          .collection(_challengesCollection)
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: 'completed')
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('completedAt', isLessThan: Timestamp.fromDate(dayEnd))
          .get();

      final List<ChallengeSettlementData> result = [];

      for (final challengeDoc in challengesSnapshot.docs) {
        final data = challengeDoc.data();
        final challengeId = challengeDoc.id;

        // 참가자별 기여 거리 조회
        final contributionsSnapshot = await firestore
            .collection(_challengesCollection)
            .doc(challengeId)
            .collection(_contributionsSubcollection)
            .get();

        final Map<String, double> participantContributions = {};
        double userContribution = 0;
        int userContributionCount = 0;

        for (final contrib in contributionsSnapshot.docs) {
          final contribData = contrib.data();
          final oderId = contribData['userId'] as String;
          final distance = (contribData['distance'] as num).toDouble();
          
          participantContributions[oderId] = 
              (participantContributions[oderId] ?? 0) + distance;
          
          if (oderId == userId) {
            userContribution += distance;
            userContributionCount++;
          }
        }

        if (userContribution <= 0) continue;

        // MVP 확인 (기여도 1위)
        final sortedContributions = participantContributions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final isUserMvp = sortedContributions.isNotEmpty && 
            sortedContributions.first.key == userId;

        final targetDistance = (data['targetDistance'] as num).toDouble();
        final achievedDistance = (data['currentDistance'] as num).toDouble();
        final participantIds = data['participantIds'] as List<dynamic>;

        result.add(ChallengeSettlementData(
          challengeId: challengeId,
          challengeName: data['title'] as String? ?? '${targetDistance.toStringAsFixed(1)}km 챌린지',
          targetDistance: targetDistance,
          achievedDistance: achievedDistance,
          isSuccess: achievedDistance >= targetDistance,
          endDate: (data['completedAt'] as Timestamp).toDate(),
          participantCount: participantIds.length,
          participantContributions: participantContributions,
          userContribution: userContribution,
          isUserMvp: isUserMvp,
          userTotalWorkoutDistance: userContribution,
          isFirstContribution: userContributionCount == 1,
        ));
      }

      return result;
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '챌린지 데이터 조회 실패', e);
      return [];
    }
  }

  /// 사용자의 챌린지 기여 정보 조회
  Future<UserChallengeContribution> getUserContribution(
    String userId,
    String challengeId,
  ) async {
    try {
      final contributionsSnapshot = await firestore
          .collection(_challengesCollection)
          .doc(challengeId)
          .collection(_contributionsSubcollection)
          .where('userId', isEqualTo: userId)
          .get();

      double totalDistance = 0;
      for (final doc in contributionsSnapshot.docs) {
        totalDistance += (doc.data()['distance'] as num).toDouble();
      }

      return UserChallengeContribution(
        totalDistance: totalDistance,
        contributionCount: contributionsSnapshot.docs.length,
        isFirst: contributionsSnapshot.docs.length == 1,
      );
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '기여 정보 조회 실패', e);
      return const UserChallengeContribution(
        totalDistance: 0,
        contributionCount: 0,
        isFirst: false,
      );
    }
  }

  /// 해당 날짜가 사용자의 첫 운동인지 확인
  Future<bool> isFirstWorkoutOfDay(String userId, DateTime date) async {
    try {
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final snapshot = await firestore
          .collection(_workoutsCollection)
          .where('userId', isEqualTo: userId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('startTime', isLessThan: Timestamp.fromDate(dayEnd))
          .limit(2)
          .get();

      return snapshot.docs.length == 1;
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '첫 운동 확인 실패', e);
      return false;
    }
  }

  /// 해당 챌린지에서 사용자의 첫 기여인지 확인
  Future<bool> isFirstContribution(String userId, String challengeId) async {
    try {
      final snapshot = await firestore
          .collection(_challengesCollection)
          .doc(challengeId)
          .collection(_contributionsSubcollection)
          .where('userId', isEqualTo: userId)
          .limit(2)
          .get();

      return snapshot.docs.length == 1;
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '첫 기여 확인 실패', e);
      return false;
    }
  }
}
