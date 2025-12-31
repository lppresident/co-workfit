import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';
import 'package:co_workfit/features/wood/domain/repositories/wood_repository.dart';
import 'package:co_workfit/features/wood/domain/usecases/settle_daily_rewards.dart';

/// 미정산 보상 확인 및 일괄 정산 UseCase
///
/// 앱 실행 시 호출되어 누락된 정산을 처리
/// - 마지막 정산일 다음날 ~ 어제까지 일괄 정산
/// - 7일 이상 지난 정산 기록 삭제
class CheckPendingSettlements {
  final WoodRepository _repository;
  final SettleDailyRewards _settleDailyRewards;

  CheckPendingSettlements({
    required WoodRepository repository,
    required SettleDailyRewards settleDailyRewards,
  })  : _repository = repository,
        _settleDailyRewards = settleDailyRewards;

  /// 미정산 보상 확인 및 일괄 정산
  ///
  /// [userId] 사용자 ID
  /// 반환: 정산된 결과 목록 (0개 정산은 제외)
  Future<List<WoodSettlementEntity>> call(String userId) async {
    // 1. 미정산 날짜 목록 조회
    final pendingDates = await _repository.getPendingSettlementDates(userId);

    // 2. 각 날짜별로 정산 실행 (0개 정산은 null 반환되므로 필터링)
    final settlements = <WoodSettlementEntity>[];
    for (final date in pendingDates) {
      final settlement = await _settleDailyRewards(
        userId: userId,
        settlementDate: date,
      );
      if (settlement != null && settlement.totalWoodAwarded > 0) {
        settlements.add(settlement);
      }
    }

    // 3. 7일 이상 지난 정산 기록 삭제
    await _repository.deleteOldSettlements(userId);

    return settlements;
  }
}

/// 정산 결과 요약
class SettlementSummary {
  /// 정산된 날짜 수
  final int settledDays;

  /// 총 획득 통나무
  final int totalWoodAwarded;

  /// 정산 상세 목록
  final List<WoodSettlementEntity> settlements;

  const SettlementSummary({
    required this.settledDays,
    required this.totalWoodAwarded,
    required this.settlements,
  });

  factory SettlementSummary.fromSettlements(List<WoodSettlementEntity> settlements) {
    return SettlementSummary(
      settledDays: settlements.length,
      totalWoodAwarded: settlements.fold(0, (sum, s) => sum + s.totalWoodAwarded),
      settlements: settlements,
    );
  }

  /// 정산할 내용이 있는지
  bool get hasSettlements => settlements.isNotEmpty;

  /// 보상을 받은 정산이 있는지
  bool get hasRewards => totalWoodAwarded > 0;
}
