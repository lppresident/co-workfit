import 'package:get_it/get_it.dart';
import 'package:co_workfit/features/workout/data/datasources/health_kit_datasource.dart';
import 'package:co_workfit/features/workout/data/datasources/health_data_mapper.dart';
import 'package:co_workfit/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';
import 'package:co_workfit/features/workout/domain/usecases/get_workouts.dart';
import 'package:co_workfit/features/workout/domain/usecases/request_health_permission.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Data Sources
  sl.registerLazySingleton<HealthKitDataSource>(
    () => HealthKitDataSource(),
  );

  sl.registerLazySingleton<HealthDataMapper>(
    () => HealthDataMapper(),
  );

  // Repository
  sl.registerLazySingleton<WorkoutRepository>(
    () => WorkoutRepositoryImpl(
      healthKitDataSource: sl(),
      healthDataMapper: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => RequestHealthPermission(sl()));
  sl.registerLazySingleton(() => GetWorkouts(sl()));
  sl.registerLazySingleton(() => GetTodayWorkouts(sl()));
  sl.registerLazySingleton(() => GetRecentWorkouts(sl()));

  // BLoC
  sl.registerFactory(
    () => WorkoutBloc(
      requestHealthPermission: sl(),
      getTodayWorkouts: sl(),
      getRecentWorkouts: sl(),
      getWorkouts: sl(),
    ),
  );
}
