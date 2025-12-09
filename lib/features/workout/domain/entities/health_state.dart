// Domain entities for health permission and data state management
//
// This file defines the core state types used across iOS (HealthKit)
// and Android (Health Connect) health data flows.

import 'package:equatable/equatable.dart';

/// Authorization status for health data access
///
/// Maps to platform-specific authorization states:
/// - iOS: HealthKit authorization status
/// - Android: Combination of HC installation + permission status
enum HealthAuthorizationStatus {
  /// Permission has not been requested yet (iOS-specific)
  notDetermined,

  /// User has denied permission
  denied,

  /// User has granted permission
  granted,

  /// Unable to determine status (error state)
  unknown,
}

/// Installation status for Health Connect (Android-only)
enum HealthConnectInstallStatus {
  /// Health Connect app is installed
  installed,

  /// Health Connect app is not installed
  notInstalled,

  /// Unable to determine (error or not applicable)
  unknown,
}

/// UI state enum for the health feature
///
/// This represents the complete state of the health data UI,
/// driving all rendering decisions.
enum HealthUIState {
  /// Initial state before any operations
  initial,

  /// Loading state during permission/data checks
  loading,

  /// iOS: HealthKit data empty - show permission guidance
  /// This state is shown when workout data is empty because iOS
  /// cannot distinguish between "no data" and "no permission"
  iosPermissionRequired,

  /// iOS: Empty workout data + permission guidance already shown
  iosWorkoutEmpty,

  /// Android: Health Connect app not installed
  androidHCNotInstalled,

  /// Android: Health Connect installed but permissions denied
  androidPermissionRequired,

  /// Android: All conditions met but no workout data exists
  /// Unlike iOS, Android can distinguish this from permission issues
  androidWorkoutEmpty,

  /// Data loaded successfully (both platforms)
  workoutLoaded,

  /// Error occurred during operations
  error,
}

/// Complete health state snapshot
///
/// Contains all necessary information about current health data status
/// for a specific platform.
class HealthState extends Equatable {
  /// Current UI state
  final HealthUIState uiState;

  /// Current authorization status
  final HealthAuthorizationStatus authorizationStatus;

  /// Health Connect installation status (Android only, null on iOS)
  final HealthConnectInstallStatus? installStatus;

  /// Whether workout data exists (null if not yet checked)
  final bool? hasWorkoutData;

  /// Error message if uiState is error
  final String? errorMessage;

  /// Number of workouts loaded (0 if empty or not loaded)
  final int workoutCount;

  const HealthState({
    required this.uiState,
    required this.authorizationStatus,
    this.installStatus,
    this.hasWorkoutData,
    this.errorMessage,
    this.workoutCount = 0,
  });

  /// Initial state constructor
  factory HealthState.initial() {
    return const HealthState(
      uiState: HealthUIState.initial,
      authorizationStatus: HealthAuthorizationStatus.unknown,
      installStatus: null,
      hasWorkoutData: null,
    );
  }

  /// Loading state constructor
  factory HealthState.loading() {
    return const HealthState(
      uiState: HealthUIState.loading,
      authorizationStatus: HealthAuthorizationStatus.unknown,
      installStatus: null,
      hasWorkoutData: null,
    );
  }

  /// iOS permission required state (empty data scenario)
  factory HealthState.iosPermissionRequired({
    required HealthAuthorizationStatus authStatus,
  }) {
    return HealthState(
      uiState: HealthUIState.iosPermissionRequired,
      authorizationStatus: authStatus,
      installStatus: null,
      hasWorkoutData: false,
    );
  }

  /// iOS workout empty state
  factory HealthState.iosWorkoutEmpty({
    required HealthAuthorizationStatus authStatus,
  }) {
    return HealthState(
      uiState: HealthUIState.iosWorkoutEmpty,
      authorizationStatus: authStatus,
      installStatus: null,
      hasWorkoutData: false,
    );
  }

  /// Android HC not installed state
  factory HealthState.androidHCNotInstalled() {
    return const HealthState(
      uiState: HealthUIState.androidHCNotInstalled,
      authorizationStatus: HealthAuthorizationStatus.unknown,
      installStatus: HealthConnectInstallStatus.notInstalled,
      hasWorkoutData: null,
    );
  }

  /// Android permission required state
  factory HealthState.androidPermissionRequired() {
    return const HealthState(
      uiState: HealthUIState.androidPermissionRequired,
      authorizationStatus: HealthAuthorizationStatus.denied,
      installStatus: HealthConnectInstallStatus.installed,
      hasWorkoutData: null,
    );
  }

