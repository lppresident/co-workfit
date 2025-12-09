/// Use Case: Fetch Workout Data
///
/// Fetches workout data for a specified date range.

import 'package:dartz/dartz.dart';
import '../entities/workout_entity.dart';
import '../repositories/health_repository.dart';

class FetchWorkoutData {
  final HealthRepository _repository;

  FetchWorkoutData(this._repository);

  /// Execute the use case
  ///
  /// Returns Either<String, List<WorkoutEntity>>
  /// - Left: Error message
  /// - Right: List of workout entities (may be empty)
  Future<Either<String, List<WorkoutEntity>>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _repository.fetchWorkoutData(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
