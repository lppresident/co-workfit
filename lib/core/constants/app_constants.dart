/// Application-wide constants
class AppConstants {
  AppConstants._();

  // Timeouts
  static const int defaultTimeoutSeconds = 10;
  static const int dataLoadTimeoutMs = 10000;
  static const int permissionCheckTimeoutMs = 10000;

  // Date/Time
  static const int defaultRecentDays = 7;
  static const int monthlyDays = 30;
  static const int weeklyDays = 7;

  // UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 2.0;

  // Leaderboard
  static const int goldRank = 1;
  static const int silverRank = 2;
  static const int bronzeRank = 3;
  static const int goldColor = 0xFFFFD700;
  static const int silverColor = 0xFFC0C0C0;
  static const int bronzeColor = 0xFFCD7F32;

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String friendRequestsCollection = 'friend_requests';
  static const String friendshipsCollection = 'friendships';
  static const String leaderboardCollection = 'leaderboard';

  // Friend Request Status
  static const String friendRequestPending = 'pending';
  static const String friendRequestAccepted = 'accepted';
  static const String friendRequestRejected = 'rejected';

  // Error Messages
  static const String firebaseNotInitializedError = 'Firebase not initialized';
  static const String permissionDeniedError = 'Permission denied';
  static const String healthConnectNotInstalledError = 'Health Connect not installed';
}
