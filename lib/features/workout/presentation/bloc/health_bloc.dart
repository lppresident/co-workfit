/// Health BLoC - State Machine for iOS/Android Health Data
///
/// This BLoC implements the complete state machine for managing health
/// permissions and data across iOS (HealthKit) and Android (Health Connect).
///
/// Key responsibilities:
/// - Permission checking and requesting
/// - Workout data fetching
/// - Background-to-foreground state comparison
/// - Platform-specific flow handling

import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/health_state.dart';
import '../../domain/entities/health_event.dart';
import '../../domain/usecases/check_health_permission.dart';
import '../../domain/usecases/request_health_permission.dart';
import '../../domain/usecases/fetch_workout_data.dart';
import '../../domain/usecases/check_health_connect_installation.dart';
import 'health_bloc_state.dart';

/// Health BLoC
///
/// Manages the state machine for health permission and data operations.
class HealthBloc extends Bloc<HealthEvent, HealthBlocState> {
  /// Use case: Check current health permission status
  final CheckHealthPermission _checkHealthPermission;

  /// Use case: Request health permission
  final RequestHealthPermission _requestHealthPermission;

  /// Use case: Fetch workout data
  final FetchWorkoutData _fetchWorkoutData;

  /// Use case: Check Health Connect installation (Android only)
  final CheckHealthConnectInstallation _checkHealthConnectInstallation;

  /// State persistence for background-to-foreground comparison
  final HealthStatePersistence _statePersistence = HealthStatePersistence();

  HealthBloc({
    required CheckHealthPermission checkHealthPermission,
    required RequestHealthPermission requestHealthPermission,
    required FetchWorkoutData fetchWorkoutData,
    required CheckHealthConnectInstallation checkHealthConnectInstallation,
  })  : _checkHealthPermission = checkHealthPermission,
        _requestHealthPermission = requestHealthPermission,
        _fetchWorkoutData = fetchWorkoutData,
        _checkHealthConnectInstallation = checkHealthConnectInstallation,
        super(HealthBlocInitial()) {
    // Register event handlers
    on<HealthInitializeEvent>(_onInitialize);
    on<HealthCheckPermissionEvent>(_onCheckPermission);
    on<HealthRequestPermissionEvent>(_onRequestPermission);
    on<HealthFetchWorkoutDataEvent>(_onFetchWorkoutData);
    on<HealthRefreshEvent>(_onRefresh);
    on<HealthAppResumedEvent>(_onAppResumed);
    on<HealthInstallHealthConnectEvent>(_onInstallHealthConnect);
    on<HealthOpenSettingsEvent>(_onOpenSettings);
    on<HealthOpenIOSHealthAppEvent>(_onOpenIOSHealthApp);
    on<HealthClearErrorEvent>(_onClearError);
  }

  /// Handle initialization event
  ///
  /// Entry point for the state machine. Determines platform and starts
  /// the appropriate flow.
  Future<void> _onInitialize(
    HealthInitializeEvent event,
    Emitter<HealthBlocState> emit,
  ) async {
    emit(HealthBlocLoading());

    if (Platform.isIOS) {
      await _runIOSFlow(emit, days: 7);
    } else if (Platform.isAndroid) {
      await _runAndroidFlow(emit, days: 7);
    } else {
      emit(HealthBlocError(
        message: 'Unsupported platform',
        authStatus: HealthAuthorizationStatus.unknown,
      ));
    }
  }

  /// Handle permission check event
  Future<void> _onCheckPermission(
    HealthCheckPermissionEvent event,
    Emitter<HealthBlocState> emit,
  ) async {
    emit(HealthBlocLoading());

    if (Platform.isIOS) {
      await _runIOSFlow(emit, days: 7);
    } else if (Platform.isAndroid) {
      await _runAndroidFlow(emit, days: 7);
    }
  }

  /// Handle permission request event
  Future<void> _onRequestPermission(
    HealthRequestPermissionEvent event,
    Emitter<HealthBlocState> emit,
  ) async {
    emit(HealthBlocLoading());

    final result = await _requestHealthPermission();

    result.fold(
      (error) {
        emit(HealthBlocError(
          message: error,
          authStatus: HealthAuthorizationStatus.denied,
        ));
      },
      (granted) async {
        // After permission request, re-run the full flow
        if (Platform.isIOS) {
          await _runIOSFlow(emit, days: 7);
        } else if (Platform.isAndroid) {
          await _runAndroidFlow(emit, days: 7);
        }
      },
    );
  }

