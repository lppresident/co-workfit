import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

/// 플랫폼별 캘리브레이션 설정
class CalibrationConfig extends Equatable {
  final WorkoutSource source;

  // 각 지표별 가중치 (합이 1.0이 되도록)
  final double caloriesWeight;
  final double heartRateWeight;
  final double durationWeight;
  final double distanceWeight;

  // 플랫폼별 보정 계수 (각 플랫폼의 측정 특성을 반영)
  final double platformAdjustmentFactor;

  const CalibrationConfig({
    required this.source,
    this.caloriesWeight = 0.35,
    this.heartRateWeight = 0.30,
    this.durationWeight = 0.20,
    this.distanceWeight = 0.15,
    this.platformAdjustmentFactor = 1.0,
  });

  @override
  List<Object?> get props => [
        source,
        caloriesWeight,
        heartRateWeight,
        durationWeight,
        distanceWeight,
        platformAdjustmentFactor,
      ];

  /// 플랫폼별 기본 설정 가져오기
  static CalibrationConfig getDefaultConfig(WorkoutSource source) {
    switch (source) {
      case WorkoutSource.garmin:
        // Garmin은 일반적으로 칼로리를 높게 측정하는 경향
        return const CalibrationConfig(
          source: WorkoutSource.garmin,
          platformAdjustmentFactor: 0.95,
          caloriesWeight: 0.30,
          heartRateWeight: 0.35,
          durationWeight: 0.20,
          distanceWeight: 0.15,
        );

      case WorkoutSource.appleHealth:
        // Apple은 심박수 데이터가 정확한 편
        return const CalibrationConfig(
          source: WorkoutSource.appleHealth,
          platformAdjustmentFactor: 1.0,
          heartRateWeight: 0.35,
        );

      case WorkoutSource.googleFit:
        // Google Fit은 걸음수/거리 기반이 강함
        return const CalibrationConfig(
          source: WorkoutSource.googleFit,
          platformAdjustmentFactor: 1.05,
          distanceWeight: 0.20,
          durationWeight: 0.25,
        );

      case WorkoutSource.samsungHealth:
        // Samsung은 비교적 균형잡힌 측정
        return const CalibrationConfig(
          source: WorkoutSource.samsungHealth,
          platformAdjustmentFactor: 1.0,
        );

      case WorkoutSource.manual:
        // 수동 입력은 보수적으로 평가
        return const CalibrationConfig(
          source: WorkoutSource.manual,
          platformAdjustmentFactor: 0.90,
        );
    }
  }

  CalibrationConfig copyWith({
    WorkoutSource? source,
    double? caloriesWeight,
    double? heartRateWeight,
    double? durationWeight,
    double? distanceWeight,
    double? platformAdjustmentFactor,
  }) {
    return CalibrationConfig(
      source: source ?? this.source,
      caloriesWeight: caloriesWeight ?? this.caloriesWeight,
      heartRateWeight: heartRateWeight ?? this.heartRateWeight,
      durationWeight: durationWeight ?? this.durationWeight,
      distanceWeight: distanceWeight ?? this.distanceWeight,
      platformAdjustmentFactor:
          platformAdjustmentFactor ?? this.platformAdjustmentFactor,
    );
  }
}

/// 캘리브레이션 결과
class CalibrationResult extends Equatable {
  final double workload; // 0-100 스케일의 노동 강도
  final int score; // 실제 점수
  final Map<String, double> breakdown; // 각 지표별 기여도

  const CalibrationResult({
    required this.workload,
    required this.score,
    required this.breakdown,
  });

  @override
  List<Object?> get props => [workload, score, breakdown];
}
