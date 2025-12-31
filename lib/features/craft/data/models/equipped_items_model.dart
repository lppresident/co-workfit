import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/equipped_items_entity.dart';

/// 장착 아이템 데이터 모델
class EquippedItemsModel extends EquippedItemsEntity {
  const EquippedItemsModel({
    super.headItemId,
    super.bodyItemId,
    super.legsItemId,
  });

  /// Entity에서 Model 생성
  factory EquippedItemsModel.fromEntity(EquippedItemsEntity entity) {
    return EquippedItemsModel(
      headItemId: entity.headItemId,
      bodyItemId: entity.bodyItemId,
      legsItemId: entity.legsItemId,
    );
  }

  /// Firestore DocumentSnapshot에서 생성
  factory EquippedItemsModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return const EquippedItemsModel();
    }
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return const EquippedItemsModel();
    }
    return EquippedItemsModel.fromMap(data);
  }

  /// Map에서 생성
  factory EquippedItemsModel.fromMap(Map<String, dynamic> data) {
    return EquippedItemsModel(
      headItemId: data['headItemId'] as String?,
      bodyItemId: data['bodyItemId'] as String?,
      legsItemId: data['legsItemId'] as String?,
    );
  }

  /// Firestore 저장용 Map 변환
  Map<String, dynamic> toFirestore() {
    return {
      'headItemId': headItemId,
      'bodyItemId': bodyItemId,
      'legsItemId': legsItemId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// 빈 장착 상태
  factory EquippedItemsModel.empty() {
    return const EquippedItemsModel();
  }
}

