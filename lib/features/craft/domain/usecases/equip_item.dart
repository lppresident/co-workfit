import '../repositories/craft_repository.dart';

/// 아이템 장착 결과
class EquipResult {
  final bool success;
  final String? errorMessage;
  final String? previousItemId; // 교체된 이전 아이템 ID

  const EquipResult._({
    required this.success,
    this.errorMessage,
    this.previousItemId,
  });

  factory EquipResult.success({String? previousItemId}) {
    return EquipResult._(success: true, previousItemId: previousItemId);
  }

  factory EquipResult.failure(String message) {
    return EquipResult._(success: false, errorMessage: message);
  }
}

/// 아이템 장착 UseCase
class EquipItem {
  final CraftRepository repository;

  EquipItem(this.repository);

  /// 아이템 장착 실행
  ///
  /// [userId] - 사용자 ID
  /// [itemId] - 장착할 아이템 ID
  ///
  /// Returns: 장착 결과
  Future<EquipResult> call(String userId, String itemId) async {
    try {
      // 1. 아이템 정보 조회
      final item = await repository.getItemById(itemId);
      if (item == null) {
        return EquipResult.failure('존재하지 않는 아이템입니다');
      }

      // 2. 인벤토리 확인
      final hasItem = await repository.hasItem(userId, itemId);
      if (!hasItem) {
        return EquipResult.failure('인벤토리에 아이템이 없습니다');
      }

      // 3. 현재 장착 상태 확인 (교체되는 아이템 ID 확인)
      final currentEquipped = await repository.getEquippedItems(userId);
      String? previousItemId;
      if (item.clothingSlot != null) {
        previousItemId = currentEquipped.getEquippedItemId(item.clothingSlot!);
      }

      // 4. 장착 실행
      await repository.equipItem(userId, itemId);

      return EquipResult.success(previousItemId: previousItemId);
    } catch (e) {
      return EquipResult.failure(e.toString());
    }
  }
}

