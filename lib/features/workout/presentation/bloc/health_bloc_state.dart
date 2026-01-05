/// BLoC states for health feature UI
///
/// These states are emitted by HealthBloc and consumed by the UI layer.
/// They wrap HealthState with workout data for rendering.

import 'package:equatable/equatable.dart';
import '../../domain/entities/health_state.dart';
import '../../domain/entities/workout_entity.dart';

/// Base class for all health BLoC states
abstract class HealthBlocState extends Equatable {
  /// Core health state information
  final HealthState healthState;

  /// List of workout entities (empty if not loaded)
  final List<WorkoutEntity> workouts;

  /// Computed total calories from all workouts
  final int totalCalories;

  /// Computed total duration in minutes from all workouts
  final int totalDurationMinutes;

  const HealthBlocState({
    required this.healthState,
    this.workouts = const [],
    this.totalCalories = 0,
    this.totalDurationMinutes = 0,
  });

  /// Convenience getters that delegate to healthState
  HealthUIState get uiState => healthState.uiState;
  HealthAuthorizationStatus get authorizationStatus =>
      healthState.authorizationStatus;
  HealthConnectInstallStatus? get installStatus => healthState.installStatus;
  bool? get hasWorkoutData => healthState.hasWorkoutData;
  String? get errorMessage => healthState.errorMessage;
  int get workoutCount => healthState.workoutCount;

  bool get isLoading => healthState.isLoading;
  bool get isError => healthState.isError;
  bool get isShowingWorkouts => healthState.isShowingWorkouts;
  bool get isPermissionRequired => healthState.isPermissionRequired;

  @override
  List<Object?> get props => [
        healthState,
        workouts,
        totalCalories,
        totalDurationMinutes,
      ];
}

/// Initial state - app just launched
class HealthBlocInitial extends HealthBlocState {
  HealthBlocInitial()
      : super(
          healthState: HealthState.initial(),
        );
}

/// Loading state - permission check or data fetch in progress
class HealthBlocLoading extends HealthBlocState {
  HealthBlocLoading()
      : super(
          healthState: HealthState.loading(),
        );
}

/// iOS: Permission required (empty data scenario)
class HealthBlocIOSPermissionRequired extends HealthBlocState {
  HealthBlocIOSPermissionRequired({
    required HealthAuthorizationStatus authStatus,
  }) : super(
          healthState: HealthState.iosPermissionRequired(
            authStatus: authStatus,
          ),
        );
}

/// iOS: Workout empty state
class HealthBlocIOSWorkoutEmpty extends HealthBlocState {
  HealthBlocIOSWorkoutEmpty({
    required HealthAuthorizationStatus authStatus,
  }) : super(
          healthState: HealthState.iosWorkoutEmpty(
            authStatus: authStatus,
          ),
        );
}

/// Android: Health Connect not installed
class HealthBlocAndroidHCNotInstalled extends HealthBlocState {
  HealthBlocAndroidHCNotInstalled()
      : super(
          healthState: HealthState.androidHCNotInstalled(),
        );
}

/// Android: Permission required
class HealthBlocAndroidPermissionRequired extends HealthBlocState {
  HealthBlocAndroidPermissionRequired()
      : super(
          healthState: HealthState.androidPermissionRequired(),
        );
}

/// Android: Workout empty (all conditions met, just no data)
class HealthBlocAndroidWorkoutEmpty extends HealthBlocState {
  HealthBlocAndroidWorkoutEmpty()
      : super(
          healthState: HealthState.androidWorkoutEmpty(),
        );
}

/// Workout data loaded successfully
class HealthBlocWorkoutLoaded extends HealthBlocState {
  HealthBlocWorkoutLoaded({
    required HealthAuthorizationStatus authStatus,
    HealthConnectInstallStatus? installStatus,
    required List<WorkoutEntity> workouts,
  }) : super(
          healthState: HealthState.workoutLoaded(
            authStatus: authStatus,
            installStatus: installStatus,
            workoutCount: workouts.length,
          ),
          workouts: workouts,
          totalCalories: _calculateTotalCalories(workouts),
          totalDurationMinutes: _calculateTotalDuration(workouts),
        );

  /// Calculate total calories from workouts
  static int _calculateTotalCalories(List<WorkoutEntity> workouts) {
    return workouts.fold<int>(
      0,
      (sum, workout) => sum + (workout.calories ?? 0),
    );
  }

  /// Calculate total duration in minutes from workouts
  static int _calculateTotalDuration(List<WorkoutEntity> workouts) {
    return workouts.fold<int>(
      0,
      (sum, workout) => sum + workout.durationMinutes,
    );
  }
}

/// Error state
class HealthBlocError extends HealthBlocState {
  HealthBlocError({
    required String message,
    required HealthAuthorizationStatus authStatus,
    HealthConnectInstallStatus? installStatus,
  }) : super(
          healthState: HealthState.error(
            message: message,
            authStatus: authStatus,
            installStatus: installStatus,
          ),
        );
}
