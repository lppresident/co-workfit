import 'package:flutter/material.dart';

/// 재화 타입 정의
/// 
/// 새로운 재화를 추가하려면:
/// 1. 이 enum에 새 값 추가
/// 2. CurrencyConfig에 해당 재화의 설정 추가
/// 3. CurrencyConfigRegistry에 등록
enum CurrencyType {
  /// 통나무 - 달리기/유산소 운동
  wood,
  
  /// 쇠 - 웨이트/근력 운동
  iron,
  
  /// 흙 - 기타 운동 (걷기, 수영, 요가 등)
  soil,
}

extension CurrencyTypeExtension on CurrencyType {
  /// 재화 표시 이름
  String get displayName {
    switch (this) {
      case CurrencyType.wood:
        return '통나무';
      case CurrencyType.iron:
        return '쇠';
      case CurrencyType.soil:
        return '흙';
    }
  }
  
  /// 재화 이모지
  String get emoji {
    switch (this) {
      case CurrencyType.wood:
        return '🪵';
      case CurrencyType.iron:
        return '🔩';
      case CurrencyType.soil:
        return '🪨';
    }
  }
  
  /// 재화 색상
  Color get color {
    switch (this) {
      case CurrencyType.wood:
        return const Color(0xFF8B4513); // 갈색
      case CurrencyType.iron:
        return const Color(0xFF708090); // 회색
      case CurrencyType.soil:
        return const Color(0xFF6B4423); // 흙색
    }
  }
  
  /// Firestore 필드명 (amount)
  String get amountFieldName => '${name}Amount';
  
  /// Firestore 필드명 (lifetime earned)
  String get lifetimeFieldName => '${name}LifetimeEarned';
  
  /// Firestore 필드명 (last settlement date)
  String get lastSettlementFieldName => 'last${name[0].toUpperCase()}${name.substring(1)}SettlementDate';
}

