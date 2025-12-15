/// Health Repository Implementation
///
/// Implements platform-specific health data operations for iOS (HealthKit)
/// and Android (Health Connect).

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../domain/entities/health_state.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/repositories/health_repository.dart';
import '../datasources/health_kit_datasource.dart';
import '../datasources/health_connect_datasource.dart';
import '../datasources/health_data_mapper.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// Health Repository Implementation
class HealthRepositoryImpl implements HealthRepository {
  final HealthKitDataSource _healthKitDataSource;
  final HealthConnectDataSource _healthConnectDataSource;
  final HealthDataMapper _healthDataMapper;
  final String _userId;

  HealthRepositoryImpl({
    required HealthKitDataSource healthKitDataSource,
    required HealthConnectDataSource healthConnectDataSource,
    required HealthDataMapper healthDataMapper,
    String userId = 'current_user',
  })  : _healthKitDataSource = healthKitDataSource,
        _healthConnectDataSource = healthConnectDataSource,
        _healthDataMapper = healthDataMapper,
        _userId = userId;

  bool get _isIOS => Platform.isIOS;
  bool get _isAndroid => Platform.isAndroid;

  // ========================================================================
  // Permission Management
  // ========================================================================

  @override
  Future<Either<String, HealthAuthorizationStatus>>
      checkHealthPermission() async {
    try {
      if (_isIOS) {
        return await _checkIOSPermission();
      } else if (_isAndroid) {
        return await _checkAndroidPermission();
      } else {
        return Left('Unsupported platform');
      }
    } catch (e) {
      return Left('Error checking permission: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, bool>> requestHealthPermission() async {
    try {
      if (_isIOS) {
        AppLogger.info('HealthRepo', 'iOS - Requesting HealthKit permission');
        return await _healthKitDataSource.requestAuthorization();
      } else if (_isAndroid) {
        AppLogger.info('HealthRepo', 'Android - Requesting Health Connect permission');
        return await _healthConnectDataSource.requestAuthorization();
      } else {
        return Left('Unsupported platform');
      }
    } catch (e) {
      return Left('Error requesting permission: ${e.toString()}');
    }
  }

  // ========================================================================
  // Data Fetching
  // ========================================================================

  @override
  Future<Either<String, List<WorkoutEntity>>> fetchWorkoutData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (_isIOS) {
        return await _fetchIOSWorkoutData(startDate, endDate);
      } else if (_isAndroid) {
        return await _fetchAndroidWorkoutData(startDate, endDate);
      } else {
        return Left('Unsupported platform');
      }
    } catch (e) {
      return Left('Error fetching workout data: ${e.toString()}');
    }
  }

  // ========================================================================
  // Android-Specific (Health Connect)
  // ========================================================================

