import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_summary_entity.dart';
import 'package:co_workfit/features/currency/domain/entities/settlement_entity.dart';
import 'package:co_workfit/features/currency/domain/entities/challenge_settlement_data.dart';

/// 통합 재화 Repository 인터페이스
abstract class CurrencyRepository {
  // ========== Summary ==========

  /// 사용자의 재화 보유 현황 조회
  Future<CurrencySummaryEntity> getCurrencySummary(String userId);

  /// 재화 보유 현황 업데이트
  Future<void> updateCurrencySummary(String userId, CurrencySummaryEntity summary);

  /// 여러 재화 한 번에 추가 (정산 시)
  Future<void> addCurrencies(
    String userId,
    Map<CurrencyType, int> amounts,
    String settlementDate,
  );

  /// 특정 재화 사용 (제작 시)
  Future<void> useCurrency(String userId, CurrencyType type, int amount);

  // ========== Settlement ==========

  /// 정산 기록 저장
  Future<void> saveSettlement(String userId, SettlementEntity settlement);

  /// 특정 날짜의 정산 기록 조회
  Future<SettlementEntity?> getSettlement(String userId, String date);

  /// 정산 기록 목록 조회 (최근 N일)
  Future<List<SettlementEntity>> getSettlements(
    String userId, {
    int limit = 7,
  });

  /// 미정산 날짜 목록 조회 (마지막 정산일 이후 ~ 어제)
  Future<List<String>> getPendingSettlementDates(String userId);

  /// 마지막 정산 날짜 업데이트 (보상이 없는 날짜도 처리 완료로 표시)
  Future<void> updateLastSettlementDate(String userId, String date);

  /// 7일 이상 지난 정산 기록 삭제
  Future<void> deleteOldSettlements(String userId);

  // ========== Challenge Data ==========

  /// 특정 날짜에 종료된 챌린지 목록 조회
  Future<List<ChallengeSettlementData>> getChallengesEndedOn(
    String userId,
    String date,
  );

  // ========== Solo Workout Data ==========

  /// 특정 날짜의 개인 운동 기록 조회
  Future<SoloWorkoutData?> getSoloWorkoutData(
    String userId,
    String date,
    CurrencyType currencyType,
  );
}

