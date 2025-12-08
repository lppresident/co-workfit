import 'dart:math';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/calibration/domain/entities/calibration_config.dart';

/// 운동 데이터를 캘리브레이션하는 유스케이스
class CalibrateWorkout {
  /// 운동 데이터를 캘리브레이션하여 표준화된 workload와 score 계산
  CalibrationResult execute(WorkoutEntity workout) {
    final config = CalibrationConfig.getDefaultConfig(workout.source);

    // 각 지표를 0-100 스케일로 정규화
    final normalizedCalories = _normalizeCalories(workout.calories);
    final normalizedHeartRate = _normalizeHeartRate(
      workout.averageHeartRate,
      workout.maxHeartRate,
    );
    final normalizedDuration = _normalizeDuration(workout.durationMinutes);
    final normalizedDistance = _normalizeDistance(
      workout.distance,
      workout.type,
    );

    // 가중치 적용하여 기본 workload 계산
    final baseWorkload = (normalizedCalories * config.caloriesWeight) +
        (normalizedHeartRate * config.heartRateWeight) +
        (normalizedDuration * config.durationWeight) +
        (normalizedDistance * config.distanceWeight);

    // 플랫폼 보정 계수 적용
    final calibratedWorkload =
        (baseWorkload * config.platformAdjustmentFactor).clamp(0.0, 100.0);

    // 운동 타입별 보너스 적용
    final typeMultiplier = _getTypeMultiplier(workout.type);
    final finalWorkload = (calibratedWorkload * typeMultiplier).clamp(0.0, 100.0);

    // 점수 계산 (workload를 기반으로 점수화)
    final score = _calculateScore(finalWorkload, workout.durationMinutes);

    // 각 지표별 기여도 저장
    final breakdown = {
      'calories': normalizedCalories * config.caloriesWeight,
      'heartRate': normalizedHeartRate * config.heartRateWeight,
      'duration': normalizedDuration * config.durationWeight,
      'distance': normalizedDistance * config.distanceWeight,
      'platformAdjustment': config.platformAdjustmentFactor,
      'typeMultiplier': typeMultiplier,
    };

    return CalibrationResult(
      workload: finalWorkload,
      score: score,
      breakdown: breakdown,
    );
  }

  /// 칼로리를 0-100 스케일로 정규화
  /// 800kcal 이상을 100점으로 설정
  double _normalizeCalories(int? calories) {
    if (calories == null || calories <= 0) return 0.0;
    const maxCalories = 800.0;
    return min(100.0, (calories / maxCalories) * 100);
  }

  /// 심박수를 0-100 스케일로 정규화
  /// 평균 심박수와 최대 심박수를 함께 고려
  double _normalizeHeartRate(int? avgHeartRate, int? maxHeartRate) {
    if (avgHeartRate == null) return 0.0;

    // 안정시 심박수 기준 (60 bpm)을 기준으로
    // 고강도 심박수 (160 bpm)까지를 100점으로
    const restingHR = 60.0;
    const maxIntensityHR = 160.0;

    final avgScore =
        ((avgHeartRate - restingHR) / (maxIntensityHR - restingHR)) * 100;

    // 최대 심박수가 있으면 추가 고려
    if (maxHeartRate != null && maxHeartRate > avgHeartRate) {
      final maxScore =
          ((maxHeartRate - restingHR) / (maxIntensityHR - restingHR)) * 100;
      return min(100.0, (avgScore * 0.7 + maxScore * 0.3));
    }

    return min(100.0, max(0.0, avgScore));
  }

  /// 운동 시간을 0-100 스케일로 정규화
  /// 90분 이상을 100점으로 설정
  double _normalizeDuration(int durationMinutes) {
    if (durationMinutes <= 0) return 0.0;
    const maxDuration = 90.0;
    return min(100.0, (durationMinutes / maxDuration) * 100);
  }

  /// 거리를 0-100 스케일로 정규화 (운동 타입에 따라 다름)
  double _normalizeDistance(double? distance, WorkoutType type) {
    if (distance == null || distance <= 0) return 0.0;

    double maxDistance;
    switch (type) {
      case WorkoutType.running:
        maxDistance = 10.0; // 10km
        break;
      case WorkoutType.cycling:
        maxDistance = 30.0; // 30km
        break;
      case WorkoutType.walking:
        maxDistance = 8.0; // 8km
        break;
      case WorkoutType.swimming:
        maxDistance = 2.0; // 2km
        break;
      default:
        maxDistance = 5.0;
    }

    return min(100.0, (distance / maxDistance) * 100);
  }

  /// 운동 타입별 난이도 계수
  double _getTypeMultiplier(WorkoutType type) {
    switch (type) {
      case WorkoutType.running:
        return 1.0;
      case WorkoutType.cycling:
        return 0.9;
      case WorkoutType.swimming:
        return 1.2; // 수영은 더 힘듦
      case WorkoutType.weightTraining:
        return 1.1;
      case WorkoutType.hiking:
        return 1.05;
      case WorkoutType.walking:
        return 0.7;
      case WorkoutType.yoga:
        return 0.8;
      case WorkoutType.other:
        return 1.0;
    }
  }

  /// workload와 시간을 기반으로 최종 점수 계산
  int _calculateScore(double workload, int durationMinutes) {
    // 기본 점수는 workload * 10
    final baseScore = workload * 10;

    // 시간 보너스 (30분 이상부터 보너스, 최대 20% 추가)
    final durationBonus = durationMinutes >= 30
        ? min(200.0, (durationMinutes - 30) * 2.0)
        : 0.0;

    return (baseScore + durationBonus).round();
  }
}