  /// Handle fetch workout data event
  Future<void> _onFetchWorkoutData(
    HealthFetchWorkoutDataEvent event,
    Emitter<HealthBlocState> emit,
  ) async {
    emit(HealthBlocLoading());

    final result = await _fetchWorkoutData(
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      (error) {
        emit(HealthBlocError(
          message: error,
          authStatus: HealthAuthorizationStatus.unknown,
        ));
      },
      (workouts) {
        if (workouts.isEmpty) {
          if (Platform.isIOS) {
            emit(HealthBlocIOSWorkoutEmpty(
              authStatus: HealthAuthorizationStatus.granted,
            ));
          } else {
            emit(HealthBlocAndroidWorkoutEmpty());
          }
        } else {
          emit(HealthBlocWorkoutLoaded(
            authStatus: HealthAuthorizationStatus.granted,
            installStatus: Platform.isAndroid
                ? HealthConnectInstallStatus.installed
                : null,
            workouts: workouts,
          ));
        }
      },
    );
  }

  /// Handle refresh event
  ///
  /// Refresh button always re-runs full flow, ignoring state comparison
  Future<void> _onRefresh(
    HealthRefreshEvent event,
    Emitter<HealthBlocState> emit,
  ) async {
    emit(HealthBlocLoading());

    if (Platform.isIOS) {
      await _runIOSFlow(emit, days: event.days);
    } else if (Platform.isAndroid) {
      await _runAndroidFlow(emit, days: event.days);
    }
  }

  /// Handle app resumed event (background → foreground)
  ///
  /// Compares previous state with current state to determine if refresh needed
  Future<void> _onAppResumed(
    HealthAppResumedEvent event,
    Emitter<HealthBlocState> emit,
  ) async {
    // Get current permission and installation status
    final currentAuthStatus = await _getCurrentAuthorizationStatus();
    final currentInstallStatus = Platform.isAndroid
        ? await _getCurrentInstallStatus()
        : null;

    // Check if state has changed
    final hasChanged = _statePersistence.hasStateChanged(
      currentAuthStatus: currentAuthStatus,
      currentInstallStatus: currentInstallStatus,
    );

    if (hasChanged) {
      // State changed - refresh data
      emit(HealthBlocLoading());

      if (Platform.isIOS) {
        await _runIOSFlow(emit, days: 7);
      } else if (Platform.isAndroid) {
        await _runAndroidFlow(emit, days: 7);
      }
    } else {
      // No change - maintain current state (prevent flicker)
      // Do nothing, keep current state
    }
  }

  /// Handle Health Connect installation event (Android only)
  Future<void> _onInstallHealthConnect(
    HealthInstallHealthConnectEvent event,
    Emitter<HealthBlocState> emit,
  ) async {
    // This will be implemented in the repository layer
    // to open Play Store
    // For now, keep current state
  }

  /// Handle open settings event
  Future<void> _onOpenSettings(
    HealthOpenSettingsEvent event,
    Emitter<HealthBlocState> emit,
  ) async {
    // This will be implemented in the repository layer
    // to open Health Connect settings
    // For now, keep current state
  }

  /// Handle open iOS Health app event
  Future<void> _onOpenIOSHealthApp(
    HealthOpenIOSHealthAppEvent event,
    Emitter<HealthBlocState> emit,
  ) async {
    // This will be implemented in the repository layer
    // to open iOS Health app
    // For now, keep current state
  }

  /// Handle clear error event
  Future<void> _onClearError(
    HealthClearErrorEvent event,
    Emitter<HealthBlocState> emit,
  ) async {
    emit(HealthBlocInitial());
  }

  // ========================================================================
  // iOS Flow
  // ========================================================================

