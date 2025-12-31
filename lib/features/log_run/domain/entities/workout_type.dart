/// 챌린지 운동 타입
enum ChallengeType {
  /// 달리기 (거리 기반)
  running,

  /// 웨이트 트레이닝 (시간×심박수 기반)
  strengthTraining,
}

extension ChallengeTypeExtension on ChallengeType {
  String get displayName {
    switch (this) {
      case ChallengeType.running:
        return '달리기';
      case ChallengeType.strengthTraining:
        return '헬스';
    }
  }

  String get emoji {
    switch (this) {
      case ChallengeType.running:
        return '🏃';
      case ChallengeType.strengthTraining:
        return '🏋️';
    }
  }

  String get currencyEmoji {
    switch (this) {
      case ChallengeType.running:
        return '🪵';
      case ChallengeType.strengthTraining:
        return '🔩';
    }
  }

  String get currencyName {
    switch (this) {
      case ChallengeType.running:
        return '통나무';
      case ChallengeType.strengthTraining:
        return '쇠';
    }
  }

  String get unitName {
    switch (this) {
      case ChallengeType.running:
        return 'km';
      case ChallengeType.strengthTraining:
        return '점';
    }
  }

  String toFirestore() {
    switch (this) {
      case ChallengeType.running:
        return 'running';
      case ChallengeType.strengthTraining:
        return 'strength_training';
    }
  }

  static ChallengeType fromFirestore(String? value) {
    switch (value) {
      case 'strength_training':
        return ChallengeType.strengthTraining;
      case 'running':
      default:
        return ChallengeType.running;
    }
  }
}

