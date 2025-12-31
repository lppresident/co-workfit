import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';
import 'package:co_workfit/features/wood/domain/repositories/wood_repository.dart';

/// 정산 내역 조회 UseCase
class GetSettlementHistory {
  final WoodRepository _repository;

  GetSettlementHistory(this._repository);

  /// 정산 내역 목록 조회
  ///
  /// [userId] 사용자 ID
  /// [limit] 조회할 최대 개수 (기본 30개)
  Future<List<WoodSettlementEntity>> call(
    String userId, {
    int limit = 30,
  }) {
    return _repository.getSettlements(userId, limit: limit);
  }
}

