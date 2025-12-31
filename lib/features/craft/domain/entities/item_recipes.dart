import 'item_category.dart';
import 'item_entity.dart';

/// Phase 1 의상 아이템 레시피
/// 
/// 통나무 아이템 (10개): 달리기 챌린지로 획득
/// - 머리 (HEAD) - 4개
/// - 상체 (BODY) - 3개
/// - 하체 (LEGS) - 3개
/// 
/// 쇠 아이템 (10개): 헬스 챌린지로 획득
/// - 머리 (HEAD) - 4개
/// - 상체 (BODY) - 3개
/// - 하체 (LEGS) - 3개
class ItemRecipes {
  ItemRecipes._();

  /// 모든 아이템 목록 (통나무 + 쇠)
  static List<ItemEntity> get allItems => [
        ...woodItems,
        ...ironItems,
      ];
  
  /// 통나무 아이템 목록
  static List<ItemEntity> get woodItems => [
        ...headItems,
        ...bodyItems,
        ...legsItems,
      ];
  
  /// 쇠 아이템 목록
  static List<ItemEntity> get ironItems => [
        ...ironHeadItems,
        ...ironBodyItems,
        ...ironLegsItems,
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
          iconEmoji: '🧢',
          estimatedDays: 5,
        ),
        const ItemEntity(
          id: 'head_log_crown',
          name: '통나무 왕관',
          description: '달리기의 왕에게 어울리는 왕관.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.head,
          woodCost: 300,
          iconEmoji: '🎩',
          estimatedDays: 20,
        ),
        const ItemEntity(
          id: 'head_golden_crown',
          name: '황금 통나무 왕관',
          description: '전설의 러너만이 쓸 수 있는 황금빛 왕관.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.head,
          woodCost: 1200,
          iconEmoji: '👑',
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

  /// 가격순 정렬 (통나무 아이템)
  static List<ItemEntity> get woodItemsSortedByPrice {
    final sorted = List<ItemEntity>.from(woodItems);
    sorted.sort((a, b) => a.woodCost.compareTo(b.woodCost));
    return sorted;
  }
  
  /// 가격순 정렬 (쇠 아이템)
  static List<ItemEntity> get ironItemsSortedByPrice {
    final sorted = List<ItemEntity>.from(ironItems);
    sorted.sort((a, b) => a.ironCost.compareTo(b.ironCost));
    return sorted;
  }

  // ========== 쇠 아이템 (헬스 챌린지) ==========

  /// 쇠 머리 아이템 (4개)
  static List<ItemEntity> get ironHeadItems => [
        const ItemEntity(
          id: 'iron_head_band',
          name: '철 머리띠',
          description: '헬스 입문자의 첫 장식. 땀을 잡아줍니다!',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.head,
          ironCost: 30,
          iconEmoji: '⚙️',
          estimatedDays: 3,
        ),
        const ItemEntity(
          id: 'iron_steel_helmet',
          name: '강철 헬멧',
          description: '단단한 강철로 만든 헬멧. 집중력을 높여줍니다.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.head,
          ironCost: 80,
          iconEmoji: '⛑️',
          estimatedDays: 7,
        ),
        const ItemEntity(
          id: 'iron_warrior_helm',
          name: '전사의 투구',
          description: '강인한 전사에게 어울리는 투구.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.head,
          ironCost: 300,
          iconEmoji: '🪖',
          estimatedDays: 25,
        ),
        const ItemEntity(
          id: 'iron_champion_crown',
          name: '챔피언 왕관',
          description: '헬스의 정점에 선 챔피언만이 쓸 수 있는 왕관.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.head,
          ironCost: 1200,
          iconEmoji: '🏆',
          estimatedDays: 80,
        ),
      ];

  /// 쇠 상체 아이템 (3개)
  static List<ItemEntity> get ironBodyItems => [
        const ItemEntity(
          id: 'iron_tank_top',
          name: '철 탱크탑',
          description: '근육을 드러내는 탱크탑. 운동할 맛이 납니다!',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.body,
          ironCost: 50,
          iconEmoji: '🎽',
          estimatedDays: 4,
        ),
        const ItemEntity(
          id: 'iron_chain_mail',
          name: '쇠사슬 갑옷',
          description: '촘촘한 쇠사슬로 엮은 갑옷.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.body,
          ironCost: 150,
          iconEmoji: '🔗',
          estimatedDays: 12,
        ),
        const ItemEntity(
          id: 'iron_plate_armor',
          name: '강철 판금 갑옷',
          description: '최강의 방어력을 자랑하는 판금 갑옷.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.body,
          ironCost: 500,
          iconEmoji: '🛡️',
          estimatedDays: 40,
        ),
      ];

  /// 쇠 하체 아이템 (3개)
  static List<ItemEntity> get ironLegsItems => [
        const ItemEntity(
          id: 'iron_gym_shorts',
          name: '철 운동 반바지',
          description: '움직임이 자유로운 운동 반바지.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.legs,
          ironCost: 40,
          iconEmoji: '🩲',
          estimatedDays: 4,
        ),
        const ItemEntity(
          id: 'iron_training_pants',
          name: '강철 트레이닝 바지',
          description: '강도 높은 훈련에도 견디는 바지.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.legs,
          ironCost: 120,
          iconEmoji: '👖',
          estimatedDays: 10,
        ),
        const ItemEntity(
          id: 'iron_warrior_greaves',
          name: '전사의 정강이 받침',
          description: '전설의 전사가 착용하던 정강이 받침.',
          category: ItemCategory.clothing,
          clothingSlot: ClothingSlot.legs,
          ironCost: 400,
          iconEmoji: '🦾',
          estimatedDays: 33,
        ),
      ];
}

