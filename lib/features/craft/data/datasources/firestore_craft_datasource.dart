import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/core/utils/logger.dart';
import '../models/inventory_item_model.dart';
import '../models/equipped_items_model.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/item_recipes.dart';

/// Firestore 제작 시스템 DataSource
class FirestoreCraftDataSource {
  final FirebaseFirestore firestore;

  // Collection 경로
  static const String _usersCollection = 'users';
  static const String _inventorySubcollection = 'inventory';

  FirestoreCraftDataSource({required this.firestore});

  // ========== 아이템 마스터 데이터 ==========

  /// 모든 아이템 레시피 조회 (로컬 데이터 사용)
  Future<List<ItemEntity>> getAllRecipes() async {
    // Phase 1: 로컬 정적 데이터 사용
    // Phase 2+: Firestore에서 동적 로드 가능
    return ItemRecipes.allItems;
  }

  /// ID로 아이템 조회
  Future<ItemEntity?> getItemById(String itemId) async {
    return ItemRecipes.getItemById(itemId);
  }

  // ========== 인벤토리 ==========

  /// 사용자 인벤토리 조회
  Future<List<InventoryItemModel>> getInventory(String userId) async {
    try {
      final snapshot = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_inventorySubcollection)
          .get();

      return snapshot.docs
          .map((doc) => InventoryItemModel.fromFirestore(doc))
          .where((item) => item.quantity > 0)
          .toList();
    } catch (e) {
      AppLogger.error('FirestoreCraftDataSource', '인벤토리 조회 실패', e);
      return [];
    }
  }

  /// 인벤토리에 아이템 추가
  Future<void> addToInventory(
    String userId,
    String itemId,
    int quantity,
  ) async {
    try {
      final docRef = firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_inventorySubcollection)
          .doc(itemId);

      await firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (doc.exists) {
          // 기존 아이템 수량 증가
          final currentQuantity =
              (doc.data()?['quantity'] as num?)?.toInt() ?? 0;
          transaction.update(docRef, {
            'quantity': currentQuantity + quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // 신규 아이템 추가
          final newItem = InventoryItemModel.create(itemId, quantity: quantity);
          transaction.set(docRef, newItem.toFirestore());
        }
      });

      AppLogger.info(
        'FirestoreCraftDataSource',
        '아이템 추가: $itemId x$quantity (userId: $userId)',
      );
    } catch (e) {
      AppLogger.error('FirestoreCraftDataSource', '아이템 추가 실패', e);
      rethrow;
    }
  }

  /// 인벤토리에서 아이템 제거
  Future<void> removeFromInventory(
    String userId,
    String itemId,
    int quantity,
  ) async {
    try {
      final docRef = firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_inventorySubcollection)
          .doc(itemId);

      await firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          throw Exception('아이템이 인벤토리에 없습니다: $itemId');
        }

        final currentQuantity =
            (doc.data()?['quantity'] as num?)?.toInt() ?? 0;
        if (currentQuantity < quantity) {
          throw Exception('아이템 수량이 부족합니다: $itemId');
        }

        final newQuantity = currentQuantity - quantity;
        if (newQuantity <= 0) {
          transaction.delete(docRef);
        } else {
          transaction.update(docRef, {
            'quantity': newQuantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      AppLogger.info(
        'FirestoreCraftDataSource',
        '아이템 제거: $itemId x$quantity (userId: $userId)',
      );
    } catch (e) {
      AppLogger.error('FirestoreCraftDataSource', '아이템 제거 실패', e);
      rethrow;
    }
  }

  /// 특정 아이템 보유 수량 조회
  Future<int> getItemQuantity(String userId, String itemId) async {
    try {
      final doc = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_inventorySubcollection)
          .doc(itemId)
          .get();

      if (!doc.exists) return 0;
      return (doc.data()?['quantity'] as num?)?.toInt() ?? 0;
    } catch (e) {
      AppLogger.error('FirestoreCraftDataSource', '아이템 수량 조회 실패', e);
      return 0;
    }
  }

  // ========== 장착 ==========

  /// 장착 아이템 조회
  Future<EquippedItemsModel> getEquippedItems(String userId) async {
    try {
      final doc = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return EquippedItemsModel.empty();
      }

      final data = doc.data();
      if (data == null || data['equippedItems'] == null) {
        return EquippedItemsModel.empty();
      }

      return EquippedItemsModel.fromMap(
        data['equippedItems'] as Map<String, dynamic>,
      );
    } catch (e) {
      AppLogger.error('FirestoreCraftDataSource', '장착 아이템 조회 실패', e);
      return EquippedItemsModel.empty();
    }
  }

  /// 장착 아이템 업데이트
  Future<void> updateEquippedItems(
    String userId,
    EquippedItemsModel equipped,
  ) async {
    try {
      await firestore.collection(_usersCollection).doc(userId).update({
        'equippedItems': equipped.toFirestore(),
      });

      AppLogger.info(
        'FirestoreCraftDataSource',
        '장착 아이템 업데이트 (userId: $userId)',
      );
    } catch (e) {
      AppLogger.error('FirestoreCraftDataSource', '장착 아이템 업데이트 실패', e);
      rethrow;
    }
  }

  // ========== 통나무 관련 ==========

  /// 현재 통나무 보유량 조회
  Future<int> getWoodAmount(String userId) async {
    try {
      final doc = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return 0;
      return (doc.data()?['woodAmount'] as num?)?.toInt() ?? 0;
    } catch (e) {
      AppLogger.error('FirestoreCraftDataSource', '통나무 조회 실패', e);
      return 0;
    }
  }

  /// 통나무 사용 (제작 시)
  Future<void> useWood(String userId, int amount) async {
    try {
      await firestore.runTransaction((transaction) async {
        final userRef = firestore.collection(_usersCollection).doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('사용자 정보가 없습니다');
        }

        final currentAmount =
            (userDoc.data()?['woodAmount'] as num?)?.toInt() ?? 0;
        if (currentAmount < amount) {
          throw Exception(
              '통나무가 부족합니다. 보유: $currentAmount, 필요: $amount');
        }

        transaction.update(userRef, {
          'woodAmount': FieldValue.increment(-amount),
        });
      });

      AppLogger.info(
        'FirestoreCraftDataSource',
        '통나무 $amount개 사용 (userId: $userId)',
      );
    } catch (e) {
      AppLogger.error('FirestoreCraftDataSource', '통나무 사용 실패', e);
      rethrow;
    }
  }
}

