import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/domain/entities/challenge_settlement_data.dart';
import 'package:co_workfit/features/currency/data/models/currency_summary_model.dart';
import 'package:co_workfit/features/currency/data/models/settlement_model.dart';
import 'package:co_workfit/features/log_run/domain/entities/workout_type.dart';

/// Firestore 재화 데이터 관리
class FirestoreCurrencyDataSource {
  final FirebaseFirestore firestore;

  static const String _usersCollection = 'users';
  static const String _settlementsCollection = 'settlements';
  static const String _challengesCollection = 'challenges';
  static const String _workoutsCollection = 'workouts';

  FirestoreCurrencyDataSource({required this.firestore});

  // ========== Summary ==========

  /// 재화 보유 현황 조회
  Future<CurrencySummaryModel> getCurrencySummary(String userId) async {
    try {
      final doc = await firestore.collection(_usersCollection).doc(userId).get();

      if (!doc.exists || doc.data() == null) {
        return CurrencySummaryModel(
          amounts: {for (final type in CurrencyType.values) type: 0},
          lifetimeEarned: {for (final type in CurrencyType.values) type: 0},
        );
      }

      return CurrencySummaryModel.fromFirestore(doc.data()!);
    } catch (e) {
      AppLogger.error('CurrencyDS', 'getCurrencySummary failed', e);
      rethrow;
    }
  }

  /// 재화 보유 현황 업데이트
  Future<void> updateCurrencySummary(
    String userId,
    CurrencySummaryModel summary,
  ) async {
    try {
      await firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(summary.toFirestore(), SetOptions(merge: true));

      AppLogger.info('CurrencyDS', 'Currency summary updated');
    } catch (e) {
      AppLogger.error('CurrencyDS', 'updateCurrencySummary failed', e);
      rethrow;
    }
  }

  /// 여러 재화 한 번에 추가
  Future<void> addCurrencies(
    String userId,
    Map<CurrencyType, int> amounts,
    String settlementDate,
  ) async {
    try {
      final userRef = firestore.collection(_usersCollection).doc(userId);

      await firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        final data = doc.data() ?? {};

        final updates = <String, dynamic>{
          'lastSettlementDate': Timestamp.fromDate(DateTime.parse(settlementDate)),
        };

        for (final entry in amounts.entries) {
          if (entry.value > 0) {
            final type = entry.key;
            final currentAmount = (data['${type.name}Amount'] as int?) ?? 0;
            final currentLifetime = (data['${type.name}LifetimeEarned'] as int?) ?? 0;

            updates['${type.name}Amount'] = currentAmount + entry.value;
            updates['${type.name}LifetimeEarned'] = currentLifetime + entry.value;
          }
        }

        transaction.set(userRef, updates, SetOptions(merge: true));
      });

