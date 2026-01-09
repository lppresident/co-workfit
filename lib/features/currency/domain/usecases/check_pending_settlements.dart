import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/features/currency/domain/entities/settlement_entity.dart';
import 'package:co_workfit/features/currency/domain/repositories/currency_repository.dart';
import 'package:co_workfit/features/currency/domain/usecases/settle_daily_rewards.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';

/// 미정산 날짜 확인 및 일괄 정산 UseCase
class CheckPendingSettlements {
  final CurrencyRepository _currencyRepository;
  final ChallengeRepository _challengeRepository;
  final SettleDailyRewards _settleDailyRewards;

  CheckPendingSettlements({
    required CurrencyRepository currencyRepository,
    required ChallengeRepository challengeRepository,
    required SettleDailyRewards settleDailyRewards,
  })  : _currencyRepository = currencyRepository,
        _challengeRepository = challengeRepository,
        _settleDailyRewards = settleDailyRewards;

  /// 미정산 날짜들을 확인하고 일괄 정산
  ///
  /// Returns: 정산된 결과 목록
  Future<List<SettlementEntity>> call(String userId) async {
    // 0. 정산 전에 먼저 만료된 챌린지들을 모두 처리
    // 이렇게 해야 정산 시 isSuccess 값이 Firestore에 저장되어 있음
    AppLogger.info('CheckPendingSettlements', '정산 전 만료된 챌린지 처리 시작');
    final expiredResult = await _challengeRepository.markExpiredChallenges(userId);
    expiredResult.fold(
      (failure) => AppLogger.error('CheckPendingSettlements', '만료된 챌린지 처리 실패: $failure'),
      (count) => AppLogger.info('CheckPendingSettlements', '만료된 챌린지 $count개 처리 완료'),
    );

    // 1. 미정산 날짜 목록 조회
    final pendingDates = await _currencyRepository.getPendingSettlementDates(userId);

    if (pendingDates.isEmpty) {
      return [];
    }

    AppLogger.info('CheckPendingSettlements', '미정산 날짜: ${pendingDates.length}개');

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

    // 3. 마지막 정산 날짜 업데이트 (보상이 없는 날짜도 처리 완료로 표시)
    if (pendingDates.isNotEmpty) {
      await _currencyRepository.updateLastSettlementDate(userId, pendingDates.last);
    }

    // 4. 오래된 정산 기록 삭제 (7일 초과)
    await _currencyRepository.deleteOldSettlements(userId);

    AppLogger.info('CheckPendingSettlements', '정산 완료: ${settlements.length}개');

    return settlements;
  }
}


