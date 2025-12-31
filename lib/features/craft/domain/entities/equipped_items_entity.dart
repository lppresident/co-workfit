import 'package:equatable/equatable.dart';
import 'item_category.dart';

/// 장착 아이템 엔티티 (캐릭터에 장착된 아이템)
class EquippedItemsEntity extends Equatable {
  /// 머리 슬롯에 장착된 아이템 ID
  final String? headItemId;

  /// 상체 슬롯에 장착된 아이템 ID
  final String? bodyItemId;

  /// 하체 슬롯에 장착된 아이템 ID
  final String? legsItemId;

  const EquippedItemsEntity({
    this.headItemId,
    this.bodyItemId,
    this.legsItemId,
  });

  /// 빈 장착 상태
  factory EquippedItemsEntity.empty() {
    return const EquippedItemsEntity();
  }

  /// 특정 슬롯에 아이템 장착
  EquippedItemsEntity equip(ClothingSlot slot, String itemId) {
    switch (slot) {
      case ClothingSlot.head:
        return EquippedItemsEntity(
          headItemId: itemId,
          bodyItemId: bodyItemId,
          legsItemId: legsItemId,
        );
      case ClothingSlot.body:
        return EquippedItemsEntity(
          headItemId: headItemId,
          bodyItemId: itemId,
          legsItemId: legsItemId,
        );
      case ClothingSlot.legs:
        return EquippedItemsEntity(
          headItemId: headItemId,
          bodyItemId: bodyItemId,
          legsItemId: itemId,
        );
    }
  }

  /// 특정 슬롯에서 아이템 해제
  EquippedItemsEntity unequip(ClothingSlot slot) {
    switch (slot) {
      case ClothingSlot.head:
        return EquippedItemsEntity(
          headItemId: null,
          bodyItemId: bodyItemId,
          legsItemId: legsItemId,
        );
      case ClothingSlot.body:
        return EquippedItemsEntity(
          headItemId: headItemId,
          bodyItemId: null,
          legsItemId: legsItemId,
        );
      case ClothingSlot.legs:
        return EquippedItemsEntity(
          headItemId: headItemId,
          bodyItemId: bodyItemId,
          legsItemId: null,
        );
    }
  }

  /// 특정 슬롯에 장착된 아이템 ID 조회
  String? getEquippedItemId(ClothingSlot slot) {
    switch (slot) {
      case ClothingSlot.head:
        return headItemId;
      case ClothingSlot.body:
        return bodyItemId;
      case ClothingSlot.legs:
        return legsItemId;
    }
  }

  /// 특정 아이템이 장착되어 있는지 확인
  bool isEquipped(String itemId) {
    return headItemId == itemId ||
        bodyItemId == itemId ||
        legsItemId == itemId;
  }

  /// 장착된 아이템 개수
  int get equippedCount {
    int count = 0;
    if (headItemId != null) count++;
    if (bodyItemId != null) count++;
    if (legsItemId != null) count++;
    return count;
  }

  @override
  List<Object?> get props => [headItemId, bodyItemId, legsItemId];
}

