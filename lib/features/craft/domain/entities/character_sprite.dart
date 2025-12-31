import 'package:flutter/material.dart';
import 'item_category.dart';

/// 캐릭터 스프라이트 데이터
/// 
/// 도트 스타일 캐릭터를 레이어 기반으로 렌더링하기 위한 데이터 구조
class CharacterSprite {
  /// 피부색
  final Color skinColor;
  
  /// 머리 장착 아이템 ID
  final String? headItemId;
  
  /// 상체 장착 아이템 ID
  final String? bodyItemId;
  
  /// 하체 장착 아이템 ID
  final String? legsItemId;

  const CharacterSprite({
    this.skinColor = const Color(0xFFFFDBAC), // 기본 피부색
    this.headItemId,
    this.bodyItemId,
    this.legsItemId,
  });

  CharacterSprite copyWith({
    Color? skinColor,
    String? headItemId,
    String? bodyItemId,
    String? legsItemId,
  }) {
    return CharacterSprite(
      skinColor: skinColor ?? this.skinColor,
      headItemId: headItemId ?? this.headItemId,
      bodyItemId: bodyItemId ?? this.bodyItemId,
      legsItemId: legsItemId ?? this.legsItemId,
    );
  }
}

/// 아이템 스프라이트 데이터
/// 
/// 각 아이템의 도트 스프라이트 정보
class ItemSpriteData {
  /// 아이템 ID
  final String itemId;
  
  /// 슬롯 타입
  final ClothingSlot slot;
  
  /// 기본 색상
  final Color primaryColor;
  
  /// 보조 색상
  final Color? secondaryColor;
  
  /// 악센트 색상 (장식용)
  final Color? accentColor;
  
  /// 스프라이트 타입 (렌더링 방식 결정)
  final SpriteType spriteType;

  const ItemSpriteData({
    required this.itemId,
    required this.slot,
    required this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    required this.spriteType,
  });
}

/// 스프라이트 타입
enum SpriteType {
  // === 통나무 아이템 (달리기) ===
  // 머리
  leafBand,      // 나뭇잎 머리띠
  woodHat,       // 나무 모자
  logCrown,      // 통나무 왕관
  goldenCrown,   // 황금 통나무 왕관
  
  // 상체
  woodTshirt,    // 나무 티셔츠
  forestVest,    // 숲의 조끼
  ancientArmor,  // 고대 나무 갑옷
  
  // 하체
  woodShorts,    // 나무 반바지
  forestPants,   // 숲의 바지
  ancientGreaves, // 고대 나무 각반
  
  // === 쇠 아이템 (헬스) ===
  // 머리
  ironHeadband,     // 철 머리띠
  steelHelmet,      // 강철 헬멧
  warriorHelm,      // 전사의 투구
  championCrown,    // 챔피언 왕관
  
  // 상체
  ironTankTop,      // 철 탱크탑
  chainMail,        // 쇠사슬 갑옷
  plateArmor,       // 강철 판금 갑옷
  
  // 하체
  ironGymShorts,    // 철 운동 반바지
  ironTrainingPants,// 강철 트레이닝 바지
  warriorGreaves,   // 전사의 정강이 받침
}

/// 아이템 스프라이트 레지스트리
/// 
/// 모든 아이템의 스프라이트 데이터를 관리
class ItemSpriteRegistry {
  ItemSpriteRegistry._();

