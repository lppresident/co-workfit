import '../entities/inventory_item_entity.dart';
import '../repositories/craft_repository.dart';

/// 인벤토리 조회 UseCase
class GetInventory {
  final CraftRepository repository;

  GetInventory(this.repository);

  /// 사용자 인벤토리 조회
  Future<List<InventoryItemEntity>> call(String userId) async {
    return repository.getInventory(userId);
  }

  /// 특정 아이템 보유 여부 확인
  Future<bool> hasItem(String userId, String itemId) async {
    return repository.hasItem(userId, itemId);
  }

  /// 특정 아이템 보유 수량 조회
  Future<int> getQuantity(String userId, String itemId) async {
    return repository.getItemQuantity(userId, itemId);
  }
}

