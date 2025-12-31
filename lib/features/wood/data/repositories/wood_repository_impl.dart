import 'package:co_workfit/features/wood/data/datasources/firestore_wood_datasource.dart';
import 'package:co_workfit/features/wood/data/models/wood_settlement_model.dart';
import 'package:co_workfit/features/wood/data/models/wood_summary_model.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_summary_entity.dart';
import 'package:co_workfit/features/wood/domain/repositories/wood_repository.dart';

/// WoodRepository 구현체
class WoodRepositoryImpl implements WoodRepository {
  final FirestoreWoodDataSource _dataSource;

  WoodRepositoryImpl({required FirestoreWoodDataSource dataSource})
      : _dataSource = dataSource;

  // ========== Summary ==========

  @override
  Future<WoodSummaryEntity> getWoodSummary(String userId) {
    return _dataSource.getWoodSummary(userId);
  }

  @override
  Future<void> updateWoodSummary(String userId, WoodSummaryEntity summary) {
    return _dataSource.updateWoodSummary(
      userId,
      WoodSummaryModel.fromEntity(summary),
    );
  }

  @override
  Future<void> addWood(String userId, int amount, String settlementDate) {
    return _dataSource.addWood(userId, amount, settlementDate);
  }

  @override
  Future<void> useWood(String userId, int amount) {
    return _dataSource.useWood(userId, amount);
  }

  // ========== Iron (쇠) ==========

  @override
  Future<void> addIron(String userId, int amount, String settlementDate) {
    return _dataSource.addIron(userId, amount, settlementDate);
  }

  @override
  Future<void> useIron(String userId, int amount) {
    return _dataSource.useIron(userId, amount);
  }

  // ========== Settlement ==========

  @override
  Future<void> saveSettlement(String userId, WoodSettlementEntity settlement) {
    return _dataSource.saveSettlement(
      userId,
      WoodSettlementModel.fromEntity(settlement),
    );
  }

  @override
  Future<WoodSettlementEntity?> getSettlement(String userId, String date) {
    return _dataSource.getSettlement(userId, date);
  }

  @override
  Future<List<WoodSettlementEntity>> getSettlements(
    String userId, {
    int limit = 7,
  }) {
    return _dataSource.getSettlements(userId, limit: limit);
  }

  @override
  Future<List<String>> getPendingSettlementDates(String userId) {
    return _dataSource.getPendingSettlementDates(userId);
  }

  @override
  Future<void> deleteOldSettlements(String userId) {
    return _dataSource.deleteOldSettlements(userId);
  }

  // ========== Challenge Data ==========

  @override
  Future<List<ChallengeSettlementData>> getChallengesEndedOn(
    String userId,
    String date,
  ) {
    return _dataSource.getChallengesEndedOn(userId, date);
  }

  @override
  Future<UserChallengeContribution> getUserContribution(
    String userId,
    String challengeId,
  ) {
    return _dataSource.getUserContribution(userId, challengeId);
  }

  @override
  Future<bool> isFirstWorkoutOfDay(String userId, DateTime date) {
    return _dataSource.isFirstWorkoutOfDay(userId, date);
  }

  @override
  Future<bool> isFirstContribution(String userId, String challengeId) {
    return _dataSource.isFirstContribution(userId, challengeId);
  }

  // ========== Solo Workout Data ==========

  @override
  Future<SoloWorkoutData?> getRunningWorkoutsOnDate(String userId, String date) {
    return _dataSource.getRunningWorkoutsOnDate(userId, date);
  }

  @override
  Future<SoloWorkoutData?> getStrengthWorkoutsOnDate(String userId, String date) {
    return _dataSource.getStrengthWorkoutsOnDate(userId, date);
  }
}

