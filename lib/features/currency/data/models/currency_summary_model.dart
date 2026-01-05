import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_summary_entity.dart';

/// 재화 보유 현황 Firestore 모델
class CurrencySummaryModel {
  /// 재화별 현재 보유량
  final Map<CurrencyType, int> amounts;

  /// 재화별 누적 획득량
  final Map<CurrencyType, int> lifetimeEarned;

  /// 마지막 정산 날짜
  final DateTime? lastSettlementDate;

  const CurrencySummaryModel({
    required this.amounts,
    required this.lifetimeEarned,
    this.lastSettlementDate,
  });

  /// Firestore 문서에서 생성
  factory CurrencySummaryModel.fromFirestore(Map<String, dynamic> data) {
    final amounts = <CurrencyType, int>{};
    final lifetimeEarned = <CurrencyType, int>{};

    for (final type in CurrencyType.values) {
      amounts[type] = (data['${type.name}Amount'] as int?) ?? 0;
      lifetimeEarned[type] = (data['${type.name}LifetimeEarned'] as int?) ?? 0;
    }

    DateTime? lastSettlement;
    final lastSettlementData = data['lastSettlementDate'];
    if (lastSettlementData is Timestamp) {
      lastSettlement = lastSettlementData.toDate();
    } else if (lastSettlementData is String) {
      lastSettlement = DateTime.tryParse(lastSettlementData);
    }

    return CurrencySummaryModel(
      amounts: amounts,
      lifetimeEarned: lifetimeEarned,
      lastSettlementDate: lastSettlement,
    );
  }

  /// Firestore 저장용 Map 변환
  Map<String, dynamic> toFirestore() {
    final data = <String, dynamic>{};

    for (final type in CurrencyType.values) {
      data['${type.name}Amount'] = amounts[type] ?? 0;
      data['${type.name}LifetimeEarned'] = lifetimeEarned[type] ?? 0;
    }

    if (lastSettlementDate != null) {
      data['lastSettlementDate'] = Timestamp.fromDate(lastSettlementDate!);
    }

    return data;
  }

  /// Entity로 변환
  CurrencySummaryEntity toEntity() {
    return CurrencySummaryEntity(
      amounts: amounts,
      lifetimeEarned: lifetimeEarned,
      lastSettlementDate: lastSettlementDate,
    );
  }

  /// Entity에서 생성
  factory CurrencySummaryModel.fromEntity(CurrencySummaryEntity entity) {
    return CurrencySummaryModel(
      amounts: entity.amounts,
      lifetimeEarned: entity.lifetimeEarned,
      lastSettlementDate: entity.lastSettlementDate,
    );
  }
}


