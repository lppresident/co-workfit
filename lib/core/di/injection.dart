import 'package:get_it/get_it.dart';
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
}
