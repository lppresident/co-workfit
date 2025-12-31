/// 아이템 카테고리
enum ItemCategory {
  /// 의상 아이템
  clothing,

  /// 액세서리 (Phase 2+)
  accessory,

  /// 기타 아이템 (Phase 2+)
  other,
}

/// 의상 슬롯 (장착 위치)
enum ClothingSlot {
  /// 머리
  head,

  /// 상체
  body,

  /// 하체
  legs,
}

/// ClothingSlot 확장
extension ClothingSlotExtension on ClothingSlot {
  String get displayName {
    switch (this) {
      case ClothingSlot.head:
        return '머리';
      case ClothingSlot.body:
        return '상체';
      case ClothingSlot.legs:
        return '하체';
    }
  }

  String get emoji {
    switch (this) {
      case ClothingSlot.head:
        return '🧢';
      case ClothingSlot.body:
        return '👕';
      case ClothingSlot.legs:
        return '👖';
    }
  }
}

