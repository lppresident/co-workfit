import 'package:co_workfit/core/utils/logger.dart';
import '../../domain/entities/equipped_items_entity.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/item_recipes.dart';
import '../../domain/repositories/craft_repository.dart';
import '../datasources/firestore_craft_datasource.dart';
import '../models/equipped_items_model.dart';

/// CraftRepository 구현체
class CraftRepositoryImpl implements CraftRepository {
  final FirestoreCraftDataSource dataSource;

  CraftRepositoryImpl({required this.dataSource});

  // ========== 아이템 마스터 데이터 ==========

  @override
  Future<List<ItemEntity>> getAllRecipes() async {
    return dataSource.getAllRecipes();
  }

  @override
  Future<ItemEntity?> getItemById(String itemId) async {
    return dataSource.getItemById(itemId);
  }

  // ========== 인벤토리 ==========

  @override
  Future<List<InventoryItemEntity>> getInventory(String userId) async {
    return dataSource.getInventory(userId);
  }

  @override
  Future<void> addToInventory(
    String userId,
    String itemId,
    int quantity,
  ) async {
    await dataSource.addToInventory(userId, itemId, quantity);
  }

  @override
  Future<void> removeFromInventory(
    String userId,
    String itemId,
    int quantity,
  ) async {
    await dataSource.removeFromInventory(userId, itemId, quantity);
  }

  @override
  Future<bool> hasItem(String userId, String itemId) async {
    final quantity = await dataSource.getItemQuantity(userId, itemId);
    return quantity > 0;
  }

  @override
  Future<int> getItemQuantity(String userId, String itemId) async {
    return dataSource.getItemQuantity(userId, itemId);
  }

  // ========== 장착 ==========

  @override
  Future<EquippedItemsEntity> getEquippedItems(String userId) async {
    return dataSource.getEquippedItems(userId);
  }

  @override
  Future<void> equipItem(String userId, String itemId) async {
    // 1. 아이템 정보 조회
    final item = ItemRecipes.getItemById(itemId);
    if (item == null) {
      throw Exception('존재하지 않는 아이템입니다: $itemId');
    }

    // 2. 의상 아이템인지 확인
    if (item.category != ItemCategory.clothing || item.clothingSlot == null) {
      throw Exception('장착할 수 없는 아이템입니다: $itemId');
    }

    // 3. 인벤토리에 보유 중인지 확인
    final hasItemInInventory = await hasItem(userId, itemId);
    if (!hasItemInInventory) {
      throw Exception('인벤토리에 아이템이 없습니다: $itemId');
    }

    // 4. 현재 장착 상태 조회
    final currentEquipped = await dataSource.getEquippedItems(userId);

    // 5. 해당 슬롯에 장착
    final newEquipped = EquippedItemsModel.fromEntity(
      currentEquipped.equip(item.clothingSlot!, itemId),
    );

    // 6. 업데이트
    await dataSource.updateEquippedItems(userId, newEquipped);

    AppLogger.info(
      'CraftRepositoryImpl',
      '아이템 장착: $itemId → ${item.clothingSlot!.displayName} (userId: $userId)',
    );
  }

  @override
  Future<void> unequipItem(String userId, String itemId) async {
    // 1. 아이템 정보 조회
    final item = ItemRecipes.getItemById(itemId);
    if (item == null) {
      throw Exception('존재하지 않는 아이템입니다: $itemId');
    }

    // 2. 의상 아이템인지 확인
    if (item.category != ItemCategory.clothing || item.clothingSlot == null) {
      throw Exception('해제할 수 없는 아이템입니다: $itemId');
    }

    // 3. 현재 장착 상태 조회
    final currentEquipped = await dataSource.getEquippedItems(userId);

    // 4. 해당 아이템이 장착되어 있는지 확인
    if (!currentEquipped.isEquipped(itemId)) {
      throw Exception('장착되어 있지 않은 아이템입니다: $itemId');
    }

    // 5. 해당 슬롯에서 해제
    final newEquipped = EquippedItemsModel.fromEntity(
      currentEquipped.unequip(item.clothingSlot!),
    );

    // 6. 업데이트
    await dataSource.updateEquippedItems(userId, newEquipped);

    AppLogger.info(
      'CraftRepositoryImpl',
      '아이템 해제: $itemId (userId: $userId)',
    );
  }

  // ========== 제작 ==========

  @override
  Future<bool> craftItem(String userId, String itemId) async {
    try {
      // 1. 아이템 정보 조회
      final item = ItemRecipes.getItemById(itemId);
      if (item == null) {
        throw Exception('존재하지 않는 아이템입니다: $itemId');
      }

      // 2. 통나무 보유량 확인
      final woodAmount = await dataSource.getWoodAmount(userId);
      if (woodAmount < item.woodCost) {
        throw Exception(
            '통나무가 부족합니다. 보유: $woodAmount, 필요: ${item.woodCost}');
      }

      // 3. 통나무 소비
      await dataSource.useWood(userId, item.woodCost);

      // 4. 인벤토리에 아이템 추가
      await dataSource.addToInventory(userId, itemId, 1);

      AppLogger.info(
        'CraftRepositoryImpl',
        '아이템 제작 완료: ${item.name} (통나무 ${item.woodCost}개 사용)',
      );

      return true;
    } catch (e) {
      AppLogger.error('CraftRepositoryImpl', '아이템 제작 실패', e);
      rethrow;
    }
  }
}

