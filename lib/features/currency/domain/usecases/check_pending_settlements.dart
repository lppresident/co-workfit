import 'package:co_workfit/features/currency/domain/entities/settlement_entity.dart';
import 'package:co_workfit/features/currency/domain/repositories/currency_repository.dart';
import 'package:co_workfit/features/currency/domain/usecases/settle_daily_rewards.dart';

/// 미정산 날짜 확인 및 일괄 정산 UseCase
class CheckPendingSettlements {
  final CurrencyRepository _repository;
  final SettleDailyRewards _settleDailyRewards;

  CheckPendingSettlements({
    required CurrencyRepository repository,
    required SettleDailyRewards settleDailyRewards,
  })  : _repository = repository,
        _settleDailyRewards = settleDailyRewards;

  /// 미정산 날짜들을 확인하고 일괄 정산
  ///
  /// Returns: 정산된 결과 목록
  Future<List<SettlementEntity>> call(String userId) async {
    // 1. 미정산 날짜 목록 조회
    final pendingDates = await _repository.getPendingSettlementDates(userId);

    if (pendingDates.isEmpty) {
      return [];
    }

    // 2. 각 날짜별로 정산 수행
    final settlements = <SettlementEntity>[];

    for (final date in pendingDates) {
      final settlement = await _settleDailyRewards(
        userId: userId,
        settlementDate: date,
      );

      if (settlement != null) {
        settlements.add(settlement);
      }
    }

    // 3. 오래된 정산 기록 삭제 (7일 초과)
    await _repository.deleteOldSettlements(userId);

    return settlements;
  }
}


