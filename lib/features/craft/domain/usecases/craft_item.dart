import '../entities/item_entity.dart';
import '../repositories/craft_repository.dart';

/// 아이템 제작 결과
class CraftResult {
  final bool success;
  final String? errorMessage;
  final ItemEntity? craftedItem;

  const CraftResult._({
    required this.success,
    this.errorMessage,
    this.craftedItem,
  });

  factory CraftResult.success(ItemEntity item) {
    return CraftResult._(success: true, craftedItem: item);
  }

  factory CraftResult.failure(String message) {
    return CraftResult._(success: false, errorMessage: message);
  }
}

/// 아이템 제작 UseCase
class CraftItem {
  final CraftRepository repository;

  CraftItem(this.repository);

  /// 아이템 제작 실행
  ///
  /// [userId] - 사용자 ID
  /// [itemId] - 제작할 아이템 ID
  ///
  /// Returns: 제작 결과
  Future<CraftResult> call(String userId, String itemId) async {
    try {
      // 1. 아이템 정보 조회
      final item = await repository.getItemById(itemId);
      if (item == null) {
        return CraftResult.failure('존재하지 않는 아이템입니다');
      }

      // 2. 제작 실행
      final success = await repository.craftItem(userId, itemId);

      if (success) {
        return CraftResult.success(item);
      } else {
        return CraftResult.failure('제작에 실패했습니다');
      }
    } catch (e) {
      return CraftResult.failure(e.toString());
    }
  }
}

