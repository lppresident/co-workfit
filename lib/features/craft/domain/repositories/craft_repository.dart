import '../entities/equipped_items_entity.dart';
import '../entities/inventory_item_entity.dart';
import '../entities/item_entity.dart';

/// 제작 시스템 Repository 인터페이스
abstract class CraftRepository {
  // ========== 아이템 마스터 데이터 ==========

  /// 모든 아이템 레시피 조회
  Future<List<ItemEntity>> getAllRecipes();

  /// ID로 아이템 조회
  Future<ItemEntity?> getItemById(String itemId);

  // ========== 인벤토리 ==========

  /// 사용자 인벤토리 조회
  Future<List<InventoryItemEntity>> getInventory(String userId);

  /// 인벤토리에 아이템 추가 (제작 시)
  Future<void> addToInventory(String userId, String itemId, int quantity);

  /// 인벤토리에서 아이템 제거
  Future<void> removeFromInventory(String userId, String itemId, int quantity);

  /// 특정 아이템 보유 여부 확인
  Future<bool> hasItem(String userId, String itemId);

  /// 특정 아이템 보유 수량 조회
  Future<int> getItemQuantity(String userId, String itemId);

  // ========== 장착 ==========

  /// 장착 아이템 조회
  Future<EquippedItemsEntity> getEquippedItems(String userId);

  /// 아이템 장착
  Future<void> equipItem(String userId, String itemId);

  /// 아이템 해제
  Future<void> unequipItem(String userId, String itemId);

  // ========== 제작 ==========

  /// 아이템 제작 (통나무 소비 + 인벤토리 추가)
  /// 
  /// Returns: 제작 성공 여부
  Future<bool> craftItem(String userId, String itemId);
}

