/// Firebase 설정
///
/// Firebase Console에서 프로젝트를 생성한 후:
/// 1. iOS: GoogleService-Info.plist를 ios/Runner/에 추가
/// 2. Android: google-services.json을 android/app/에 추가
/// 3. FlutterFire CLI 사용: `flutterfire configure`
///
/// 참고: https://firebase.google.com/docs/flutter/setup

class FirebaseConfig {
  // Firebase 프로젝트 ID
  static const String projectId = 'co-workfit';

  // Firestore 컬렉션 이름
  static const String usersCollection = 'users';
  static const String nicknamesCollection = 'nicknames';
  static const String workoutsCollection = 'workouts';
  static const String friendsCollection = 'friends';
  static const String leaderboardCollection = 'leaderboard';
  static const String friendRequestsCollection = 'friend_requests';

  // Auth 설정
  static const bool enableEmailPasswordAuth = true;
  static const bool enableGoogleSignIn = true;
  static const bool enableAppleSignIn = true;

  // 기타 설정
  static const int leaderboardPageSize = 50;
  static const Duration cacheExpiration = Duration(hours: 1);
}
