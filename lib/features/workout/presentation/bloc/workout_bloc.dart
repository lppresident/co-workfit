import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_event.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_state.dart';
import 'package:co_workfit/features/workout/domain/usecases/request_health_permission.dart';
import 'package:co_workfit/features/workout/domain/usecases/get_workouts.dart';

/// 운동 BLoC
class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final RequestHealthPermission requestHealthPermission;
  final GetTodayWorkouts getTodayWorkouts;
  final GetRecentWorkouts getRecentWorkouts;
  final GetWorkouts getWorkouts;

  WorkoutBloc({
    required this.requestHealthPermission,
    required this.getTodayWorkouts,
    required this.getRecentWorkouts,
    required this.getWorkouts,
  }) : super(const WorkoutInitial()) {
    on<RequestHealthPermissionEvent>(_onRequestHealthPermission);
    on<FetchTodayWorkoutsEvent>(_onFetchTodayWorkouts);
    on<FetchRecentWorkoutsEvent>(_onFetchRecentWorkouts);
    on<FetchWorkoutsEvent>(_onFetchWorkouts);
    on<RefreshWorkoutsEvent>(_onRefreshWorkouts);
  }

  Future<void> _onRequestHealthPermission(
    RequestHealthPermissionEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(const WorkoutPermissionRequesting());

    final result = await requestHealthPermission();

    result.fold(
      (error) => emit(WorkoutPermissionDenied(error)),
      (granted) {
        if (granted) {
          emit(const WorkoutPermissionGranted());
          // 권한 승인 후 자동으로 오늘의 운동 가져오기
          add(const FetchTodayWorkoutsEvent());
        } else {
          emit(const WorkoutPermissionDenied('권한이 거부되었습니다.'));
        }
      },
    );
  }

  Future<void> _onFetchTodayWorkouts(
    FetchTodayWorkoutsEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(const WorkoutLoading());

    final result = await getTodayWorkouts();

    result.fold(
      (error) => emit(WorkoutError(error)),
      (workouts) {
        if (workouts.isEmpty) {
          emit(const WorkoutEmpty());
        } else {
          emit(WorkoutLoaded.fromWorkouts(workouts));
        }
      },
    );
  }

  Future<void> _onFetchRecentWorkouts(
    FetchRecentWorkoutsEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(const WorkoutLoading());

    final result = await getRecentWorkouts(days: event.days);

    result.fold(
      (error) => emit(WorkoutError(error)),
      (workouts) {
        if (workouts.isEmpty) {
          emit(const WorkoutEmpty());
        } else {
          emit(WorkoutLoaded.fromWorkouts(workouts));
        }
      },
    );
  }

  Future<void> _onFetchWorkouts(
    FetchWorkoutsEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(const WorkoutLoading());

    final result = await getWorkouts(
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      (error) => emit(WorkoutError(error)),
      (workouts) {
        if (workouts.isEmpty) {
          emit(const WorkoutEmpty());
        } else {
          emit(WorkoutLoaded.fromWorkouts(workouts));
        }
      },
    );
  }

  Future<void> _onRefreshWorkouts(
    RefreshWorkoutsEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    // 현재 상태에 따라 다시 가져오기
    if (state is WorkoutLoaded) {
      add(const FetchTodayWorkoutsEvent());
    } else {
      add(const FetchTodayWorkoutsEvent());
    }
  }
}
