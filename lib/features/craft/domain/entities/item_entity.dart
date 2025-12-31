import 'package:equatable/equatable.dart';
import 'item_category.dart';

/// 아이템 엔티티 (마스터 데이터)
class ItemEntity extends Equatable {
  /// 아이템 고유 ID
  final String id;

  /// 아이템 이름
  final String name;

  /// 아이템 설명
  final String description;

  /// 아이템 카테고리
  final ItemCategory category;

  /// 의상 슬롯 (의상 아이템인 경우)
  final ClothingSlot? clothingSlot;

  /// 제작 비용 (통나무)
  final int woodCost;

  /// 아이콘 이모지 (Phase 1에서 임시 사용)
  final String iconEmoji;

  /// 아이콘 에셋 경로 (Phase 2+)
  final String? iconAssetPath;

  /// 획득 예상 기간 (일)
  final int estimatedDays;

  const ItemEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.clothingSlot,
    required this.woodCost,
    required this.iconEmoji,
    this.iconAssetPath,
    required this.estimatedDays,
  });

  /// 제작 가능 여부 확인
  bool canCraft(int currentWood) => currentWood >= woodCost;

  /// 가격 기반 테마 색상
  int get themeColorValue {
    if (woodCost >= 500) {
      return 0xFF8D6E63; // 갈색 (고가)
    } else if (woodCost >= 100) {
      return 0xFF795548; // 진한 갈색 (중가)
    } else {
      return 0xFFA1887F; // 연한 갈색 (저가)
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        clothingSlot,
        woodCost,
        iconEmoji,
        iconAssetPath,
        estimatedDays,
      ];
}