  @override
  Future<Either<String, bool>> checkHealthConnectInstallation() async {
    if (!_isAndroid) {
      // On iOS, always return true (not applicable)
      return const Right(true);
    }

    try {
      final isInstalled =
          await _healthConnectDataSource.isHealthConnectInstalled();
      AppLogger.info('HealthRepo', 'Health Connect installed: $isInstalled');
      return Right(isInstalled);
    } catch (e) {
      return Left('Error checking Health Connect installation: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> openHealthConnectStore() async {
    if (!_isAndroid) {
      return Left('Health Connect is only available on Android');
    }

    try {
      await _healthConnectDataSource.installHealthConnect();
      return const Right(null);
    } catch (e) {
      return Left('Error opening Health Connect store: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> openHealthConnectSettings() async {
    if (!_isAndroid) {
      return Left('Health Connect is only available on Android');
    }

    try {
      await _healthConnectDataSource.openHealthConnectSettings();
      return const Right(null);
    } catch (e) {
      return Left('Error opening Health Connect settings: ${e.toString()}');
    }
  }

  // ========================================================================
  // iOS-Specific (HealthKit)
  // ========================================================================

  @override
  Future<Either<String, void>> openIOSHealthApp() async {
    if (!_isIOS) {
      return Left('Health app is only available on iOS');
    }

    try {
      // Open Health app using URL scheme
      // Note: This requires url_launcher package and proper Info.plist configuration
      // For now, return success - implementation can be added later
      return const Right(null);
    } catch (e) {
      return Left('Error opening Health app: ${e.toString()}');
    }
  }

  // ========================================================================
  // Private Helper Methods
  // ========================================================================

  /// Check iOS HealthKit permission status
  Future<Either<String, HealthAuthorizationStatus>>
      _checkIOSPermission() async {
    try {
      // Check if HealthKit is available
      final isAvailable = await _healthKitDataSource.isHealthKitAvailable();
      if (!isAvailable) {
        return const Right(HealthAuthorizationStatus.unknown);
      }

      // For iOS, we try to infer permission status by checking data access
      // Note: HealthKit doesn't provide explicit permission status check
      // We assume:
      // - If we've never requested -> notDetermined
      // - If we can access data -> granted
      // - Otherwise -> unknown (iOS privacy policy prevents explicit check)

      // For now, we'll use a heuristic: try to fetch a small amount of data
      final testResult = await _healthKitDataSource.fetchWorkoutData(
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now(),
      );

      return testResult.fold(
        (error) {
          // If error contains permission-related keywords
          if (error.contains('permission') ||
              error.contains('authorization')) {
            return const Right(HealthAuthorizationStatus.denied);
          }
          return const Right(HealthAuthorizationStatus.unknown);
        },
        (data) {
          // Successfully accessed data (even if empty) -> permission granted
          return const Right(HealthAuthorizationStatus.granted);
        },
      );
    } catch (e) {
      return Left('Error checking iOS permission: ${e.toString()}');
    }
  }

  /// Check Android Health Connect permission status
  Future<Either<String, HealthAuthorizationStatus>>
      _checkAndroidPermission() async {
    try {
      // First check if Health Connect is installed
      final isInstalled =
          await _healthConnectDataSource.isHealthConnectInstalled();
      if (!isInstalled) {
        return const Right(HealthAuthorizationStatus.unknown);
      }

      // Check if Health Connect is available (has permissions)
      final isAvailable =
          await _healthConnectDataSource.isHealthConnectAvailable();

      if (isAvailable) {
        return const Right(HealthAuthorizationStatus.granted);
      } else {
        return const Right(HealthAuthorizationStatus.denied);
      }
    } catch (e) {
      return Left('Error checking Android permission: ${e.toString()}');
    }
  }

  /// Fetch iOS workout data
  Future<Either<String, List<WorkoutEntity>>> _fetchIOSWorkoutData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    AppLogger.debug('HealthRepo', 'Fetching iOS workout data: $startDate to $endDate');

    final result = await _healthKitDataSource.fetchWorkoutData(
      startDate: startDate,
      endDate: endDate,
    );

    return result.fold(
      (error) {
        AppLogger.error('HealthRepo', 'iOS fetch error: $error');
        return Left(error);
      },
      (healthDataPoints) async {
        AppLogger.info('HealthRepo', 'iOS fetched ${healthDataPoints.length} data points');

        if (healthDataPoints.isEmpty) {
          return const Right([]);
        }

        // Convert health data points to workout entities
        final workouts = await _healthDataMapper.toWorkoutEntities(
          healthPoints: healthDataPoints,
          detailsFetcher: (start, end) async {
            final result = await _healthKitDataSource.fetchWorkoutDetails(
              workoutStart: start,
              workoutEnd: end,
            );
            return result.fold(
              (error) => <String, dynamic>{}, // Return empty map on error
              (details) => details,
            );
          },
          userId: _userId,
        );

        AppLogger.info('HealthRepo', 'Converted to ${workouts.length} workout entities');
        return Right(workouts);
      },
    );
  }

  /// Fetch Android workout data
  Future<Either<String, List<WorkoutEntity>>> _fetchAndroidWorkoutData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    AppLogger.debug('HealthRepo', 'Fetching Android workout data: $startDate to $endDate');

    final result = await _healthConnectDataSource.fetchWorkoutDataWithSource(
      startDate: startDate,
      endDate: endDate,
    );

    return result.fold(
      (error) {
        AppLogger.error('HealthRepo', 'Android fetch error: $error');
        return Left(error);
      },
      (healthDataPoints) async {
        AppLogger.info('HealthRepo', 'Android fetched ${healthDataPoints.length} data points');

        if (healthDataPoints.isEmpty) {
          return const Right([]);
        }

        // Convert health data points to workout entities with auto source detection
        final workouts =
            await _healthDataMapper.toWorkoutEntitiesWithAutoSource(
          healthPointsWithSource: healthDataPoints,
          detailsFetcher: (start, end) async {
            final result = await _healthConnectDataSource.fetchWorkoutDetails(
              workoutStart: start,
              workoutEnd: end,
            );
            return result.fold(
              (error) => <String, dynamic>{}, // Return empty map on error
              (details) => details,
            );
          },
          userId: _userId,
        );

        AppLogger.info('HealthRepo', 'Converted to ${workouts.length} workout entities');
        return Right(workouts);
      },
    );
  }
}
