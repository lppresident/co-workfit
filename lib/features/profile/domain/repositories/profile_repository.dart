import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:dartz/dartz.dart';

/// The repository for handling profile-related data operations.
abstract class ProfileRepository {
  /// Fetches the current user's profile data.
  Future<Either<Failure, UserEntity>> getProfileData();

  /// Updates the user's display name.
  Future<Either<Failure, void>> updateDisplayName(String newDisplayName);

  /// Logs the current user out.
  Future<Either<Failure, void>> logout();
}
