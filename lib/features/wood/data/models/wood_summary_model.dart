import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_summary_entity.dart';

/// WoodSummaryEntity의 Firestore 데이터 모델
class WoodSummaryModel extends WoodSummaryEntity {
  const WoodSummaryModel({
    required super.totalWood,
    required super.lifetimeEarned,
    super.lastSettlementDate,
  });

  /// Firestore 문서에서 생성
  factory WoodSummaryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WoodSummaryModel(
      totalWood: (data['totalWood'] as num?)?.toInt() ?? 0,
      lifetimeEarned: (data['lifetimeEarned'] as num?)?.toInt() ?? 0,
      lastSettlementDate: data['lastSettlementDate'] as String?,
    );
  }

  /// Map에서 생성
  factory WoodSummaryModel.fromMap(Map<String, dynamic> data) {
    return WoodSummaryModel(
      totalWood: (data['totalWood'] as num?)?.toInt() ?? 0,
      lifetimeEarned: (data['lifetimeEarned'] as num?)?.toInt() ?? 0,
      lastSettlementDate: data['lastSettlementDate'] as String?,
    );
  }

  /// Entity에서 생성
  factory WoodSummaryModel.fromEntity(WoodSummaryEntity entity) {
    return WoodSummaryModel(
      totalWood: entity.totalWood,
      lifetimeEarned: entity.lifetimeEarned,
      lastSettlementDate: entity.lastSettlementDate,
    );
  }

  /// 초기 상태
  factory WoodSummaryModel.initial() {
    return const WoodSummaryModel(
      totalWood: 0,
      lifetimeEarned: 0,
      lastSettlementDate: null,
    );
  }

  /// Firestore 저장용 Map
  Map<String, dynamic> toFirestore() {
    return {
      'totalWood': totalWood,
      'lifetimeEarned': lifetimeEarned,
      'lastSettlementDate': lastSettlementDate,
    };
  }

  /// 업데이트용 Map (null 값 제외)
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{
      'totalWood': totalWood,
      'lifetimeEarned': lifetimeEarned,
    };
    if (lastSettlementDate != null) {
      map['lastSettlementDate'] = lastSettlementDate;
    }
    return map;
  }
}

