/// Use Case: Check Health Permission Status
///
/// Queries the current health data authorization status without
/// requesting new permissions.

import 'package:dartz/dartz.dart';
import '../entities/health_state.dart';
import '../repositories/health_repository.dart';

class CheckHealthPermission {
  final HealthRepository _repository;

  CheckHealthPermission(this._repository);

  /// Execute the use case
  ///
  /// Returns Either<String, HealthAuthorizationStatus>
  /// - Left: Error message
  /// - Right: Current authorization status
  Future<Either<String, HealthAuthorizationStatus>> call() async {
    return await _repository.checkHealthPermission();
  }
}
