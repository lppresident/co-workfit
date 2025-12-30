import 'package:flutter_test/flutter_test.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/calibration/domain/usecases/calibrate_workout.dart';

void main() {
  late CalibrateWorkout calibrateWorkout;

  setUp(() {
    calibrateWorkout = CalibrateWorkout();
  });

  group('CalibrateWorkout', () {
    test('should calibrate a running workout correctly', () {
      // Arrange
      final workout = WorkoutEntity(
        id: 'test_1',
        userId: 'user_1',
        source: WorkoutSource.appleHealth,
        type: WorkoutType.running,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        durationSeconds: 30 * 60, // 30분 = 1800초
        distance: 5.0, // 5km
        calories: 400,
        averageHeartRate: 150,
        maxHeartRate: 170,
        steps: 6000,
        calibratedWorkload: 0, // 캘리브레이션 전
        calibratedScore: 0, // 캘리브레이션 전
        createdAt: DateTime.now(),
      );

      // Act
      final result = calibrateWorkout.execute(workout);

      // Assert
      expect(result.workload, greaterThan(0));
      expect(result.workload, lessThanOrEqualTo(100));
      expect(result.score, greaterThan(0));
      expect(result.breakdown, isNotEmpty);
    });

    test('should apply platform adjustment for Garmin', () {
      // Arrange
      final garminWorkout = WorkoutEntity(
        id: 'test_2',
        userId: 'user_1',
        source: WorkoutSource.garmin,
        type: WorkoutType.running,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        durationSeconds: 30 * 60, // 30분 = 1800초
        calories: 400,
        averageHeartRate: 150,
        calibratedWorkload: 0,
        calibratedScore: 0,
        createdAt: DateTime.now(),
      );

      final appleWorkout = garminWorkout.copyWith(
        source: WorkoutSource.appleHealth,
      );

      // Act
      final garminResult = calibrateWorkout.execute(garminWorkout);
      final appleResult = calibrateWorkout.execute(appleWorkout);

      // Assert
      // Garmin은 0.95 보정 계수를 가지므로 Apple보다 약간 낮아야 함
      expect(garminResult.workload, lessThan(appleResult.workload));
    });

    test('should apply workout type multiplier for swimming', () {
      // Arrange
      final swimmingWorkout = WorkoutEntity(
        id: 'test_3',
        userId: 'user_1',
        source: WorkoutSource.appleHealth,
        type: WorkoutType.swimming,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        durationSeconds: 30 * 60, // 30분 = 1800초
        calories: 400,
        averageHeartRate: 140,
        distance: 1.5,
        calibratedWorkload: 0,
        calibratedScore: 0,
        createdAt: DateTime.now(),
      );

      final runningWorkout = swimmingWorkout.copyWith(
        type: WorkoutType.running,
      );

      // Act
      final swimmingResult = calibrateWorkout.execute(swimmingWorkout);
      final runningResult = calibrateWorkout.execute(runningWorkout);

      // Assert
      // 수영은 1.2 배수를 가지므로 러닝보다 높아야 함
      expect(swimmingResult.workload, greaterThan(runningResult.workload));
    });

    test('should handle workout with no optional data', () {
      // Arrange
      final minimalWorkout = WorkoutEntity(
        id: 'test_4',
        userId: 'user_1',
        source: WorkoutSource.manual,
        type: WorkoutType.other,
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now(),
        durationSeconds: 30 * 60, // 30분 = 1800초
        calibratedWorkload: 0,
        calibratedScore: 0,
        createdAt: DateTime.now(),
      );

      // Act
      final result = calibrateWorkout.execute(minimalWorkout);

      // Assert
      expect(result.workload, greaterThanOrEqualTo(0));
      expect(result.score, greaterThanOrEqualTo(0));
    });
  });
}
