/// 챌린지 운동 타입
enum ChallengeType {
  /// 달리기 (거리 기반) → 통나무
  running,

  /// 웨이트 트레이닝 (시간×심박수 기반) → 쇠
  strengthTraining,

  /// 기타 운동 (걷기, 수영, 요가 등) → 흙
  other,
}

extension ChallengeTypeExtension on ChallengeType {
  String get displayName {
    switch (this) {
      case ChallengeType.running:
        return '달리기';
      case ChallengeType.strengthTraining:
        return '헬스';
      case ChallengeType.other:
        return '기타';
    }
  }

  String get emoji {
    switch (this) {
      case ChallengeType.running:
        return '🏃';
      case ChallengeType.strengthTraining:
        return '🏋️';
      case ChallengeType.other:
        return '🏅';
    }
  }

  String get currencyEmoji {
    switch (this) {
      case ChallengeType.running:
        return '🪵';
      case ChallengeType.strengthTraining:
        return '🔩';
      case ChallengeType.other:
        return '🪨';
    }
  }

  String get currencyName {
    switch (this) {
      case ChallengeType.running:
        return '통나무';
      case ChallengeType.strengthTraining:
        return '쇠';
      case ChallengeType.other:
        return '흙';
    }
  }

  String get unitName {
    // 모든 단위는 kg으로 통일
    return 'kg';
  }

  /// 원본 단위 이름 (UI 표시용)
  String get originalUnitName {
    switch (this) {
      case ChallengeType.running:
        return 'km';
      case ChallengeType.strengthTraining:
        return '점';
      case ChallengeType.other:
        return '분';
    }
  }

  String toFirestore() {
    switch (this) {
      case ChallengeType.running:
        return 'running';
      case ChallengeType.strengthTraining:
        return 'strength_training';
      case ChallengeType.other:
        return 'other';
    }
  }

  static ChallengeType fromFirestore(String? value) {
    switch (value) {
      case 'strength_training':
        return ChallengeType.strengthTraining;
      case 'other':
        return ChallengeType.other;
      case 'running':
      default:
        return ChallengeType.running;
    }
  }
}