  /// Run complete iOS (HealthKit) flow
  ///
  /// Flow: Check permission → Request if notDetermined → Fetch data
  ///       → Show permission UI if empty OR show workout list
  Future<void> _runIOSFlow(
    Emitter<HealthBlocState> emit, {
    required int days,
  }) async {
    // Step 1: Check current authorization status
    final authStatus = await _getCurrentAuthorizationStatus();

    // Step 2: If notDetermined, request permission
    if (authStatus == HealthAuthorizationStatus.notDetermined) {
      await _requestHealthPermission();

      // Continue regardless of request result (iOS policy)
      // The actual permission status will be reflected in the data fetch
    }

    // Step 3: Fetch workout data (regardless of permission request result)
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final fetchResult = await _fetchWorkoutData(
      startDate: startDate,
      endDate: endDate,
    );

    fetchResult.fold(
      (error) {
        // Fetch error
        emit(HealthBlocError(
          message: error,
          authStatus: authStatus,
        ));
      },
      (workouts) {
        if (workouts.isEmpty) {
          // Step 4a: Empty data
          // iOS cannot distinguish "no data" from "no permission"
          // Always show permission guidance UI
          emit(HealthBlocIOSWorkoutEmpty(
            authStatus: authStatus,
          ));
        } else {
          // Step 4b: Has data
          emit(HealthBlocWorkoutLoaded(
            authStatus: authStatus,
            installStatus: null,
            workouts: workouts,
          ));
        }

        // Update state persistence for BG→FG comparison
        _statePersistence.updateState(
          authorizationStatus: authStatus,
          installStatus: null,
        );
      },
    );
  }

  // ========================================================================
  // Android Flow
  // ========================================================================

  /// Run complete Android (Health Connect) flow
  ///
  /// Flow: Check HC installation → Check permissions → Fetch data
  ///       → Show appropriate UI based on conditions
  Future<void> _runAndroidFlow(
    Emitter<HealthBlocState> emit, {
    required int days,
  }) async {
    // Step 1: Check Health Connect installation
    final installResult = await _checkHealthConnectInstallation();

    late HealthConnectInstallStatus installStatus;

    installResult.fold(
      (error) {
        // Error checking installation - assume not installed
        installStatus = HealthConnectInstallStatus.notInstalled;
      },
      (isInstalled) {
        installStatus = isInstalled
            ? HealthConnectInstallStatus.installed
            : HealthConnectInstallStatus.notInstalled;
      },
    );

    // If not installed, show installation UI
    if (installStatus == HealthConnectInstallStatus.notInstalled) {
      emit(HealthBlocAndroidHCNotInstalled());

      // Update state persistence
      _statePersistence.updateState(
        authorizationStatus: HealthAuthorizationStatus.unknown,
        installStatus: installStatus,
      );

      return;
    }

    // Step 2: Check permissions
    final authStatus = await _getCurrentAuthorizationStatus();

    // If any permission denied, show permission UI
    if (authStatus == HealthAuthorizationStatus.denied ||
        authStatus == HealthAuthorizationStatus.notDetermined) {
      emit(HealthBlocAndroidPermissionRequired());

      // Update state persistence
      _statePersistence.updateState(
        authorizationStatus: authStatus,
        installStatus: installStatus,
      );

      return;
    }

    // Step 3: All conditions met - fetch workout data
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final fetchResult = await _fetchWorkoutData(
      startDate: startDate,
      endDate: endDate,
    );

    fetchResult.fold(
      (error) {
        // Fetch error
        emit(HealthBlocError(
          message: error,
          authStatus: authStatus,
          installStatus: installStatus,
        ));
      },
      (workouts) {
        if (workouts.isEmpty) {
          // Step 4a: Empty data (but all permissions OK)
          // Android can distinguish this from permission issues
          // Just show "no data" message
          emit(HealthBlocAndroidWorkoutEmpty());
        } else {
          // Step 4b: Has data
          emit(HealthBlocWorkoutLoaded(
            authStatus: authStatus,
            installStatus: installStatus,
            workouts: workouts,
          ));
        }

        // Update state persistence for BG→FG comparison
        _statePersistence.updateState(
          authorizationStatus: authStatus,
          installStatus: installStatus,
        );
      },
    );
  }

  // ========================================================================
  // Helper Methods
  // ========================================================================

  /// Get current authorization status
  Future<HealthAuthorizationStatus> _getCurrentAuthorizationStatus() async {
    final result = await _checkHealthPermission();

    return result.fold(
      (error) => HealthAuthorizationStatus.unknown,
      (status) => status,
    );
  }

  /// Get current Health Connect installation status (Android only)
  Future<HealthConnectInstallStatus> _getCurrentInstallStatus() async {
    final result = await _checkHealthConnectInstallation();

    return result.fold(
      (error) => HealthConnectInstallStatus.unknown,
      (isInstalled) => isInstalled
          ? HealthConnectInstallStatus.installed
          : HealthConnectInstallStatus.notInstalled,
    );
  }
}
