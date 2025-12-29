import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_event.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_state.dart';
import 'package:co_workfit/features/workout/domain/usecases/request_health_permission.dart';
import 'package:co_workfit/features/workout/domain/usecases/get_workouts.dart';
import 'package:co_workfit/features/workout/domain/usecases/update_workout_distance.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 운동 BLoC
class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final RequestHealthPermission requestHealthPermission;
  final GetTodayWorkouts getTodayWorkouts;
  final GetRecentWorkouts getRecentWorkouts;
  final GetWorkouts getWorkouts;
  final UpdateWorkoutDistance updateWorkoutDistance;

  WorkoutBloc({
    required this.requestHealthPermission,
    required this.getTodayWorkouts,
    required this.getRecentWorkouts,
    required this.getWorkouts,
    required this.updateWorkoutDistance,
  }) : super(const WorkoutInitial()) {
    on<RequestHealthPermissionEvent>(_onRequestHealthPermission);
    on<FetchTodayWorkoutsEvent>(_onFetchTodayWorkouts);
    on<FetchRecentWorkoutsEvent>(_onFetchRecentWorkouts);
    on<FetchWorkoutsEvent>(_onFetchWorkouts);
    on<RefreshWorkoutsEvent>(_onRefreshWorkouts);
    on<UpdateWorkoutDistanceEvent>(_onUpdateWorkoutDistance);
  }

  Future<void> _onRequestHealthPermission(
    RequestHealthPermissionEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    AppLogger.info('WorkoutBloc', '권한 요청 시작');
    emit(const WorkoutPermissionRequesting());

    final result = await requestHealthPermission();

    result.fold(
      (error) {
        AppLogger.error('WorkoutBloc', '권한 요청 실패: $error');
        emit(WorkoutPermissionDenied(error));
      },
      (granted) {
        AppLogger.info('WorkoutBloc', '권한 요청 결과: $granted');
        if (granted) {
          AppLogger.info('WorkoutBloc', '권한 승인됨 - 최근 운동 데이터 로드 시작');
          emit(const WorkoutPermissionGranted());
          // 권한 승인 후 자동으로 최근 7일 운동 가져오기
          add(const FetchRecentWorkoutsEvent(days: 7));
        } else {
          AppLogger.warning('WorkoutBloc', '권한 거부됨');
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
    AppLogger.info('WorkoutBloc', '최근 ${event.days}일 운동 데이터 로드 시작');
    emit(const WorkoutLoading());

    await _loadWorkoutsWithPermissionCheck(emit, days: event.days);
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
    AppLogger.info('WorkoutBloc', '새로고침 요청 - 데이터 로드 시도');
    emit(const WorkoutLoading());

    await _loadWorkoutsWithPermissionCheck(emit, days: 7);
  }

  /// 운동 데이터 로드 및 권한 상태 확인 (공통 로직)
  ///
  /// 첫 진입과 새로고침 모두 동일한 로직을 사용합니다:
  /// 1. 데이터를 가져옵니다 (15초 타임아웃)
  /// 2. 실패 시 권한 관련 에러인지 확인
  /// 3. 성공했지만 데이터가 비어있으면 권한 상태를 추가 확인 (5초 타임아웃)
  Future<void> _loadWorkoutsWithPermissionCheck(
    Emitter<WorkoutState> emit, {
    required int days,
  }) async {
    final startTime = DateTime.now();
    AppLogger.debug('WorkoutBloc', '시작 시간: ${startTime.toIso8601String()}');

    try {
      // 전체 로드 프로세스에 15초 타임아웃 적용
      AppLogger.debug('WorkoutBloc', '데이터 로드 시작...');
      final dataLoadStart = DateTime.now();

      final result = await getRecentWorkouts(days: days).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          final elapsed = DateTime.now().difference(dataLoadStart).inMilliseconds;
          AppLogger.performance('WorkoutBloc', '데이터 로드 타임아웃', elapsed);
          return Left('데이터 로드 시간 초과');
        },
      );

      final dataLoadElapsed = DateTime.now().difference(dataLoadStart).inMilliseconds;
      AppLogger.performance('WorkoutBloc', '데이터 로드 완료', dataLoadElapsed);

      // fold 대신 isLeft/isRight로 처리 (async 콜백 문제 방지)
      if (result.isLeft()) {
        final error = result.fold((l) => l, (r) => '');
        final totalElapsed = DateTime.now().difference(startTime).inMilliseconds;
        AppLogger.performance('WorkoutBloc', '데이터 로드 실패', totalElapsed);
        AppLogger.error('WorkoutBloc', '데이터 로드 실패: $error');

        // 권한 관련 에러인지 확인
        final errorLower = error.toLowerCase();
        if (error == 'HEALTH_CONNECT_NOT_INSTALLED' ||
            errorLower.contains('not installed') ||
            errorLower.contains('not available')) {
          AppLogger.warning('WorkoutBloc', 'Health Connect 미설치 - 권한 UI 표시');
          emit(const WorkoutPermissionDenied('HEALTH_CONNECT_NOT_INSTALLED'));
        } else if (error == 'HEALTH_PERMISSION_DENIED' ||
            errorLower.contains('permission') ||
            errorLower.contains('권한') ||
            errorLower.contains('authorized') ||
            errorLower.contains('access denied')) {
          AppLogger.warning('WorkoutBloc', '권한 거부됨 - 권한 UI 표시');
          emit(const WorkoutPermissionDenied('HEALTH_PERMISSION_DENIED'));
        } else {
          // 기타 에러 (타임아웃 포함) - 초기 상태로 전환
          AppLogger.info('WorkoutBloc', '일반 에러 - 초기 상태로 전환');
          emit(const WorkoutInitial());
        }
      } else {
        final workouts = result.getOrElse(() => []);
        final totalElapsed = DateTime.now().difference(startTime).inMilliseconds;
        AppLogger.performance('WorkoutBloc', '데이터 로드 성공: ${workouts.length}개', totalElapsed);

        if (workouts.isEmpty) {
          // 데이터가 비어있을 때: 권한 부족인지 실제로 데이터가 없는지 확인 (5초 타임아웃)
          AppLogger.info('WorkoutBloc', '데이터 없음 - 권한 상태 확인 중');
          AppLogger.debug('WorkoutBloc', '권한 확인 시작...');
          final permissionCheckStart = DateTime.now();

          try {
            final permissionResult = await requestHealthPermission().timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                final elapsed = DateTime.now().difference(permissionCheckStart).inMilliseconds;
                AppLogger.performance('WorkoutBloc', '권한 확인 타임아웃 - 초기 상태로', elapsed);
                return Left('권한 확인 시간 초과');
              },
            );

            final permissionCheckElapsed = DateTime.now().difference(permissionCheckStart).inMilliseconds;
            AppLogger.performance('WorkoutBloc', '권한 확인 완료', permissionCheckElapsed);

            if (permissionResult.isLeft()) {
              // 권한 확인 실패 = 권한 없음
              final permError = permissionResult.fold((l) => l, (r) => '');
              final totalElapsed2 = DateTime.now().difference(startTime).inMilliseconds;
              AppLogger.performance('WorkoutBloc', '권한 없음 확인됨 - 초기 상태로 전환', totalElapsed2);
              AppLogger.warning('WorkoutBloc', '권한 확인 실패: $permError');
              emit(const WorkoutInitial());
            } else {
              final granted = permissionResult.fold((l) => false, (r) => r);
              final totalElapsed2 = DateTime.now().difference(startTime).inMilliseconds;
              if (granted) {
                // 권한은 있는데 데이터가 없음
                AppLogger.performance('WorkoutBloc', '권한 있음 - 실제로 운동 데이터 없음', totalElapsed2);
                emit(const WorkoutEmpty());
              } else {
                // 권한 없음
                AppLogger.performance('WorkoutBloc', '권한 거부됨 - 초기 상태로 전환', totalElapsed2);
                emit(const WorkoutInitial());
              }
            }
          } catch (e) {
            final totalElapsed2 = DateTime.now().difference(startTime).inMilliseconds;
            AppLogger.performance('WorkoutBloc', '권한 확인 예외 발생 - 초기 상태로', totalElapsed2);
            AppLogger.error('WorkoutBloc', '권한 확인 예외', e);
            if (!emit.isDone) {
              emit(const WorkoutInitial());
            }
          }
        } else {
          emit(WorkoutLoaded.fromWorkouts(workouts));
          final totalElapsed2 = DateTime.now().difference(startTime).inMilliseconds;
          AppLogger.performance('WorkoutBloc', 'WorkoutLoaded emit 완료', totalElapsed2);
        }
      }
    } catch (e) {
      final totalElapsed = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.performance('WorkoutBloc', '데이터 로드 예외 발생 - 초기 상태로', totalElapsed);
      AppLogger.error('WorkoutBloc', '데이터 로드 예외', e);
      if (!emit.isDone) {
        final emitStart = DateTime.now();
        emit(const WorkoutInitial());
        final emitElapsed = DateTime.now().difference(emitStart).inMilliseconds;
        AppLogger.performance('WorkoutBloc', 'emit 완료', emitElapsed);
      }
    }

    final totalElapsed = DateTime.now().difference(startTime).inMilliseconds;
    AppLogger.performance('WorkoutBloc', '전체 프로세스 완료', totalElapsed);
  }

  Future<void> _onUpdateWorkoutDistance(
    UpdateWorkoutDistanceEvent event,
    Emitter<WorkoutState> emit,
  ) async {
    AppLogger.info('WorkoutBloc', '거리 수정 시작: ${event.workoutId} -> ${event.correctedDistance}km');

    // 현재 상태가 WorkoutLoaded인 경우만 처리
    if (state is! WorkoutLoaded) {
      AppLogger.warning('WorkoutBloc', '현재 상태가 WorkoutLoaded가 아님: $state');
      return;
    }

    final currentState = state as WorkoutLoaded;

    final result = await updateWorkoutDistance(
      UpdateWorkoutDistanceParams(
        workoutId: event.workoutId,
        correctedDistance: event.correctedDistance,
      ),
    );

    result.fold(
      (failure) {
        final errorMessage = failure.message;
        AppLogger.error('WorkoutBloc', '거리 수정 실패: $errorMessage');
        emit(WorkoutError(errorMessage));
      },
      (updatedWorkout) {
        AppLogger.info('WorkoutBloc', '거리 수정 완료: ${updatedWorkout.effectiveDistance}km');

        // 기존 운동 목록에서 수정된 운동 업데이트
        final updatedWorkouts = currentState.workouts.map((workout) {
          if (workout.id == updatedWorkout.id) {
            return updatedWorkout;
          }
          return workout;
        }).toList();

        // 통계 재계산 (fromWorkouts 팩토리 사용)
        emit(WorkoutLoaded.fromWorkouts(updatedWorkouts));
      },
    );
  }
}
