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
import 'package:co_workfit/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_out.dart';
import 'package:co_workfit/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';

// Profile
import 'package:co_workfit/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:co_workfit/features/profile/data/datasources/profile_remote_data_source_impl.dart';
import 'package:co_workfit/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:co_workfit/features/profile/domain/repositories/profile_repository.dart';
import 'package:co_workfit/features/profile/domain/usecases/get_profile_data.dart';
import 'package:co_workfit/features/profile/domain/usecases/logout_user.dart';
import 'package:co_workfit/features/profile/domain/usecases/update_display_name_use_case.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_bloc.dart';

// Social
import 'package:co_workfit/features/social/data/datasources/firestore_social_datasource.dart';

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
  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => SignUpWithEmail(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      signInWithEmail: sl(),
      signUpWithEmail: sl(),
      signInWithGoogle: sl(),
      signOut: sl(),
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
}
