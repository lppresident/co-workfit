import 'package:equatable/equatable.dart';

/// 인벤토리 아이템 엔티티 (사용자가 보유한 아이템)
class InventoryItemEntity extends Equatable {
  /// 아이템 ID (마스터 데이터 참조)
  final String itemId;

  /// 보유 수량
  final int quantity;

  /// 획득 일시
  final DateTime acquiredAt;

  /// 마지막 업데이트 일시
  final DateTime updatedAt;

  const InventoryItemEntity({
    required this.itemId,
    required this.quantity,
    required this.acquiredAt,
    required this.updatedAt,
  });

  /// 수량 증가
  InventoryItemEntity addQuantity(int amount) {
    return InventoryItemEntity(
      itemId: itemId,
      quantity: quantity + amount,
      acquiredAt: acquiredAt,
      updatedAt: DateTime.now(),
    );
  }

  /// 수량 감소
  InventoryItemEntity removeQuantity(int amount) {
    final newQuantity = quantity - amount;
    if (newQuantity < 0) {
      throw Exception('수량이 부족합니다');
    }
    return InventoryItemEntity(
      itemId: itemId,
      quantity: newQuantity,
      acquiredAt: acquiredAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [itemId, quantity, acquiredAt, updatedAt];
}

