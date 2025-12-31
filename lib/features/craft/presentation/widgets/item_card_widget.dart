import 'package:flutter/material.dart';
import '../../domain/entities/item_entity.dart';

/// 아이템 카드 위젯
class ItemCardWidget extends StatelessWidget {
  final ItemEntity item;
  final int currentWood;
  final int ownedQuantity;
  final bool isEquipped;
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
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEquipped
              ? Colors.amber
              : Color(item.rarityColorValue).withValues(alpha: 0.5),
          width: isEquipped ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘 & 등급
              Row(
                children: [
                  // 아이콘
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(item.rarityColorValue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        item.iconEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 이름 & 등급
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Color(item.rarityColorValue),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.rarityName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isEquipped) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '장착 중',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 설명
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // 가격 & 보유량
              Row(
                children: [
                  // 가격
                  Row(
                    children: [
                      const Text('🪵', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${item.woodCost}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: canCraft ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 보유량
                  if (ownedQuantity > 0)
                    Text(
                      '보유: $ownedQuantity개',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // 액션 버튼
              Row(
                children: [
                  // 제작 버튼
                  if (onCraft != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canCraft ? onCraft : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('제작'),
                      ),
                    ),

                  // 장착/해제 버튼
                  if (isOwned && (onEquip != null || onUnequip != null)) ...[
                    if (onCraft != null) const SizedBox(width: 8),
                    Expanded(
                      child: isEquipped
                          ? OutlinedButton(
                              onPressed: onUnequip,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('해제'),
                            )
                          : ElevatedButton(
                              onPressed: onEquip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('장착'),
                            ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

