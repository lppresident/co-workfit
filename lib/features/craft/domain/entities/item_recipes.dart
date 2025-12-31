import 'item_category.dart';
import 'item_entity.dart';

/// Phase 1 의상 아이템 레시피 (10개)
/// 
/// 머리 (HEAD) - 4개
/// 상체 (BODY) - 3개
/// 하체 (LEGS) - 3개
class ItemRecipes {
  ItemRecipes._();

  /// 모든 Phase 1 아이템 목록
  static List<ItemEntity> get allItems => [
        ...headItems,
        ...bodyItems,
        ...legsItems,
      ];

  /// 머리 아이템 (4개)
  static List<ItemEntity> get headItems => [
        const ItemEntity(
          id: 'head_leaf_band',
          name: '나뭇잎 머리띠',
          description: '초보 러너의 첫 장식. 자연과 함께 달리는 느낌!',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.head,
          woodCost: 30,
          rarity: 1,
          iconEmoji: '🌿',
          estimatedDays: 2,
        ),
        const ItemEntity(
          id: 'head_wood_hat',
          name: '나무 모자',
          description: '가벼운 나무로 만든 모자. 햇빛을 가려줍니다.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.head,
          woodCost: 80,
          rarity: 2,
          iconEmoji: '🎩',
          estimatedDays: 5,
        ),
        const ItemEntity(
          id: 'head_log_crown',
          name: '통나무 왕관',
          description: '달리기의 왕에게 어울리는 왕관.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.head,
          woodCost: 300,
          rarity: 3,
          iconEmoji: '👑',
          estimatedDays: 20,
        ),
        const ItemEntity(
          id: 'head_golden_crown',
          name: '황금 통나무 왕관',
          description: '전설의 러너만이 쓸 수 있는 황금빛 왕관.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.head,
          woodCost: 1200,
          rarity: 4,
          iconEmoji: '✨👑',
          estimatedDays: 60,
        ),
      ];

  /// 상체 아이템 (3개)
  static List<ItemEntity> get bodyItems => [
        const ItemEntity(
          id: 'body_wood_tshirt',
          name: '나무 티셔츠',
          description: '부드러운 나무 섬유로 만든 티셔츠.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.body,
          woodCost: 50,
          rarity: 1,
          iconEmoji: '👕',
          estimatedDays: 3,
        ),
        const ItemEntity(
          id: 'body_forest_vest',
          name: '숲의 조끼',
          description: '숲의 기운이 깃든 조끼.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.body,
          woodCost: 150,
          rarity: 2,
          iconEmoji: '🦺',
          estimatedDays: 10,
        ),
        const ItemEntity(
          id: 'body_ancient_armor',
          name: '고대 나무 갑옷',
          description: '오래된 나무의 정령이 깃든 갑옷.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.body,
          woodCost: 500,
          rarity: 3,
          iconEmoji: '🛡️',
          estimatedDays: 33,
        ),
      ];

  /// 하체 아이템 (3개)
  static List<ItemEntity> get legsItems => [
        const ItemEntity(
          id: 'legs_wood_shorts',
          name: '나무 반바지',
          description: '가벼운 나무 섬유 반바지. 달리기에 최적!',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.legs,
          woodCost: 40,
          rarity: 1,
          iconEmoji: '🩳',
          estimatedDays: 3,
        ),
        const ItemEntity(
          id: 'legs_forest_pants',
          name: '숲의 바지',
          description: '숲을 누비기 좋은 튼튼한 바지.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.legs,
          woodCost: 120,
          rarity: 2,
          iconEmoji: '👖',
          estimatedDays: 8,
        ),
        const ItemEntity(
          id: 'legs_ancient_greaves',
          name: '고대 나무 각반',
          description: '고대 전사들이 사용하던 각반.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.legs,
          woodCost: 400,
          rarity: 3,
          iconEmoji: '🦿',
          estimatedDays: 27,
        ),
      ];

  /// ID로 아이템 조회
  static ItemEntity? getItemById(String id) {
    try {
      return allItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 슬롯별 아이템 조회
  static List<ItemEntity> getItemsBySlot(ClothingSlot slot) {
    return allItems
        .where((item) => item.clothingSlot == slot)
        .toList();
  }

  /// 등급별 아이템 조회
  static List<ItemEntity> getItemsByRarity(int rarity) {
    return allItems.where((item) => item.rarity == rarity).toList();
  }

  /// 가격순 정렬
  static List<ItemEntity> get itemsSortedByPrice {
    final sorted = List<ItemEntity>.from(allItems);
    sorted.sort((a, b) => a.woodCost.compareTo(b.woodCost));
    return sorted;
  }
}