  static final Map<String, ItemSpriteData> _sprites = {
    // 머리 아이템
    'head_leaf_band': const ItemSpriteData(
      itemId: 'head_leaf_band',
      slot: ClothingSlot.head,
      primaryColor: Color(0xFF4CAF50), // 녹색
      secondaryColor: Color(0xFF81C784),
      spriteType: SpriteType.leafBand,
    ),
    'head_wood_hat': const ItemSpriteData(
      itemId: 'head_wood_hat',
      slot: ClothingSlot.head,
      primaryColor: Color(0xFF8D6E63), // 갈색
      secondaryColor: Color(0xFFA1887F),
      spriteType: SpriteType.woodHat,
    ),
    'head_log_crown': const ItemSpriteData(
      itemId: 'head_log_crown',
      slot: ClothingSlot.head,
      primaryColor: Color(0xFF5D4037), // 진한 갈색
      secondaryColor: Color(0xFF8D6E63),
      accentColor: Color(0xFFFFD700), // 금색 악센트
      spriteType: SpriteType.logCrown,
    ),
    'head_golden_crown': const ItemSpriteData(
      itemId: 'head_golden_crown',
      slot: ClothingSlot.head,
      primaryColor: Color(0xFFFFD700), // 금색
      secondaryColor: Color(0xFFFFC107),
      accentColor: Color(0xFFFF5722), // 보석 색상
      spriteType: SpriteType.goldenCrown,
    ),
    
    // 상체 아이템
    'body_wood_tshirt': const ItemSpriteData(
      itemId: 'body_wood_tshirt',
      slot: ClothingSlot.body,
      primaryColor: Color(0xFFBCAAA4), // 밝은 갈색
      secondaryColor: Color(0xFFD7CCC8),
      spriteType: SpriteType.woodTshirt,
    ),
    'body_forest_vest': const ItemSpriteData(
      itemId: 'body_forest_vest',
      slot: ClothingSlot.body,
      primaryColor: Color(0xFF388E3C), // 진한 녹색
      secondaryColor: Color(0xFF4CAF50),
      accentColor: Color(0xFF8D6E63),
      spriteType: SpriteType.forestVest,
    ),
    'body_ancient_armor': const ItemSpriteData(
      itemId: 'body_ancient_armor',
      slot: ClothingSlot.body,
      primaryColor: Color(0xFF5D4037), // 진한 갈색
      secondaryColor: Color(0xFF795548),
      accentColor: Color(0xFF4CAF50), // 녹색 문양
      spriteType: SpriteType.ancientArmor,
    ),
    
    // 하체 아이템
    'legs_wood_shorts': const ItemSpriteData(
      itemId: 'legs_wood_shorts',
      slot: ClothingSlot.legs,
      primaryColor: Color(0xFFBCAAA4), // 밝은 갈색
      secondaryColor: Color(0xFFD7CCC8),
      spriteType: SpriteType.woodShorts,
    ),
    'legs_forest_pants': const ItemSpriteData(
      itemId: 'legs_forest_pants',
      slot: ClothingSlot.legs,
      primaryColor: Color(0xFF2E7D32), // 진한 녹색
      secondaryColor: Color(0xFF388E3C),
      spriteType: SpriteType.forestPants,
    ),
    'legs_ancient_greaves': const ItemSpriteData(
      itemId: 'legs_ancient_greaves',
      slot: ClothingSlot.legs,
      primaryColor: Color(0xFF5D4037), // 진한 갈색
      secondaryColor: Color(0xFF795548),
      accentColor: Color(0xFFFFD700), // 금색 장식
      spriteType: SpriteType.ancientGreaves,
    ),
    
    // === 쇠 아이템 (헬스) ===
    
    // 머리 아이템
    'iron_head_band': const ItemSpriteData(
      itemId: 'iron_head_band',
      slot: ClothingSlot.head,
      primaryColor: Color(0xFF607D8B), // 청회색
      secondaryColor: Color(0xFF78909C),
      spriteType: SpriteType.ironHeadband,
    ),
    'iron_steel_helmet': const ItemSpriteData(
      itemId: 'iron_steel_helmet',
      slot: ClothingSlot.head,
      primaryColor: Color(0xFF546E7A), // 진한 청회색
      secondaryColor: Color(0xFF78909C),
      accentColor: Color(0xFFB0BEC5), // 하이라이트
      spriteType: SpriteType.steelHelmet,
    ),
    'iron_warrior_helm': const ItemSpriteData(
      itemId: 'iron_warrior_helm',
      slot: ClothingSlot.head,
      primaryColor: Color(0xFF455A64), // 진한 강철
      secondaryColor: Color(0xFF607D8B),
      accentColor: Color(0xFFE53935), // 빨간 깃털
      spriteType: SpriteType.warriorHelm,
    ),
    'iron_champion_crown': const ItemSpriteData(
      itemId: 'iron_champion_crown',
      slot: ClothingSlot.head,
      primaryColor: Color(0xFFFFD700), // 금색
      secondaryColor: Color(0xFF455A64),
      accentColor: Color(0xFFE91E63), // 핑크 보석
      spriteType: SpriteType.championCrown,
    ),
    
    // 상체 아이템
    'iron_tank_top': const ItemSpriteData(
      itemId: 'iron_tank_top',
      slot: ClothingSlot.body,
      primaryColor: Color(0xFF37474F), // 진한 회색
      secondaryColor: Color(0xFF546E7A),
      accentColor: Color(0xFFE53935), // 빨간 라인
      spriteType: SpriteType.ironTankTop,
    ),
    'iron_chain_mail': const ItemSpriteData(
      itemId: 'iron_chain_mail',
      slot: ClothingSlot.body,
      primaryColor: Color(0xFF78909C), // 은색
      secondaryColor: Color(0xFF546E7A),
      accentColor: Color(0xFFB0BEC5), // 반짝임
      spriteType: SpriteType.chainMail,
    ),
    'iron_plate_armor': const ItemSpriteData(
      itemId: 'iron_plate_armor',
      slot: ClothingSlot.body,
      primaryColor: Color(0xFF455A64), // 진한 강철
      secondaryColor: Color(0xFF263238),
      accentColor: Color(0xFFFFD700), // 금색 장식
      spriteType: SpriteType.plateArmor,
    ),
    
    // 하체 아이템
    'iron_gym_shorts': const ItemSpriteData(
      itemId: 'iron_gym_shorts',
      slot: ClothingSlot.legs,
      primaryColor: Color(0xFF37474F), // 진한 회색
      secondaryColor: Color(0xFF546E7A),
      accentColor: Color(0xFFE53935), // 빨간 라인
      spriteType: SpriteType.ironGymShorts,
    ),
    'iron_training_pants': const ItemSpriteData(
      itemId: 'iron_training_pants',
      slot: ClothingSlot.legs,
      primaryColor: Color(0xFF455A64), // 회색
      secondaryColor: Color(0xFF37474F),
      accentColor: Color(0xFF1E88E5), // 파란 라인
      spriteType: SpriteType.ironTrainingPants,
    ),
    'iron_warrior_greaves': const ItemSpriteData(
      itemId: 'iron_warrior_greaves',
      slot: ClothingSlot.legs,
      primaryColor: Color(0xFF455A64), // 강철
      secondaryColor: Color(0xFF263238),
      accentColor: Color(0xFFFFD700), // 금색 장식
      spriteType: SpriteType.warriorGreaves,
    ),
  };

  /// 아이템 ID로 스프라이트 데이터 조회
  static ItemSpriteData? getSprite(String itemId) {
    return _sprites[itemId];
  }

  /// 모든 스프라이트 데이터 조회
  static List<ItemSpriteData> get allSprites => _sprites.values.toList();
}

