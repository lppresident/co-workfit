import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:co_workfit/features/workout/data/datasources/firestore_workout_datasource.dart';
import 'package:co_workfit/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';
import 'package:co_workfit/features/workout/domain/usecases/get_workouts.dart';
import 'package:co_workfit/features/workout/domain/usecases/request_health_permission.dart';
import 'package:co_workfit/features/workout/domain/usecases/update_workout_distance.dart';
import 'package:co_workfit/features/workout/domain/usecases/reset_workout_distance.dart';
import 'package:co_workfit/features/workout/domain/usecases/sync_workouts_to_firestore.dart';
import 'package:co_workfit/features/workout/domain/usecases/get_merged_workouts.dart';
import 'package:co_workfit/features/workout/domain/usecases/get_workouts_from_firestore.dart';
import 'package:co_workfit/features/workout/domain/usecases/register_selected_workouts.dart';
import 'package:co_workfit/features/workout/domain/usecases/get_registered_workout_ids.dart';
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
import 'package:co_workfit/features/auth/presentation/bloc/nickname_bloc.dart';

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
import 'package:co_workfit/features/social/domain/usecases/get_sent_friend_requests.dart';
import 'package:co_workfit/features/social/domain/usecases/accept_friend_request.dart';
import 'package:co_workfit/features/social/domain/usecases/reject_friend_request.dart';
import 'package:co_workfit/features/social/domain/usecases/search_users_by_nickname.dart';
import 'package:co_workfit/features/social/domain/usecases/remove_friend.dart';
import 'package:co_workfit/features/social/domain/usecases/get_leaderboard.dart';
import 'package:co_workfit/features/social/domain/usecases/get_friends_leaderboard.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_bloc.dart';

// Log Run
import 'package:co_workfit/features/log_run/data/datasources/firestore_challenge_datasource.dart';
import 'package:co_workfit/features/log_run/data/repositories/challenge_repository_impl.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';
import 'package:co_workfit/features/log_run/domain/usecases/create_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/join_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/join_challenge_by_invite_code.dart';
import 'package:co_workfit/features/log_run/domain/usecases/submit_workout_to_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/get_active_challenges.dart';
import 'package:co_workfit/features/log_run/domain/usecases/get_challenge_contributions.dart';
import 'package:co_workfit/features/log_run/domain/usecases/delete_contribution.dart';
import 'package:co_workfit/features/log_run/domain/usecases/create_challenge_invites.dart' as invite_usecases;
import 'package:co_workfit/features/log_run/domain/usecases/get_my_invites.dart';
import 'package:co_workfit/features/log_run/domain/usecases/accept_invite.dart';
import 'package:co_workfit/features/log_run/domain/usecases/reject_invite.dart';
import 'package:co_workfit/features/log_run/domain/usecases/get_challenge_archives.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_bloc.dart';

// Currency (통합 재화 시스템)
import 'package:co_workfit/features/currency/currency.dart' as currency;

// Craft (아이템 제작 시스템)
import 'package:co_workfit/features/craft/craft.dart';

