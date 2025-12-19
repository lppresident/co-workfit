import 'package:get_it/get_it.dart';

// Firebase & Google Sign-In
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Workout
import 'package:co_workfit/features/workout/data/datasources/health_kit_datasource.dart';
import 'package:co_workfit/features/workout/data/datasources/health_connect_datasource.dart';
import 'package:co_workfit/features/workout/data/datasources/health_data_mapper.dart';
import 'package:co_workfit/features/workout/data/datasources/garmin/garmin_datasource.dart';
import 'package:co_workfit/features/workout/data/datasources/garmin/garmin_auth_service.dart';
import 'package:co_workfit/features/workout/data/datasources/garmin/garmin_api_client.dart';
import 'package:co_workfit/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';
import 'package:co_workfit/features/workout/domain/usecases/get_workouts.dart';
import 'package:co_workfit/features/workout/domain/usecases/request_health_permission.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';

// Auth
import 'package:co_workfit/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:co_workfit/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:co_workfit/features/auth/domain/repositories/auth_repository.dart';
import 'package:co_workfit/features/auth/domain/usecases/get_current_user.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_out.dart';
import 'package:co_workfit/features/auth/domain/usecases/check_nickname_availability.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';

// Profile
import 'package:co_workfit/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:co_workfit/features/profile/data/datasources/profile_remote_data_source_impl.dart';
import 'package:co_workfit/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:co_workfit/features/profile/domain/repositories/profile_repository.dart';
import 'package:co_workfit/features/profile/domain/usecases/get_profile_data.dart';
import 'package:co_workfit/features/profile/domain/usecases/logout_user.dart';
import 'package:co_workfit/features/profile/domain/usecases/update_display_name.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_bloc.dart';

// Social
import 'package:co_workfit/features/social/data/datasources/firestore_social_datasource.dart';
import 'package:co_workfit/features/social/data/repositories/social_repository_impl.dart';
import 'package:co_workfit/features/social/domain/repositories/social_repository.dart';
import 'package:co_workfit/features/social/domain/usecases/get_friends.dart';
import 'package:co_workfit/features/social/domain/usecases/get_friends_data.dart';
import 'package:co_workfit/features/social/domain/usecases/send_friend_request.dart';
import 'package:co_workfit/features/social/domain/usecases/get_received_friend_requests.dart';
import 'package:co_workfit/features/social/domain/usecases/accept_friend_request.dart';
import 'package:co_workfit/features/social/domain/usecases/reject_friend_request.dart';
import 'package:co_workfit/features/social/domain/usecases/search_users_by_nickname.dart';
import 'package:co_workfit/features/social/domain/usecases/get_leaderboard.dart';
import 'package:co_workfit/features/social/domain/usecases/get_friends_leaderboard.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_bloc.dart';

