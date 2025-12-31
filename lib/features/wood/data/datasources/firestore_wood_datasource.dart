import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/features/wood/data/models/wood_settlement_model.dart';
import 'package:co_workfit/features/wood/data/models/wood_summary_model.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_reward_constants.dart';
import 'package:co_workfit/features/wood/domain/repositories/wood_repository.dart';
import 'package:intl/intl.dart';

/// Firestore 통나무 재화 DataSource
class FirestoreWoodDataSource {
  final FirebaseFirestore firestore;

  // Collection 경로
  static const String _usersCollection = 'users';
  static const String _woodSummaryDoc = 'wood_summary';
  static const String _woodSettlementsCollection = 'wood_settlements';
  static const String _challengesCollection = 'log_run_challenges';
  static const String _contributionsSubcollection = 'contributions';
  static const String _workoutsCollection = 'workouts';

  FirestoreWoodDataSource({required this.firestore});

  // ========== Wood Summary ==========

  /// 통나무 보유 현황 조회
  Future<WoodSummaryModel> getWoodSummary(String userId) async {
    try {
      final doc = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('data')
          .doc(_woodSummaryDoc)
          .get();

      if (!doc.exists) {
        return WoodSummaryModel.initial();
      }

      return WoodSummaryModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '통나무 현황 조회 실패', e);
      return WoodSummaryModel.initial();
    }
  }

  /// 통나무 보유 현황 업데이트
  Future<void> updateWoodSummary(String userId, WoodSummaryModel summary) async {
    try {
      await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('data')
          .doc(_woodSummaryDoc)
          .set(summary.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '통나무 현황 업데이트 실패', e);
      rethrow;
    }
  }

  /// 통나무 추가 (정산 시)
  Future<void> addWood(String userId, int amount, String settlementDate) async {
    try {
      await firestore.runTransaction((transaction) async {
        final summaryRef = firestore
            .collection(_usersCollection)
            .doc(userId)
            .collection('data')
            .doc(_woodSummaryDoc);

        final summaryDoc = await transaction.get(summaryRef);
        final currentSummary = summaryDoc.exists
            ? WoodSummaryModel.fromFirestore(summaryDoc)
            : WoodSummaryModel.initial();

        final updatedSummary = WoodSummaryModel(
          totalWood: currentSummary.totalWood + amount,
          lifetimeEarned: currentSummary.lifetimeEarned + amount,
          lastSettlementDate: settlementDate,
        );

        transaction.set(summaryRef, updatedSummary.toFirestore());
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
        final summaryRef = firestore
            .collection(_usersCollection)
            .doc(userId)
            .collection('data')
            .doc(_woodSummaryDoc);

        final summaryDoc = await transaction.get(summaryRef);
        if (!summaryDoc.exists) {
          throw Exception('통나무 현황 정보가 없습니다');
        }

        final currentSummary = WoodSummaryModel.fromFirestore(summaryDoc);
        if (currentSummary.totalWood < amount) {
          throw Exception(
              '통나무가 부족합니다. 보유: ${currentSummary.totalWood}, 필요: $amount');
        }

        transaction.update(summaryRef, {
          'totalWood': FieldValue.increment(-amount),
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

  /// 정산 기록 목록 조회 (최근순)
  Future<List<WoodSettlementModel>> getSettlements(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final query = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_woodSettlementsCollection)
          .orderBy('settledAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => WoodSettlementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '정산 목록 조회 실패', e);
      return [];
    }
  }

  /// 미정산 날짜 목록 조회
  Future<List<String>> getPendingSettlementDates(String userId) async {
    try {
      // 1. 마지막 정산일 조회
      final summary = await getWoodSummary(userId);
      final lastSettlementDate = summary.lastSettlementDate;

      // 2. 시작일 결정 (마지막 정산일 다음날 또는 7일 전)
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      
      DateTime startDate;
      if (lastSettlementDate != null) {
        final lastDate = DateTime.parse(lastSettlementDate);
        startDate = lastDate.add(const Duration(days: 1));
      } else {
        // 최초 정산: 7일 전부터
        startDate = yesterday
            .subtract(Duration(days: WoodRewardConstants.settlementExpirationDays));
      }

      // 3. 미정산 날짜 목록 생성
      final pendingDates = <String>[];
      final dateFormat = DateFormat('yyyy-MM-dd');
      
      var currentDate = startDate;
      while (!currentDate.isAfter(yesterday)) {
        pendingDates.add(dateFormat.format(currentDate));
        currentDate = currentDate.add(const Duration(days: 1));
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
      // 날짜 파싱
      final targetDate = DateTime.parse(date);
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // 해당 날짜에 종료된 챌린지 조회
      final query = await firestore
          .collection(_challengesCollection)
          .where('participants', arrayContains: userId)
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('endDate', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final challenges = <ChallengeSettlementData>[];

      for (final doc in query.docs) {
        final data = doc.data();
        final challengeId = doc.id;

        // 기여 내역 조회
        final contributionsQuery = await firestore
            .collection(_challengesCollection)
            .doc(challengeId)
            .collection(_contributionsSubcollection)
            .get();

        // 참가자별 기여 거리 계산
        final participantContributions = <String, double>{};
        double userContribution = 0;
        double userTotalWorkoutDistance = 0;
        bool isFirstContribution = true;

        for (final contribDoc in contributionsQuery.docs) {
          final contribData = contribDoc.data();
          final oderId = contribData['userId'] as String;
          final distance = (contribData['distance'] as num).toDouble();

          participantContributions[oderId] =
              (participantContributions[oderId] ?? 0) + distance;

          if (oderId == userId) {
            userContribution += distance;
            userTotalWorkoutDistance += distance;
            if (isFirstContribution) {
              isFirstContribution = false;
            }
          }
        }

        // MVP 결정 (기여도 1위)
        String? mvpUserId;
        double maxContribution = 0;
        for (final entry in participantContributions.entries) {
          if (entry.value > maxContribution) {
            maxContribution = entry.value;
            mvpUserId = entry.key;
          }
        }

        final targetDistance = (data['targetDistance'] as num).toDouble();
        final currentDistance = (data['currentDistance'] as num).toDouble();
        final status = data['status'] as String;
        final isSuccess = status == 'completed';
        final endDate = (data['endDate'] as Timestamp).toDate();
        final participants = List<String>.from(data['participants'] ?? []);

        challenges.add(ChallengeSettlementData(
          challengeId: challengeId,
          challengeName: '${targetDistance.toStringAsFixed(0)}km 챌린지',
          targetDistance: targetDistance,
          achievedDistance: currentDistance,
          isSuccess: isSuccess,
          endDate: endDate,
          participantCount: participants.length,
          participantContributions: participantContributions,
          userContribution: userContribution,
          isUserMvp: mvpUserId == userId,
          userTotalWorkoutDistance: userTotalWorkoutDistance,
          isFirstContribution: !isFirstContribution, // 기여가 있으면 첫 기여 아님
        ));
      }

      return challenges;
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '챌린지 조회 실패', e);
      return [];
    }
  }

  /// 사용자의 챌린지 기여 정보 조회
  Future<UserChallengeContribution> getUserContribution(
    String userId,
    String challengeId,
  ) async {
    try {
      final query = await firestore
          .collection(_challengesCollection)
          .doc(challengeId)
          .collection(_contributionsSubcollection)
          .where('userId', isEqualTo: userId)
          .get();

      double totalDistance = 0;
      for (final doc in query.docs) {
        totalDistance += (doc.data()['distance'] as num).toDouble();
      }

      return UserChallengeContribution(
        totalDistance: totalDistance,
        contributionCount: query.docs.length,
        isFirst: query.docs.isEmpty,
      );
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '기여 정보 조회 실패', e);
      return const UserChallengeContribution(
        totalDistance: 0,
        contributionCount: 0,
        isFirst: true,
      );
    }
  }

  /// 해당 날짜가 사용자의 첫 운동인지 확인
  Future<bool> isFirstWorkoutOfDay(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // 해당 날짜의 운동 기록 조회
      final query = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_workoutsCollection)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(2)
          .get();

      // 운동이 1개만 있으면 첫 운동
      return query.docs.length <= 1;
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '첫 운동 확인 실패', e);
      return false;
    }
  }

  /// 해당 챌린지에서 사용자의 첫 기여인지 확인
  Future<bool> isFirstContribution(String userId, String challengeId) async {
    try {
      final query = await firestore
          .collection(_challengesCollection)
          .doc(challengeId)
          .collection(_contributionsSubcollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return query.docs.isEmpty;
    } catch (e) {
      AppLogger.error('FirestoreWoodDataSource', '첫 기여 확인 실패', e);
      return true;
    }
  }
}

