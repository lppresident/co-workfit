/// 운동 강도 타입
enum WorkoutIntensity {
  /// 저강도 (심박수 없음 or < 100 bpm)
  low,

  /// 중강도 (100-130 bpm)
  moderate,

  /// 고강도 (130-150 bpm)
  high,

  /// 매우 고강도 (150+ bpm)
  veryHigh,
}

extension WorkoutIntensityExtension on WorkoutIntensity {
  String get displayName {
    switch (this) {
      case WorkoutIntensity.low:
        return '저강도';
      case WorkoutIntensity.moderate:
        return '중강도';
      case WorkoutIntensity.high:
        return '고강도';
      case WorkoutIntensity.veryHigh:
        return '매우 고강도';
    }
  }

  double get coefficient {
    switch (this) {
      case WorkoutIntensity.low:
        return 0.5;
      case WorkoutIntensity.moderate:
        return 0.83;
      case WorkoutIntensity.high:
        return 1.0;
      case WorkoutIntensity.veryHigh:
        return 1.3;
    }
  }

  /// 심박수로부터 강도 타입 결정
  static WorkoutIntensity fromHeartRate(int? avgHeartRate) {
    if (avgHeartRate == null || avgHeartRate < 100) {
      return WorkoutIntensity.low;
    } else if (avgHeartRate < 130) {
      return WorkoutIntensity.moderate;
    } else if (avgHeartRate < 150) {
      return WorkoutIntensity.high;
    } else {
      return WorkoutIntensity.veryHigh;
    }
  }
}

/// 헬스 점수 계산 유틸리티
class StrengthScoreCalculator {
  /// 헬스 점수 계산
  /// 
  /// 공식: 시간(분) × 강도계수
  /// 예: 60분 × 0.83(중강도) = 50점
  static double calculateStrengthScore({
    required int durationMinutes,
    int? avgHeartRate,
  }) {
    final intensity = WorkoutIntensityExtension.fromHeartRate(avgHeartRate);
    return durationMinutes * intensity.coefficient;
  }
}

