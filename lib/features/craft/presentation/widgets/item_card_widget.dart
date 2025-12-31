import 'package:flutter/material.dart';
import '../../domain/entities/equipped_items_entity.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_entity.dart';
import 'character_widget.dart';

/// 아이템 카드 위젯 (캐릭터 미리보기 포함)
class ItemCardWidget extends StatelessWidget {
  final ItemEntity item;
  final int currentWood;
  final int ownedQuantity;
  final bool isEquipped;
  final EquippedItemsEntity? currentEquipped;
  final VoidCallback? onTap;
  final VoidCallback? onCraft;
  final VoidCallback? onEquip;
  final VoidCallback? onUnequip;

  const ItemCardWidget({
    super.key,
    required this.item,
    required this.currentWood,
    this.ownedQuantity = 0,
    this.isEquipped = false,
    this.currentEquipped,
    this.onTap,
    this.onCraft,
    this.onEquip,
    this.onUnequip,
  });

  bool get canCraft => currentWood >= item.woodCost;
  bool get isOwned => ownedQuantity > 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isEquipped
              ? Colors.amber
              : Color(item.themeColorValue).withValues(alpha: 0.3),
          width: isEquipped ? 2.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 캐릭터 미리보기
              _buildCharacterPreview(),
              
              const SizedBox(height: 8),
              
              // 아이템 이름
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 4),
              
              // 슬롯 & 장착 상태
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.clothingSlot?.displayName ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  if (isEquipped) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '장착',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const Spacer(),
              
              // 가격 & 보유량
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🪵', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(
                    '${item.woodCost}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: canCraft ? Colors.green[700] : Colors.red[400],
                    ),
                  ),
                  if (ownedQuantity > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '📦$ownedQuantity',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 액션 버튼
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// 캐릭터 미리보기 (아이템 장착 시 모습)
  Widget _buildCharacterPreview() {
    // 현재 장착 상태에서 이 아이템을 장착한 미리보기
    EquippedItemsEntity previewEquipped = currentEquipped ?? const EquippedItemsEntity();
    if (item.clothingSlot != null) {
      previewEquipped = previewEquipped.equip(item.clothingSlot!, item.id);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // 캐릭터
        CharacterWidget(
          size: 72,
          equippedItems: previewEquipped,
          backgroundColor: Colors.grey[50],
          borderColor: Color(item.themeColorValue).withValues(alpha: 0.5),
          borderWidth: 1.5,
          showShadow: false,
        ),
        // 보유 여부 표시
        if (!isOwned)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  /// 액션 버튼들
  Widget _buildActionButtons() {
    return Row(
      children: [
        // 제작 버튼
        if (onCraft != null)
          Expanded(
            child: SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: canCraft ? onCraft : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[400],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('제작', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),

        // 장착/해제 버튼
        if (isOwned && (onEquip != null || onUnequip != null)) ...[
          if (onCraft != null) const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              height: 32,
              child: isEquipped
                  ? OutlinedButton(
                      onPressed: onUnequip,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('해제', style: TextStyle(fontSize: 12)),
                    )
                  : ElevatedButton(
                      onPressed: onEquip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('장착', style: TextStyle(fontSize: 12)),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