// Core Services
import 'package:co_workfit/core/services/app_lifecycle_service.dart';
import 'package:co_workfit/core/services/version_check_service.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // ========== Core Dependencies ==========

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

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

  // Firestore DataSource
  sl.registerLazySingleton(
    () => FirestoreWorkoutDataSource(
      firestore: FirebaseFirestore.instance,
    ),
  );

  // ========== Repository ==========
  sl.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepositoryImpl(
      healthKitDataSource: sl(),
      healthConnectDataSource: sl(),
      garminDataSource: sl(),
      healthDataMapper: sl(),
      firestoreDataSource: sl(),
      firebaseAuth: FirebaseAuth.instance,
    ),
  );

  // ========== Use Cases ==========
  sl.registerLazySingleton(() => RequestHealthPermission(sl()));
  sl.registerLazySingleton(() => GetWorkouts(sl()));
  sl.registerLazySingleton(() => GetTodayWorkouts(sl()));
  sl.registerLazySingleton(() => GetRecentWorkouts(sl()));
  sl.registerLazySingleton(() => UpdateWorkoutDistance(sl()));
  sl.registerLazySingleton(() => ResetWorkoutDistance(sl()));
  sl.registerLazySingleton(() => SyncWorkoutsToFirestore(sl()));
  sl.registerLazySingleton(() => GetMergedWorkouts(sl()));
  sl.registerLazySingleton(() => GetWorkoutsFromFirestore(sl()));
  sl.registerLazySingleton(() => RegisterSelectedWorkouts(sl()));
  sl.registerLazySingleton(() => GetRegisteredWorkoutIds(sl()));

  // ========== BLoC ==========
  sl.registerFactory(
    () => WorkoutBloc(
      requestHealthPermission: sl(),
      getTodayWorkouts: sl(),
      getRecentWorkouts: sl(),
      getWorkouts: sl(),
      updateWorkoutDistance: sl(),
      resetWorkoutDistance: sl(),
      syncWorkoutsToFirestore: sl(),
      getMergedWorkouts: sl(),
      getWorkoutsFromFirestore: sl(),
      registerSelectedWorkouts: sl(),
      getRegisteredWorkoutIds: sl(),
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
      authRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => NicknameBloc(
      checkNicknameAvailability: sl(),
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
  sl.registerLazySingleton(() => GetSentFriendRequests(sl()));
  sl.registerLazySingleton(() => AcceptFriendRequest(sl()));
  sl.registerLazySingleton(() => RejectFriendRequest(sl()));
  sl.registerLazySingleton(() => SearchUsersByNickname(sl()));
  sl.registerLazySingleton(() => RemoveFriend(sl()));

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
      getSentFriendRequests: sl(),
      acceptFriendRequest: sl(),
      rejectFriendRequest: sl(),
      searchUsersByNickname: sl(),
      removeFriend: sl(),
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
  sl.registerLazySingleton<FirestoreChallengeDataSource>(
    () => FirestoreChallengeDataSource(firestore: sl()),
  );

  // Repository
  sl.registerLazySingleton<ChallengeRepository>(
    () => ChallengeRepositoryImpl(dataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateChallenge(sl()));
  sl.registerLazySingleton(() => JoinChallenge(sl()));
  sl.registerLazySingleton(() => JoinChallengeByInviteCode(sl()));
  sl.registerLazySingleton(() => SubmitWorkoutToChallenge(sl()));
  sl.registerLazySingleton(() => GetAllChallenges(sl()));
  sl.registerLazySingleton(() => GetChallengeContributions(sl()));
  sl.registerLazySingleton(() => DeleteContribution(sl()));
  sl.registerLazySingleton(() => invite_usecases.CreateChallengeInvites(sl()));
  sl.registerLazySingleton(() => GetMyInvites(sl()));
  sl.registerLazySingleton(() => AcceptInvite(sl()));
  sl.registerLazySingleton(() => RejectInvite(sl()));
  sl.registerLazySingleton(() => GetChallengeArchives(sl()));

  // BLoC
  sl.registerFactory(
    () => ChallengeBloc(
      createChallengeUseCase: sl(),
      joinChallengeUseCase: sl(),
      joinChallengeByCodeUseCase: sl(),
      submitWorkoutUseCase: sl(),
      getAllChallengesUseCase: sl(),
      getChallengeContributionsUseCase: sl(),
      deleteContributionUseCase: sl(),
      createChallengeInvitesUseCase: sl(),
      getMyInvitesUseCase: sl(),
      acceptInviteUseCase: sl(),
      rejectInviteUseCase: sl(),
      getChallengeArchivesUseCase: sl(),
      repository: sl(),
    ),
  );

  // ========== Currency Feature (통합 재화 시스템) ==========

  // Data Sources
  sl.registerLazySingleton<currency.FirestoreCurrencyDataSource>(
    () => currency.FirestoreCurrencyDataSource(firestore: sl()),
  );

  // Repository
  sl.registerLazySingleton<currency.CurrencyRepository>(
    () => currency.CurrencyRepositoryImpl(dataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => const currency.RewardCalculator());
  sl.registerLazySingleton(
    () => currency.SettleDailyRewards(
      repository: sl(),
      calculator: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => currency.CheckPendingSettlements(
      currencyRepository: sl(),
      challengeRepository: sl(),
      settleDailyRewards: sl(),
    ),
  );

  // BLoC
  sl.registerFactory(
    () => currency.CurrencyBloc(
      repository: sl(),
      checkPendingSettlements: sl(),
    ),
  );

  // ========== Craft Feature (아이템 제작 시스템) ==========

  // Data Sources
  sl.registerLazySingleton<FirestoreCraftDataSource>(
    () => FirestoreCraftDataSource(firestore: sl()),
  );

  // Repository
  sl.registerLazySingleton<CraftRepository>(
    () => CraftRepositoryImpl(dataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetRecipes(sl()));
  sl.registerLazySingleton(() => GetInventory(sl()));
  sl.registerLazySingleton(() => GetEquippedItems(sl()));
  sl.registerLazySingleton(() => CraftItem(sl()));
  sl.registerLazySingleton(() => EquipItem(sl()));
  sl.registerLazySingleton(() => UnequipItem(sl()));

  // BLoC
  sl.registerFactory(
    () => CraftBloc(
      getRecipes: sl(),
      getInventory: sl(),
      getEquippedItems: sl(),
      craftItem: sl(),
      equipItem: sl(),
      unequipItem: sl(),
      repository: sl(),
    ),
  );

  // ========== Core Services ==========

  // VersionCheckService (Singleton)
  sl.registerLazySingleton<VersionCheckService>(
    () => VersionCheckService(),
  );

  // AppLifecycleService (Singleton - 앱 전역에서 하나만 존재)
  // 주의: CurrencyBloc, VersionCheckService에 의존하므로 등록 후에 생성해야 함
  // 하지만 registerLazySingleton으로 등록하므로 실제 사용 시점에 생성됨
  sl.registerLazySingleton<AppLifecycleService>(
    () => AppLifecycleService(
      prefs: sl(),
      currencyBloc: sl(),
      versionCheckService: sl(),
    ),
  );
}
