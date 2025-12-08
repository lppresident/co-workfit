import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

/// 운동 상태
abstract class WorkoutState extends Equatable {
  const WorkoutState();

  @override
  List<Object?> get props => [];
}

/// 초기 상태
class WorkoutInitial extends WorkoutState {
  const WorkoutInitial();
}

/// 로딩 중
class WorkoutLoading extends WorkoutState {
  const WorkoutLoading();
}

/// 권한 요청 중
class WorkoutPermissionRequesting extends WorkoutState {
  const WorkoutPermissionRequesting();
}

/// 권한 승인됨
class WorkoutPermissionGranted extends WorkoutState {
  const WorkoutPermissionGranted();
}

/// 권한 거부됨
class WorkoutPermissionDenied extends WorkoutState {
  final String message;

  const WorkoutPermissionDenied(this.message);

  @override
  List<Object?> get props => [message];
}

/// 운동 데이터 로드 성공
class WorkoutLoaded extends WorkoutState {
  final List<WorkoutEntity> workouts;
  final int totalScore;
  final int totalCalories;
  final int totalDuration;

  const WorkoutLoaded({
    required this.workouts,
    required this.totalScore,
    required this.totalCalories,
    required this.totalDuration,
  });

  @override
  List<Object?> get props => [
        workouts,
        totalScore,
        totalCalories,
        totalDuration,
      ];

  /// 통계 계산
  factory WorkoutLoaded.fromWorkouts(List<WorkoutEntity> workouts) {
    final totalScore = workouts.fold<int>(
      0,
      (sum, workout) => sum + workout.calibratedScore,
    );

    final totalCalories = workouts.fold<int>(
      0,
      (sum, workout) => sum + (workout.calories ?? 0),
    );

    final totalDuration = workouts.fold<int>(
      0,
      (sum, workout) => sum + workout.durationMinutes,
    );

    return WorkoutLoaded(
      workouts: workouts,
      totalScore: totalScore,
      totalCalories: totalCalories,
      totalDuration: totalDuration,
    );
  }
}

/// 운동 데이터 없음
class WorkoutEmpty extends WorkoutState {
  const WorkoutEmpty();
}

/// 에러 발생
class WorkoutError extends WorkoutState {
  final String message;

  const WorkoutError(this.message);

  @override
  List<Object?> get props => [message];
}