// Log Run
import 'package:co_workfit/features/log_run/data/datasources/firestore_log_run_datasource.dart';
import 'package:co_workfit/features/log_run/data/repositories/log_run_repository_impl.dart';
import 'package:co_workfit/features/log_run/domain/repositories/log_run_repository.dart';
import 'package:co_workfit/features/log_run/domain/usecases/create_log_run_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/join_log_run_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/join_challenge_by_invite_code.dart';
import 'package:co_workfit/features/log_run/domain/usecases/submit_workout_to_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/get_active_challenges.dart';
import 'package:co_workfit/features/log_run/domain/usecases/get_challenge_contributions.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_bloc.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // ========== Data Sources ==========

  // iOS - HealthKit
  sl.registerLazySingleton<HealthKitDataSource>(
    () => HealthKitDataSource(),
  );

  // Android - Health Connect (Samsung Health, Google Fit 등 통합)
  sl.registerLazySingleton<HealthConnectDataSource>(
    () => HealthConnectDataSource(),
  );

  // Garmin - iOS/Android 공통
  sl.registerLazySingleton<GarminAuthService>(
    () => GarminAuthService(),
  );

  sl.registerLazySingleton<GarminApiClient>(
    () => GarminApiClient(authService: sl()),
  );

  sl.registerLazySingleton<GarminDataSource>(
    () => GarminDataSource(
      authService: sl(),
      apiClient: sl(),
    ),
  );

  // Mapper
  sl.registerLazySingleton<HealthDataMapper>(
    () => HealthDataMapper(),
  );

  // ========== Repository ==========
  sl.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepositoryImpl(
      healthKitDataSource: sl(),
      healthConnectDataSource: sl(),
      garminDataSource: sl(),
      healthDataMapper: sl(),
    ),
  );

  // ========== Use Cases ==========
  sl.registerLazySingleton(() => RequestHealthPermission(sl()));
  sl.registerLazySingleton(() => GetWorkouts(sl()));
  sl.registerLazySingleton(() => GetTodayWorkouts(sl()));
  sl.registerLazySingleton(() => GetRecentWorkouts(sl()));

  // ========== BLoC ==========
  sl.registerFactory(
    () => WorkoutBloc(
      requestHealthPermission: sl(),
      getTodayWorkouts: sl(),
      getRecentWorkouts: sl(),
      getWorkouts: sl(),
    ),
  );

  // ========== Auth Feature ==========

  // Data Sources
  sl.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSource(),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignInWithApple(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => CheckNicknameAvailability(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      signInWithGoogle: sl(),
      signInWithApple: sl(),
      signOut: sl(),
      checkNicknameAvailability: sl(),
      authRepository: sl(),
    ),
  );

  // ========== Firebase & GoogleSignIn Instances (Core) ==========
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());


  // ========== Profile Feature ==========

  // Data Sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      googleSignIn: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetProfileData(sl()));
  sl.registerLazySingleton(() => UpdateDisplayName(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));

  // BLoC
  sl.registerFactory(
    () => ProfileBloc(
      getProfileData: sl(),
      updateDisplayName: sl(),
      logoutUser: sl(),
    ),
  );


  // ========== Social Feature ==========

  // Data Sources
  sl.registerLazySingleton<FirestoreSocialDataSource>(
    () => FirestoreSocialDataSource(),
  );

  // Repository
  sl.registerLazySingleton<SocialRepository>(
    () => SocialRepositoryImpl(sl()),
  );

  // Use Cases - Friends
  sl.registerLazySingleton(() => GetFriends(sl()));
  sl.registerLazySingleton(() => GetFriendsData(sl()));
  sl.registerLazySingleton(() => SendFriendRequest(sl()));
  sl.registerLazySingleton(() => GetReceivedFriendRequests(sl()));
  sl.registerLazySingleton(() => AcceptFriendRequest(sl()));
  sl.registerLazySingleton(() => RejectFriendRequest(sl()));
  sl.registerLazySingleton(() => SearchUsersByNickname(sl()));

  // Use Cases - Leaderboard
  sl.registerLazySingleton(() => GetLeaderboard(sl()));
  sl.registerLazySingleton(() => GetFriendsLeaderboard(sl()));

  // BLoC
  sl.registerFactory(
    () => SocialBloc(
      getFriends: sl(),
      getFriendsData: sl(),
      sendFriendRequest: sl(),
      getReceivedFriendRequests: sl(),
      acceptFriendRequest: sl(),
      rejectFriendRequest: sl(),
      searchUsersByNickname: sl(),
    ),
  );

  sl.registerFactory(
    () => LeaderboardBloc(
      getLeaderboard: sl(),
      getFriendsLeaderboard: sl(),
    ),
  );

  // ========== Log Run Feature ==========

  // Data Sources
  sl.registerLazySingleton<FirestoreLogRunDataSource>(
    () => FirestoreLogRunDataSource(firestore: sl()),
  );

  // Repository
  sl.registerLazySingleton<LogRunRepository>(
    () => LogRunRepositoryImpl(dataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateLogRunChallenge(sl()));
  sl.registerLazySingleton(() => JoinLogRunChallenge(sl()));
  sl.registerLazySingleton(() => JoinChallengeByInviteCode(sl()));
  sl.registerLazySingleton(() => SubmitWorkoutToChallenge(sl()));
  sl.registerLazySingleton(() => GetActiveChallenges(sl()));
  sl.registerLazySingleton(() => GetChallengeContributions(sl()));

  // BLoC
  sl.registerFactory(
    () => LogRunBloc(
      createChallengeUseCase: sl(),
      joinChallengeUseCase: sl(),
      joinChallengeByCodeUseCase: sl(),
      submitWorkoutUseCase: sl(),
      getActiveChallengesUseCase: sl(),
      getChallengeContributionsUseCase: sl(),
      repository: sl(),
    ),
  );
}
