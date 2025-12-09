/// Events for the Health BLoC state machine
///
/// These events trigger state transitions in the health permission
/// and data loading flow.

import 'package:equatable/equatable.dart';

/// Base class for all health events
abstract class HealthEvent extends Equatable {
  const HealthEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Initialize health state
///
/// Triggered on app launch to begin the permission check → data load flow.
/// This is the entry point for the entire state machine.
class HealthInitializeEvent extends HealthEvent {
  const HealthInitializeEvent();
}

/// Event: Check current health permission status
///
/// Queries the current authorization status without requesting permission.
/// Used as the first step in the flow.
class HealthCheckPermissionEvent extends HealthEvent {
  const HealthCheckPermissionEvent();
}

/// Event: Request health permission
///
/// Explicitly requests health data access permission from the user.
/// On iOS, this shows the HealthKit permission dialog.
/// On Android, this shows the Health Connect permission screen.
class HealthRequestPermissionEvent extends HealthEvent {
  const HealthRequestPermissionEvent();
}

/// Event: Fetch workout data
///
/// Loads workout data for a specified date range.
/// Should only be called after permission checks are complete.
class HealthFetchWorkoutDataEvent extends HealthEvent {
  /// Start date for data fetch
  final DateTime startDate;

  /// End date for data fetch
  final DateTime endDate;

  const HealthFetchWorkoutDataEvent({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Event: Refresh all health data
///
/// Triggered by refresh button or pull-to-refresh.
/// Re-runs the complete flow: permission check → data load
/// Ignores previous state comparison.
class HealthRefreshEvent extends HealthEvent {
  /// Number of days to load (default: 7)
  final int days;

  const HealthRefreshEvent({this.days = 7});

  @override
  List<Object?> get props => [days];
}

/// Event: App returned from background
///
/// Triggered when app lifecycle changes from background to foreground.
/// Compares previous state with current state to decide if refresh is needed.
class HealthAppResumedEvent extends HealthEvent {
  const HealthAppResumedEvent();
}

/// Event: Install Health Connect (Android only)
///
/// Opens the Play Store to install Health Connect app.
class HealthInstallHealthConnectEvent extends HealthEvent {
  const HealthInstallHealthConnectEvent();
}

/// Event: Open Health Connect settings (Android only)
///
/// Opens the Health Connect app settings for permission management.
class HealthOpenSettingsEvent extends HealthEvent {
  const HealthOpenSettingsEvent();
}

/// Event: Open iOS Health app settings
///
/// Opens the Health app on iOS for the user to manage permissions.
class HealthOpenIOSHealthAppEvent extends HealthEvent {
  const HealthOpenIOSHealthAppEvent();
}

/// Event: Clear error state
///
/// Resets error state, typically triggered after user acknowledges error.
class HealthClearErrorEvent extends HealthEvent {
  const HealthClearErrorEvent();
}
