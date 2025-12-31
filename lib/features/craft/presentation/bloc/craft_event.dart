import 'package:equatable/equatable.dart';

/// Craft BLoC 이벤트
abstract class CraftEvent extends Equatable {
  const CraftEvent();

  @override
  List<Object?> get props => [];
}

/// 레시피 목록 로드
class LoadRecipes extends CraftEvent {
  const LoadRecipes();
}

/// 인벤토리 로드
class LoadInventory extends CraftEvent {
  final String userId;

  const LoadInventory(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 장착 아이템 로드
class LoadEquippedItems extends CraftEvent {
  final String userId;

  const LoadEquippedItems(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// 아이템 제작
class CraftItemEvent extends CraftEvent {
  final String userId;
  final String itemId;

  const CraftItemEvent({
    required this.userId,
    required this.itemId,
  });

  @override
  List<Object?> get props => [userId, itemId];
}

/// 아이템 장착
class EquipItemEvent extends CraftEvent {
  final String userId;
  final String itemId;

  const EquipItemEvent({
    required this.userId,
    required this.itemId,
  });

  @override
  List<Object?> get props => [userId, itemId];
}

/// 아이템 해제
class UnequipItemEvent extends CraftEvent {
  final String userId;
  final String itemId;

  const UnequipItemEvent({
    required this.userId,
    required this.itemId,
  });

  @override
  List<Object?> get props => [userId, itemId];
}

/// 전체 데이터 새로고침
class RefreshCraftData extends CraftEvent {
  final String userId;

  const RefreshCraftData(this.userId);

  @override
  List<Object?> get props => [userId];
}

