import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

/// 운동 타입별 무게(kg) 변환 유틸리티
///
/// 챌린지 시스템에서 사용하는 표준 단위인 kg으로 변환합니다.
///
/// 변환 우선순위:
/// 1. 달리기: 거리 기반 (1km = 1kg)
/// 2. 기타 운동: 칼로리 기반 (10 kcal = 1kg)
/// 3. 대체 (칼로리 없음): 심박수 × 시간 기반 (10점 = 1kg)
/// 4. 최소 (심박수도 없음): 시간 기반 저강도 (1시간 = 5kg)
class WorkoutConverter {
  WorkoutConverter._();

  /// 칼로리 → kg 변환 비율
  /// 100 kcal = 1 kg
  static const double _caloriesPerKg = 100.0;

  /// 점수 → kg 변환 비율 (심박수×시간 기반)
  /// 10점 = 1 kg
  static const double _scorePerKg = 10.0;

  /// 저강도 운동 기본 점수 (심박수 데이터 없을 때)
  /// 시간당 50점 (저강도 심박수 100 bpm × 0.5 계수 가정)
  static const double _lowIntensityScorePerHour = 50.0;

  /// 달리기 거리(km)를 무게(kg)로 변환
  ///
  /// 1km = 1kg 으로 직접 매핑
  static double runningToWeight(double distanceKm) {
    return distanceKm;
  }

  /// 칼로리를 무게(kg)로 변환
  ///
  /// 10 kcal = 1kg
  /// 예: 30 kcal → 3kg, 100 kcal → 10kg
  static double caloriesToWeight(int calories) {
    return calories / _caloriesPerKg;
  }

  /// 점수를 무게(kg)로 변환 (심박수×시간 기반)
  ///
  /// 10점 = 1kg
  /// 예: 40점 → 4kg, 100점 → 10kg
  static double scoreToWeight(int score) {
    return score / _scorePerKg;
  }

  /// 시간을 저강도 무게(kg)로 변환 (fallback)
  ///
  /// 시간당 50점 기준 (저강도)
  /// 예: 60분 → 50점 → 5kg
  static double durationToLowIntensityWeight(int durationSeconds) {
    final hours = durationSeconds / 3600.0;
    final score = hours * _lowIntensityScorePerHour;
    return scoreToWeight(score.round());
  }

  /// WorkoutEntity에서 무게(kg) 추출
  ///
  /// 우선순위:
  /// 1. 달리기 → 거리 기반
  /// 2. 칼로리 데이터 있음 → 칼로리 기반
  /// 3. 모두 없음 → 시간 기반 저강도
  static double fromWorkout(WorkoutEntity workout) {
    // 1. 달리기: 거리 기반 (우선)
    if (workout.type == WorkoutType.running) {
      final distance = workout.correctedDistance ?? workout.distance ?? 0.0;
      return runningToWeight(distance);
    }

    // 2. 칼로리 데이터 있음: 칼로리 기반
    if (workout.calories != null && workout.calories! > 0) {
      return caloriesToWeight(workout.calories!);
    }

    // 3. 모두 없음: 시간 기반 저강도 (최소 보장)
    return durationToLowIntensityWeight(workout.durationSeconds);
  }

  /// 무게(kg)를 달리기 거리(km)로 역변환
  static double weightToRunningDistance(double weightKg) {
    return weightKg; // 1:1 매핑
  }

  /// 무게(kg)를 칼로리로 역변환
  static int weightToCalories(double weightKg) {
    return (weightKg * _caloriesPerKg).round();
  }

  /// 무게(kg)를 점수로 역변환
  static int weightToScore(double weightKg) {
    return (weightKg * _scorePerKg).round();
  }

  /// 운동 타입별 예상 칼로리 (참고용)
  ///
  /// 1시간 평균 기준 (kcal)
  static int getEstimatedCaloriesPerHour(WorkoutType type) {
    switch (type) {
      case WorkoutType.running:
        return 600; // 10km/h 기준
      case WorkoutType.cycling:
        return 500;
      case WorkoutType.swimming:
        return 600;
      case WorkoutType.weightTraining:
        return 400;
      case WorkoutType.walking:
        return 200;
      case WorkoutType.hiking:
        return 450;
      case WorkoutType.yoga:
        return 150;
      default:
        return 300; // 기본값
    }
  }

  /// 운동 데이터의 변환 방식 확인 (디버깅/UI용)
  static String getConversionMethod(WorkoutEntity workout) {
    if (workout.type == WorkoutType.running &&
        (workout.distance != null || workout.correctedDistance != null)) {
      return '거리 기반';
    }
    if (workout.calories != null && workout.calories! > 0) {
      return '칼로리 기반';
    }
    return '시간 기반 (저강도)';
  }
}
