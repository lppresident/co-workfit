import 'package:co_workfit/features/wood/domain/entities/wood_summary_entity.dart';
import 'package:co_workfit/features/wood/domain/repositories/wood_repository.dart';

/// 통나무 보유 현황 조회 UseCase
class GetWoodSummary {
  final WoodRepository _repository;

  GetWoodSummary(this._repository);

  /// 사용자의 통나무 보유 현황 조회
  Future<WoodSummaryEntity> call(String userId) {
    return _repository.getWoodSummary(userId);
  }
}

