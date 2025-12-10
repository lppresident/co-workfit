import 'package:co_workfit/features/auth/data/models/user_model.dart';

/// Abstract interface for the remote data source for profile-related data.
abstract class ProfileRemoteDataSource {
  /// Fetches the current user's profile data from the remote source.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<UserModel> getProfileData();

  /// Updates the user's display name on the remote source.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<void> updateDisplayName(String newDisplayName);

  /// Logs the current user out from the remote source.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<void> logout();
}
