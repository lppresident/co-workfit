import '../repositories/craft_repository.dart';

/// 아이템 해제 결과
class UnequipResult {
  final bool success;
  final String? errorMessage;

  const UnequipResult._({
    required this.success,
    this.errorMessage,
  });

  factory UnequipResult.success() {
    return const UnequipResult._(success: true);
  }

  factory UnequipResult.failure(String message) {
    return UnequipResult._(success: false, errorMessage: message);
  }
}

/// 아이템 해제 UseCase
class UnequipItem {
  final CraftRepository repository;

  UnequipItem(this.repository);

  /// 아이템 해제 실행
  ///
  /// [userId] - 사용자 ID
  /// [itemId] - 해제할 아이템 ID
  ///
  /// Returns: 해제 결과
  Future<UnequipResult> call(String userId, String itemId) async {
    try {
      // 1. 아이템 정보 조회
      final item = await repository.getItemById(itemId);
      if (item == null) {
        return UnequipResult.failure('존재하지 않는 아이템입니다');
      }

      // 2. 현재 장착 상태 확인
      final currentEquipped = await repository.getEquippedItems(userId);
      if (!currentEquipped.isEquipped(itemId)) {
        return UnequipResult.failure('장착되어 있지 않은 아이템입니다');
      }

      // 3. 해제 실행
      await repository.unequipItem(userId, itemId);

      return UnequipResult.success();
    } catch (e) {
      return UnequipResult.failure(e.toString());
    }
  }
}

