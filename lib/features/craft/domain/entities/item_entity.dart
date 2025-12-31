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

  /// 아이템 등급 (1: 일반, 2: 고급, 3: 희귀, 4: 전설)
  final int rarity;

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
    required this.rarity,
    required this.iconEmoji,
    this.iconAssetPath,
    required this.estimatedDays,
  });

  /// 제작 가능 여부 확인
  bool canCraft(int currentWood) => currentWood >= woodCost;

  /// 등급 이름
  String get rarityName {
    switch (rarity) {
      case 1:
        return '일반';
      case 2:
        return '고급';
      case 3:
        return '희귀';
      case 4:
        return '전설';
      default:
        return '알 수 없음';
    }
  }

  /// 등급 색상 (hex)
  int get rarityColorValue {
    switch (rarity) {
      case 1:
        return 0xFF9E9E9E; // 회색
      case 2:
        return 0xFF4CAF50; // 녹색
      case 3:
        return 0xFF2196F3; // 파랑
      case 4:
        return 0xFFFF9800; // 주황 (전설)
      default:
        return 0xFF9E9E9E;
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
        rarity,
        iconEmoji,
        iconAssetPath,
        estimatedDays,
      ];
}