      AppLogger.info('CurrencyDS', 'Currencies added: $amounts');
    } catch (e) {
      AppLogger.error('CurrencyDS', 'addCurrencies failed', e);
      rethrow;
    }
  }

  /// 특정 재화 사용
  Future<void> useCurrency(
    String userId,
    CurrencyType type,
    int amount,
  ) async {
    try {
      final userRef = firestore.collection(_usersCollection).doc(userId);

      await firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        final data = doc.data() ?? {};

        final currentAmount = (data['${type.name}Amount'] as int?) ?? 0;
        if (currentAmount < amount) {
          throw Exception('${type.displayName} 부족');
        }

        transaction.update(userRef, {
          '${type.name}Amount': currentAmount - amount,
        });
      });

      AppLogger.info('CurrencyDS', '${type.name} used: $amount');
    } catch (e) {
      AppLogger.error('CurrencyDS', 'useCurrency failed', e);
      rethrow;
    }
  }

  // ========== Settlement ==========

  /// 정산 기록 저장
  Future<void> saveSettlement(String userId, SettlementModel settlement) async {
    try {
      await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_settlementsCollection)
          .doc(settlement.settlementDate)
          .set(settlement.toFirestore());

      AppLogger.info('CurrencyDS', 'Settlement saved: ${settlement.settlementDate}');
    } catch (e) {
      AppLogger.error('CurrencyDS', 'saveSettlement failed', e);
      rethrow;
    }
  }

  /// 특정 날짜의 정산 기록 조회
  Future<SettlementModel?> getSettlement(String userId, String date) async {
    try {
      final doc = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_settlementsCollection)
          .doc(date)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return SettlementModel.fromFirestore(doc.data()!);
    } catch (e) {
      AppLogger.error('CurrencyDS', 'getSettlement failed', e);
      rethrow;
    }
  }

  /// 정산 기록 목록 조회
  Future<List<SettlementModel>> getSettlements(
    String userId, {
    int limit = 7,
  }) async {
    try {
      final query = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_settlementsCollection)
          .orderBy('settlementDate', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => SettlementModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.error('CurrencyDS', 'getSettlements failed', e);
      rethrow;
    }
  }

  /// 미정산 날짜 목록 조회
  Future<List<String>> getPendingSettlementDates(String userId) async {
    try {
      // 마지막 정산 날짜 조회
      final userDoc = await firestore.collection(_usersCollection).doc(userId).get();
      final userData = userDoc.data();

      DateTime lastSettlement;
      if (userData != null && userData['lastSettlementDate'] != null) {
        final lastSettlementData = userData['lastSettlementDate'];
        if (lastSettlementData is Timestamp) {
          lastSettlement = lastSettlementData.toDate();
        } else {
          lastSettlement = DateTime.parse(lastSettlementData as String);
        }
      } else {
        // 첫 정산인 경우 7일 전부터
        lastSettlement = DateTime.now().subtract(const Duration(days: 8));
      }

      // 어제 날짜까지 미정산 날짜 계산
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final pendingDates = <String>[];

      var currentDate = lastSettlement.add(const Duration(days: 1));
      while (!currentDate.isAfter(yesterday)) {
        final dateStr = _formatDate(currentDate);
        pendingDates.add(dateStr);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      AppLogger.info('CurrencyDS', 'Pending dates: ${pendingDates.length}');
      return pendingDates;
    } catch (e) {
      AppLogger.error('CurrencyDS', 'getPendingSettlementDates failed', e);
      rethrow;
    }
  }

  /// 마지막 정산 날짜 업데이트 (보상이 없는 날짜도 처리 완료로 표시)
  Future<void> updateLastSettlementDate(String userId, String date) async {
    try {
      final userRef = firestore.collection(_usersCollection).doc(userId);
      await userRef.set({
        'lastSettlementDate': Timestamp.fromDate(DateTime.parse(date)),
      }, SetOptions(merge: true));

      AppLogger.info('CurrencyDS', 'Updated lastSettlementDate to $date');
    } catch (e) {
      AppLogger.error('CurrencyDS', 'updateLastSettlementDate failed', e);
      rethrow;
    }
  }

  /// 7일 이상 지난 정산 기록 삭제
  Future<void> deleteOldSettlements(String userId) async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      final cutoffStr = _formatDate(cutoffDate);

      final query = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_settlementsCollection)
          .where('settlementDate', isLessThan: cutoffStr)
          .get();

      final batch = firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      AppLogger.info('CurrencyDS', 'Deleted ${query.docs.length} old settlements');
    } catch (e) {
      AppLogger.error('CurrencyDS', 'deleteOldSettlements failed', e);
      rethrow;
    }
  }

  // ========== Challenge Data ==========

  /// 특정 날짜에 종료된 챌린지 목록 조회
  Future<List<ChallengeSettlementData>> getChallengesEndedOn(
    String userId,
    String date,
  ) async {
    try {
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
        final challengeData = await _buildChallengeSettlementData(
          userId,
          doc.id,
          data,
        );
        if (challengeData != null) {
          challenges.add(challengeData);
        }
      }

      AppLogger.info('CurrencyDS', 'Found ${challenges.length} challenges ended on $date');
      return challenges;
    } catch (e) {
      AppLogger.error('CurrencyDS', 'getChallengesEndedOn failed', e);
      rethrow;
    }
  }

  Future<ChallengeSettlementData?> _buildChallengeSettlementData(
    String userId,
    String challengeId,
    Map<String, dynamic> data,
  ) async {
    try {
      // 챌린지 타입 결정
      final typeStr = data['type'] as String? ?? 'running';
      ChallengeType challengeType;
      switch (typeStr) {
        case 'strength_training':
        case 'strengthTraining':
          challengeType = ChallengeType.strengthTraining;
          break;
        case 'other':
          challengeType = ChallengeType.other;
          break;
        case 'running':
        default:
          challengeType = ChallengeType.running;
      }

      // 참가자별 기여도 조회
      final contributionsQuery = await firestore
          .collection(_challengesCollection)
          .doc(challengeId)
          .collection('contributions')
          .get();

      final participantContributions = <String, double>{};
      double userContribution = 0;
      double userTotalWorkoutValue = 0;
      bool isFirstContribution = true;

      for (final contribDoc in contributionsQuery.docs) {
        final contribData = contribDoc.data();
        final participantId = contribData['userId'] as String;
        final value = (contribData['value'] as num?)?.toDouble() ?? 0;

        participantContributions[participantId] =
            (participantContributions[participantId] ?? 0) + value;

        if (participantId == userId) {
          userContribution += value;
          userTotalWorkoutValue += value;
          isFirstContribution = false;
        }
      }

      // MVP 결정
      String? mvpUserId;
      double maxContribution = 0;
      for (final entry in participantContributions.entries) {
        if (entry.value > maxContribution) {
          maxContribution = entry.value;
          mvpUserId = entry.key;
        }
      }

      // endDate 파싱
      DateTime endDate;
      final endDateData = data['endDate'];
      if (endDateData is Timestamp) {
        endDate = endDateData.toDate();
      } else {
        endDate = DateTime.parse(endDateData as String);
      }

      return ChallengeSettlementData(
        challengeId: challengeId,
        challengeName: data['name'] as String? ?? '챌린지',
        challengeType: challengeType,
        targetValue: (data['targetValue'] as num?)?.toDouble() ?? 0,
        achievedValue: (data['achievedValue'] as num?)?.toDouble() ?? 0,
        isSuccess: data['isSuccess'] as bool? ?? false,
        endDate: endDate,
        participantCount: (data['participantIds'] as List?)?.length ?? 1,
        participantContributions: participantContributions,
        userContribution: userContribution,
        isUserMvp: mvpUserId == userId,
        userTotalWorkoutValue: userTotalWorkoutValue,
        isFirstContribution: isFirstContribution,
      );
    } catch (e) {
      AppLogger.error('CurrencyDS', '_buildChallengeSettlementData failed', e);
      return null;
    }
  }

  // ========== Solo Workout Data ==========

  /// 특정 날짜의 개인 운동 기록 조회
  Future<SoloWorkoutData?> getSoloWorkoutData(
    String userId,
    String date,
    CurrencyType currencyType,
  ) async {
    try {
      final targetDate = DateTime.parse(date);
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // 운동 타입 필터
      List<String> workoutTypes;
      switch (currencyType) {
        case CurrencyType.wood:
          workoutTypes = ['running'];
          break;
        case CurrencyType.iron:
          workoutTypes = ['weightTraining', 'strength'];
          break;
        case CurrencyType.soil:
          workoutTypes = ['walking', 'cycling', 'swimming', 'yoga', 'hiking', 'other'];
          break;
      }

      final query = await firestore
          .collection(_workoutsCollection)
          .where('userId', isEqualTo: userId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      double totalValue = 0;
      int workoutCount = 0;

      for (final doc in query.docs) {
        final data = doc.data();
        final type = data['type'] as String?;

        if (type != null && workoutTypes.contains(type)) {
          workoutCount++;

          switch (currencyType) {
            case CurrencyType.wood:
              // 거리 (km)
              final distance = (data['distance'] as num?)?.toDouble() ?? 0;
              totalValue += distance;
              break;
            case CurrencyType.iron:
              // 점수 (시간 × 강도)
              final durationSeconds = data['durationSeconds'] as int?;
              final durationMinutes = durationSeconds != null ? (durationSeconds / 60).round() : 0;
              final intensity = (data['intensity'] as num?)?.toDouble() ?? 0.83;
              totalValue += durationMinutes * intensity;
              break;
            case CurrencyType.soil:
              // 시간 (분)
              final durationSeconds = data['durationSeconds'] as int?;
              final durationMinutes = durationSeconds != null ? (durationSeconds / 60).round() : 0;
              totalValue += durationMinutes.toDouble();
              break;
          }
        }
      }

      if (workoutCount == 0) {
        return null;
      }

      switch (currencyType) {
        case CurrencyType.wood:
          return SoloWorkoutData.running(
            distanceKm: totalValue,
            workoutCount: workoutCount,
            date: date,
          );
        case CurrencyType.iron:
          return SoloWorkoutData.strength(
            score: totalValue,
            workoutCount: workoutCount,
            date: date,
          );
        case CurrencyType.soil:
          return SoloWorkoutData.other(
            minutes: totalValue,
            workoutCount: workoutCount,
            date: date,
          );
      }
    } catch (e) {
      AppLogger.error('CurrencyDS', 'getSoloWorkoutData failed', e);
      return null;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