  /// Android workout empty state (no data, but all permissions OK)
  factory HealthState.androidWorkoutEmpty() {
    return const HealthState(
      uiState: HealthUIState.androidWorkoutEmpty,
      authorizationStatus: HealthAuthorizationStatus.granted,
      installStatus: HealthConnectInstallStatus.installed,
      hasWorkoutData: false,
    );
  }

  /// Workout loaded successfully state
  factory HealthState.workoutLoaded({
    required HealthAuthorizationStatus authStatus,
    HealthConnectInstallStatus? installStatus,
    required int workoutCount,
  }) {
    return HealthState(
      uiState: HealthUIState.workoutLoaded,
      authorizationStatus: authStatus,
      installStatus: installStatus,
      hasWorkoutData: true,
      workoutCount: workoutCount,
    );
  }

  /// Error state
  factory HealthState.error({
    required String message,
    required HealthAuthorizationStatus authStatus,
    HealthConnectInstallStatus? installStatus,
  }) {
    return HealthState(
      uiState: HealthUIState.error,
      authorizationStatus: authStatus,
      installStatus: installStatus,
      hasWorkoutData: null,
      errorMessage: message,
    );
  }

  /// Copy with method for state updates
  HealthState copyWith({
    HealthUIState? uiState,
    HealthAuthorizationStatus? authorizationStatus,
    HealthConnectInstallStatus? installStatus,
    bool? hasWorkoutData,
    String? errorMessage,
    int? workoutCount,
  }) {
    return HealthState(
      uiState: uiState ?? this.uiState,
      authorizationStatus: authorizationStatus ?? this.authorizationStatus,
      installStatus: installStatus ?? this.installStatus,
      hasWorkoutData: hasWorkoutData ?? this.hasWorkoutData,
      errorMessage: errorMessage ?? this.errorMessage,
      workoutCount: workoutCount ?? this.workoutCount,
    );
  }

  /// Whether this state represents a loading operation
  bool get isLoading => uiState == HealthUIState.loading;

  /// Whether this state represents an error
  bool get isError => uiState == HealthUIState.error;

  /// Whether workout data is currently displayed
  bool get isShowingWorkouts => uiState == HealthUIState.workoutLoaded;

  /// Whether permission action is required (any platform)
  bool get isPermissionRequired =>
      uiState == HealthUIState.iosPermissionRequired ||
      uiState == HealthUIState.androidPermissionRequired ||
      uiState == HealthUIState.androidHCNotInstalled;

  @override
  List<Object?> get props => [
        uiState,
        authorizationStatus,
        installStatus,
        hasWorkoutData,
        errorMessage,
        workoutCount,
      ];

  @override
  String toString() {
    return 'HealthState('
        'uiState: $uiState, '
        'authStatus: $authorizationStatus, '
        'installStatus: $installStatus, '
        'hasData: $hasWorkoutData, '
        'workoutCount: $workoutCount, '
        'error: $errorMessage'
        ')';
  }
}

/// State persistence for background-to-foreground comparison
///
/// Stores the previous health state to determine if a refresh is needed
/// when the app returns from background.
class HealthStatePersistence {
  /// Previous authorization status
  HealthAuthorizationStatus? previousAuthorizationStatus;

  /// Previous installation status (Android only)
  HealthConnectInstallStatus? previousInstallStatus;

  /// Whether we have any previous state stored
  bool get hasPreviousState => previousAuthorizationStatus != null;

  /// Update stored state
  void updateState({
    required HealthAuthorizationStatus authorizationStatus,
    HealthConnectInstallStatus? installStatus,
  }) {
    previousAuthorizationStatus = authorizationStatus;
    previousInstallStatus = installStatus;
  }

  /// Check if state has changed since last time
  bool hasStateChanged({
    required HealthAuthorizationStatus currentAuthStatus,
    HealthConnectInstallStatus? currentInstallStatus,
  }) {
    // No previous state means this is first check - always refresh
    if (!hasPreviousState) {
      return true;
    }

    // Check authorization status change
    if (previousAuthorizationStatus != currentAuthStatus) {
      return true;
    }

    // Check installation status change (Android only)
    if (currentInstallStatus != null &&
        previousInstallStatus != currentInstallStatus) {
      return true;
    }

    // No changes detected
    return false;
  }

  /// Clear stored state
  void clear() {
    previousAuthorizationStatus = null;
    previousInstallStatus = null;
  }
}
