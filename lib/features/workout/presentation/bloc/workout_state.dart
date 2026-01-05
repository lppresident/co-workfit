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

  // 전체 기간 통계
  final int totalScore;
  final int totalCalories;
  final int totalDuration;

  // 오늘 통계
  final int todayScore;
  final int todayCalories;
  final int todayDuration;

  const WorkoutLoaded({
    required this.workouts,
    required this.totalScore,
    required this.totalCalories,
    required this.totalDuration,
    required this.todayScore,
    required this.todayCalories,
    required this.todayDuration,
  });

  @override
  List<Object?> get props => [
        workouts,
        totalScore,
        totalCalories,
        totalDuration,
        todayScore,
        todayCalories,
        todayDuration,
      ];

  /// 통계 계산
  factory WorkoutLoaded.fromWorkouts(List<WorkoutEntity> workouts) {
    // 전체 기간 통계
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

    // 오늘 날짜 운동만 필터링
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayWorkouts = workouts.where((workout) {
      return workout.startTime.isAfter(todayStart) &&
          workout.startTime.isBefore(todayEnd);
    }).toList();

    // 오늘 통계
    final todayScore = todayWorkouts.fold<int>(
      0,
      (sum, workout) => sum + workout.calibratedScore,
    );

    final todayCalories = todayWorkouts.fold<int>(
      0,
      (sum, workout) => sum + (workout.calories ?? 0),
    );

    final todayDuration = todayWorkouts.fold<int>(
      0,
      (sum, workout) => sum + workout.durationMinutes,
    );

    return WorkoutLoaded(
      workouts: workouts,
      totalScore: totalScore,
      totalCalories: totalCalories,
      totalDuration: totalDuration,
      todayScore: todayScore,
      todayCalories: todayCalories,
      todayDuration: todayDuration,
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

/// 동기화 중
class WorkoutSyncing extends WorkoutState {
  const WorkoutSyncing();
}

/// 동기화 성공
class WorkoutSyncSuccess extends WorkoutState {
  final int uploadedCount;

  const WorkoutSyncSuccess(this.uploadedCount);

  @override
  List<Object?> get props => [uploadedCount];
}

/// 동기화 실패
class WorkoutSyncFailure extends WorkoutState {
  final String message;

  const WorkoutSyncFailure(this.message);

  @override
  List<Object?> get props => [message];
}
