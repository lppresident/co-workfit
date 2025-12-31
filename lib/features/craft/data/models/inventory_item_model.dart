import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/inventory_item_entity.dart';

/// 인벤토리 아이템 데이터 모델
class InventoryItemModel extends InventoryItemEntity {
  const InventoryItemModel({
    required super.itemId,
    required super.quantity,
    required super.acquiredAt,
    required super.updatedAt,
  });

  /// Entity에서 Model 생성
  factory InventoryItemModel.fromEntity(InventoryItemEntity entity) {
    return InventoryItemModel(
      itemId: entity.itemId,
      quantity: entity.quantity,
      acquiredAt: entity.acquiredAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Firestore DocumentSnapshot에서 생성
  factory InventoryItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItemModel(
      itemId: doc.id,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      acquiredAt: (data['acquiredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Map에서 생성 (itemId 포함)
  factory InventoryItemModel.fromMap(String itemId, Map<String, dynamic> data) {
    return InventoryItemModel(
      itemId: itemId,
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      acquiredAt: (data['acquiredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore 저장용 Map 변환
  Map<String, dynamic> toFirestore() {
    return {
      'quantity': quantity,
      'acquiredAt': Timestamp.fromDate(acquiredAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// 신규 아이템 생성
  factory InventoryItemModel.create(String itemId, {int quantity = 1}) {
    final now = DateTime.now();
    return InventoryItemModel(
      itemId: itemId,
      quantity: quantity,
      acquiredAt: now,
      updatedAt: now,
    );
  }
}

