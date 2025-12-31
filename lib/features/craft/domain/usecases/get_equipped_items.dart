import '../entities/equipped_items_entity.dart';
import '../repositories/craft_repository.dart';

/// 장착 아이템 조회 UseCase
class GetEquippedItems {
  final CraftRepository repository;

  GetEquippedItems(this.repository);

  /// 장착 아이템 조회
  Future<EquippedItemsEntity> call(String userId) async {
    return repository.getEquippedItems(userId);
  }
}

