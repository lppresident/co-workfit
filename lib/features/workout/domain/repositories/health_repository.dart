/// Health Repository Interface
///
/// Defines the contract for health data operations across platforms.
/// Implementations handle platform-specific details for iOS (HealthKit)
/// and Android (Health Connect).

import 'package:dartz/dartz.dart';
import '../entities/health_state.dart';
import '../entities/workout_entity.dart';

abstract class HealthRepository {
  // ========================================================================
  // Permission Management
  // ========================================================================

  /// Check current health data authorization status
  ///
  /// Returns Either<String, HealthAuthorizationStatus>
  /// - Left: Error message
  /// - Right: Current authorization status
  Future<Either<String, HealthAuthorizationStatus>> checkHealthPermission();

  /// Request health data access permission
  ///
  /// Shows platform-specific permission dialog:
  /// - iOS: HealthKit permission dialog
  /// - Android: Health Connect permission screen
  ///
  /// Returns Either<String, bool>
  /// - Left: Error message
  /// - Right: true if any permissions granted, false otherwise
  Future<Either<String, bool>> requestHealthPermission();

  // ========================================================================
  // Data Fetching
  // ========================================================================

  /// Fetch workout data for a date range
  ///
  /// Returns Either<String, List<WorkoutEntity>>
  /// - Left: Error message
  /// - Right: List of workouts (may be empty)
  Future<Either<String, List<WorkoutEntity>>> fetchWorkoutData({
    required DateTime startDate,
    required DateTime endDate,
  });

  // ========================================================================
  // Android-Specific (Health Connect)
  // ========================================================================

  /// Check if Health Connect app is installed (Android only)
  ///
  /// Returns Either<String, bool>
  /// - Left: Error message
  /// - Right: true if installed, false otherwise
  ///
  /// On iOS, this always returns Right(true)
  Future<Either<String, bool>> checkHealthConnectInstallation();

  /// Open Health Connect app in Play Store (Android only)
  ///
  /// Returns Either<String, void>
  /// - Left: Error message
  /// - Right: Success (void)
  Future<Either<String, void>> openHealthConnectStore();

  /// Open Health Connect settings (Android only)
  ///
  /// Returns Either<String, void>
  /// - Left: Error message
  /// - Right: Success (void)
  Future<Either<String, void>> openHealthConnectSettings();

  // ========================================================================
  // iOS-Specific (HealthKit)
  // ========================================================================

  /// Open iOS Health app (iOS only)
  ///
  /// Returns Either<String, void>
  /// - Left: Error message
  /// - Right: Success (void)
  Future<Either<String, void>> openIOSHealthApp();
}
