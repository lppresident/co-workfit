import 'package:equatable/equatable.dart';
import 'item_category.dart';

/// 아이템 재화 타입
enum ItemCurrencyType {
  wood,  // 통나무 (달리기)
  iron,  // 쇠 (헬스)
}

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
  
  /// 제작 비용 (쇠)
  final int ironCost;

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
    this.woodCost = 0,
    this.ironCost = 0,
    required this.iconEmoji,
    this.iconAssetPath,
    required this.estimatedDays,
  });

  /// 재화 타입
  ItemCurrencyType get currencyType => 
      ironCost > 0 ? ItemCurrencyType.iron : ItemCurrencyType.wood;
  
  /// 통나무 아이템인지
  bool get isWoodItem => woodCost > 0 && ironCost == 0;
  
  /// 쇠 아이템인지
  bool get isIronItem => ironCost > 0;
  
  /// 제작 비용 (재화 타입에 따라)
  int get cost => isIronItem ? ironCost : woodCost;

  /// 제작 가능 여부 확인 (통나무)
  bool canCraftWithWood(int currentWood) => isWoodItem && currentWood >= woodCost;
  
  /// 제작 가능 여부 확인 (쇠)
  bool canCraftWithIron(int currentIron) => isIronItem && currentIron >= ironCost;
  
  /// 제작 가능 여부 확인 (통합)
  bool canCraft({int currentWood = 0, int currentIron = 0}) {
    if (isIronItem) return currentIron >= ironCost;
    return currentWood >= woodCost;
  }

  /// 가격 기반 테마 색상
  int get themeColorValue {
    final price = cost;
    if (isIronItem) {
      // 쇠 아이템 - 청회색 계열
      if (price >= 500) {
        return 0xFF455A64; // 진한 청회색 (고가)
      } else if (price >= 100) {
        return 0xFF607D8B; // 청회색 (중가)
      } else {
        return 0xFF78909C; // 연한 청회색 (저가)
      }
    } else {
      // 통나무 아이템 - 갈색 계열
      if (price >= 500) {
        return 0xFF8D6E63; // 갈색 (고가)
      } else if (price >= 100) {
        return 0xFF795548; // 진한 갈색 (중가)
      } else {
        return 0xFFA1887F; // 연한 갈색 (저가)
      }
    }
  }
  
  /// 재화 이모지
  String get currencyEmoji => isIronItem ? '🔩' : '🪵';

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        clothingSlot,
        woodCost,
        ironCost,
        iconEmoji,
        iconAssetPath,
        estimatedDays,
      ];
}

