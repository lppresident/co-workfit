import 'package:equatable/equatable.dart';
import '../../domain/entities/equipped_items_entity.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/entities/item_entity.dart';

/// Craft BLoC 상태
class CraftState extends Equatable {
  /// 로딩 중 여부
  final bool isLoading;

  /// 에러 메시지
  final String? errorMessage;

  /// 성공 메시지 (제작 완료 등)
  final String? successMessage;

  /// 모든 아이템 레시피
  final List<ItemEntity> recipes;

  /// 사용자 인벤토리
  final List<InventoryItemEntity> inventory;

  /// 장착 아이템
  final EquippedItemsEntity equippedItems;

  /// 현재 통나무 보유량
  final int woodAmount;

  const CraftState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.recipes = const [],
    this.inventory = const [],
    this.equippedItems = const EquippedItemsEntity(),
    this.woodAmount = 0,
  });

  /// 초기 상태
  factory CraftState.initial() {
    return const CraftState();
  }

  /// 로딩 상태
  CraftState loading() {
    return copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );
  }

  /// 에러 상태
  CraftState error(String message) {
    return copyWith(
      isLoading: false,
      errorMessage: message,
      successMessage: null,
    );
  }

  /// 성공 상태
  CraftState success(String message) {
    return copyWith(
      isLoading: false,
      errorMessage: null,
      successMessage: message,
    );
  }

  /// 메시지 초기화
  CraftState clearMessages() {
    return copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }

  /// 특정 아이템의 인벤토리 수량 조회
  int getItemQuantity(String itemId) {
    try {
      return inventory.firstWhere((i) => i.itemId == itemId).quantity;
    } catch (e) {
      return 0;
    }
  }

  /// 특정 아이템이 장착되어 있는지 확인
  bool isItemEquipped(String itemId) {
    return equippedItems.isEquipped(itemId);
  }

  /// 특정 아이템을 제작할 수 있는지 확인
  bool canCraftItem(ItemEntity item) {
    return woodAmount >= item.woodCost;
  }

  CraftState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    List<ItemEntity>? recipes,
    List<InventoryItemEntity>? inventory,
    EquippedItemsEntity? equippedItems,
    int? woodAmount,
  }) {
    return CraftState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      recipes: recipes ?? this.recipes,
      inventory: inventory ?? this.inventory,
      equippedItems: equippedItems ?? this.equippedItems,
      woodAmount: woodAmount ?? this.woodAmount,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        successMessage,
        recipes,
        inventory,
        equippedItems,
        woodAmount,
      ];
}

