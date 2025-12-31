import 'package:flutter/material.dart';
import '../../domain/entities/character_sprite.dart';
import '../../domain/entities/equipped_items_entity.dart';
import '../../domain/entities/item_category.dart';
import 'character_painter.dart';

/// 도트 스타일 캐릭터 위젯
/// 
/// CustomPainter를 사용하여 레이어 기반 도트 캐릭터를 렌더링
class CharacterWidget extends StatelessWidget {
  /// 캐릭터 크기 (너비와 높이)
  final double size;
  
  /// 장착 아이템 정보
  final EquippedItemsEntity? equippedItems;
  
  /// 피부색 (null이면 기본값)
  final Color? skinColor;
  
  /// 배경색 (null이면 투명)
  final Color? backgroundColor;
  
  /// 테두리 표시 여부
  final bool showBorder;
  
  /// 테두리 색상
  final Color borderColor;
  
  /// 테두리 두께
  final double borderWidth;
  
  /// 그림자 표시 여부
  final bool showShadow;
  
  /// 탭 콜백
  final VoidCallback? onTap;

  const CharacterWidget({
    super.key,
    this.size = 120,
    this.equippedItems,
    this.skinColor,
    this.backgroundColor,
    this.showBorder = true,
    this.borderColor = Colors.brown,
    this.borderWidth = 2,
    this.showShadow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 픽셀 크기 계산 (캐릭터는 32x48 픽셀)
    final pixelSize = size / 52; // 약간의 여백 포함

    final sprite = CharacterSprite(
      skinColor: skinColor ?? const Color(0xFFFFDBAC),
      headItemId: equippedItems?.headItemId,
      bodyItemId: equippedItems?.bodyItemId,
      legsItemId: equippedItems?.legsItemId,
    );

    Widget character = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.15),
        border: showBorder
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.15 - borderWidth),
        child: CustomPaint(
          size: Size(size, size),
          painter: CharacterPainter(
            sprite: sprite,
            pixelSize: pixelSize,
            backgroundColor: backgroundColor,
          ),
        ),
      ),
    );

    if (onTap != null) {
      character = GestureDetector(
        onTap: onTap,
        child: character,
      );
    }

    return character;
  }
}

/// 미니 캐릭터 위젯 (아바타용)
/// 
/// 작은 크기의 캐릭터 표시용
class MiniCharacterWidget extends StatelessWidget {
  final double size;
  final EquippedItemsEntity? equippedItems;
  final Color? borderColor;
  final VoidCallback? onTap;

  const MiniCharacterWidget({
    super.key,
    this.size = 48,
    this.equippedItems,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CharacterWidget(
      size: size,
      equippedItems: equippedItems,
      backgroundColor: Colors.grey[100],
      showBorder: true,
      borderColor: borderColor ?? Colors.brown[300]!,
      borderWidth: 1.5,
      showShadow: false,
      onTap: onTap,
    );
  }
}

/// 캐릭터 프리뷰 위젯 (장착 미리보기용)
/// 
/// 아이템 장착 시 미리보기 표시
class CharacterPreviewWidget extends StatelessWidget {
  final double size;
  final EquippedItemsEntity currentEquipped;
  final String? previewItemId;
  final ClothingSlot? previewSlot;

  const CharacterPreviewWidget({
    super.key,
    this.size = 150,
    required this.currentEquipped,
    this.previewItemId,
    this.previewSlot,
  });

  @override
  Widget build(BuildContext context) {
    // 미리보기 아이템이 있으면 임시로 장착
    EquippedItemsEntity previewEquipped = currentEquipped;
    if (previewItemId != null && previewSlot != null) {
      previewEquipped = currentEquipped.equip(previewSlot!, previewItemId!);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[50]!,
            Colors.brown[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.brown[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CharacterWidget(
            size: size,
            equippedItems: previewEquipped,
            backgroundColor: Colors.white.withValues(alpha: 0.5),
            borderColor: Colors.brown[400]!,
          ),
          if (previewItemId != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '미리보기',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


