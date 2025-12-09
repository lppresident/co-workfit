/// Use Case: Check Health Connect Installation (Android only)
///
/// Checks whether the Health Connect app is installed on the device.

import 'package:dartz/dartz.dart';
import '../repositories/health_repository.dart';

class CheckHealthConnectInstallation {
  final HealthRepository _repository;

  CheckHealthConnectInstallation(this._repository);

  /// Execute the use case
  ///
  /// Returns Either<String, bool>
  /// - Left: Error message
  /// - Right: true if Health Connect is installed, false otherwise
  Future<Either<String, bool>> call() async {
    return await _repository.checkHealthConnectInstallation();
  }
}
