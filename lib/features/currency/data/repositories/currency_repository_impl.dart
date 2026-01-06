import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_summary_entity.dart';
import 'package:co_workfit/features/currency/domain/entities/settlement_entity.dart';
import 'package:co_workfit/features/currency/domain/entities/challenge_settlement_data.dart';
import 'package:co_workfit/features/currency/domain/repositories/currency_repository.dart';
import 'package:co_workfit/features/currency/data/datasources/firestore_currency_datasource.dart';
import 'package:co_workfit/features/currency/data/models/currency_summary_model.dart';
import 'package:co_workfit/features/currency/data/models/settlement_model.dart';

/// 통합 재화 Repository 구현체
class CurrencyRepositoryImpl implements CurrencyRepository {
  final FirestoreCurrencyDataSource _dataSource;

  CurrencyRepositoryImpl({required FirestoreCurrencyDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<CurrencySummaryEntity> getCurrencySummary(String userId) async {
    final model = await _dataSource.getCurrencySummary(userId);
    return model.toEntity();
  }

  @override
  Future<void> updateCurrencySummary(
    String userId,
    CurrencySummaryEntity summary,
  ) async {
    final model = CurrencySummaryModel.fromEntity(summary);
    await _dataSource.updateCurrencySummary(userId, model);
  }

  @override
  Future<void> addCurrencies(
    String userId,
    Map<CurrencyType, int> amounts,
    String settlementDate,
  ) async {
    await _dataSource.addCurrencies(userId, amounts, settlementDate);
  }

  @override
  Future<void> useCurrency(
    String userId,
    CurrencyType type,
    int amount,
  ) async {
    await _dataSource.useCurrency(userId, type, amount);
  }

  @override
  Future<void> saveSettlement(String userId, SettlementEntity settlement) async {
    final model = SettlementModel.fromEntity(settlement);
    await _dataSource.saveSettlement(userId, model);
  }

  @override
  Future<SettlementEntity?> getSettlement(String userId, String date) async {
    final model = await _dataSource.getSettlement(userId, date);
    return model?.toEntity();
  }

  @override
  Future<List<SettlementEntity>> getSettlements(
    String userId, {
    int limit = 7,
  }) async {
    final models = await _dataSource.getSettlements(userId, limit: limit);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<String>> getPendingSettlementDates(String userId) async {
    return await _dataSource.getPendingSettlementDates(userId);
  }

  @override
  Future<void> updateLastSettlementDate(String userId, String date) async {
    await _dataSource.updateLastSettlementDate(userId, date);
  }

  @override
  Future<void> deleteOldSettlements(String userId) async {
    await _dataSource.deleteOldSettlements(userId);
  }

  @override
  Future<List<ChallengeSettlementData>> getChallengesEndedOn(
    String userId,
    String date,
  ) async {
    return await _dataSource.getChallengesEndedOn(userId, date);
  }

  @override
  Future<SoloWorkoutData?> getSoloWorkoutData(
    String userId,
    String date,
    CurrencyType currencyType,
  ) async {
    return await _dataSource.getSoloWorkoutData(userId, date, currencyType);
  }
}

