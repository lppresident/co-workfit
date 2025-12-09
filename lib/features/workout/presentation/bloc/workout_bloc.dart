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
    print('[WorkoutBloc] 권한 요청 시작');
    emit(const WorkoutPermissionRequesting());

    final result = await requestHealthPermission();

    result.fold(
      (error) {
        print('[WorkoutBloc] 권한 요청 실패: $error');
        emit(WorkoutPermissionDenied(error));
      },
      (granted) {
        print('[WorkoutBloc] 권한 요청 결과: $granted');
        if (granted) {
          print('[WorkoutBloc] 권한 승인됨 - 최근 운동 데이터 로드 시작');
          emit(const WorkoutPermissionGranted());
          // 권한 승인 후 자동으로 최근 7일 운동 가져오기
          add(const FetchRecentWorkoutsEvent(days: 7));
        } else {
          print('[WorkoutBloc] 권한 거부됨');
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
    print('[WorkoutBloc] 최근 ${event.days}일 운동 데이터 로드 시작');
    emit(const WorkoutLoading());

    final result = await getRecentWorkouts(days: event.days);

    result.fold(
      (error) {
        print('[WorkoutBloc] 운동 데이터 로드 실패: $error');
        emit(WorkoutError(error));
      },
      (workouts) {
        print('[WorkoutBloc] 운동 데이터 로드 완료: ${workouts.length}개');
        if (workouts.isEmpty) {
          print('[WorkoutBloc] 운동 데이터 없음');
          emit(const WorkoutEmpty());
        } else {
          print('[WorkoutBloc] 운동 데이터 표시');
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
    print('[WorkoutBloc] 새로고침 요청 - 데이터 로드 시도');
    emit(const WorkoutLoading());

    // 데이터를 가져와서 권한 상태를 확인
    final result = await getRecentWorkouts(days: 7);

    result.fold(
      (error) {
        print('[WorkoutBloc] 새로고침 실패: $error');

        // 권한 관련 에러인지 확인
        final errorLower = error.toLowerCase();
        if (error == 'HEALTH_CONNECT_NOT_INSTALLED' ||
            errorLower.contains('not installed') ||
            errorLower.contains('not available')) {
          print('[WorkoutBloc] Health Connect 미설치 - 권한 UI 표시');
          emit(const WorkoutPermissionDenied('HEALTH_CONNECT_NOT_INSTALLED'));
        } else if (error == 'HEALTH_PERMISSION_DENIED' ||
            errorLower.contains('permission') ||
            errorLower.contains('권한') ||
            errorLower.contains('authorized') ||
            errorLower.contains('access denied')) {
          print('[WorkoutBloc] 권한 거부됨 - 권한 UI 표시');
          emit(const WorkoutPermissionDenied('HEALTH_PERMISSION_DENIED'));
        } else {
          // 기타 에러
          print('[WorkoutBloc] 일반 에러 - 에러 UI 표시');
          emit(WorkoutError(error));
        }
      },
      (workouts) {
        print('[WorkoutBloc] 새로고침 성공: ${workouts.length}개');
        if (workouts.isEmpty) {
          emit(const WorkoutEmpty());
        } else {
          emit(WorkoutLoaded.fromWorkouts(workouts));
        }
      },
    );
  }
}
