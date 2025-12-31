/// 운동 타입
enum WorkoutType {
  /// 달리기 (거리 기반)
  running,

  /// 웨이트 트레이닝 (시간×심박수 기반)
  strengthTraining,
}

extension WorkoutTypeExtension on WorkoutType {
  String get displayName {
    switch (this) {
      case WorkoutType.running:
        return '달리기';
      case WorkoutType.strengthTraining:
        return '헬스';
    }
  }

  String get emoji {
    switch (this) {
      case WorkoutType.running:
        return '🏃';
      case WorkoutType.strengthTraining:
        return '🏋️';
    }
  }

  String get currencyEmoji {
    switch (this) {
      case WorkoutType.running:
        return '🪵';
      case WorkoutType.strengthTraining:
        return '🔩';
    }
  }

  String get currencyName {
    switch (this) {
      case WorkoutType.running:
        return '통나무';
      case WorkoutType.strengthTraining:
        return '쇠';
    }
  }

  String get unitName {
    switch (this) {
      case WorkoutType.running:
        return 'km';
      case WorkoutType.strengthTraining:
        return '점';
    }
  }

  String toFirestore() {
    switch (this) {
      case WorkoutType.running:
        return 'running';
      case WorkoutType.strengthTraining:
        return 'strength_training';
    }
  }

  static WorkoutType fromFirestore(String? value) {
    switch (value) {
      case 'strength_training':
        return WorkoutType.strengthTraining;
      case 'running':
      default:
        return WorkoutType.running;
    }
  }
}

