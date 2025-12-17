import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_event.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_state.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_contribution_entity.dart';
import 'package:co_workfit/features/log_run/domain/usecases/create_log_run_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/join_log_run_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/submit_workout_to_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/get_active_challenges.dart';
import 'package:co_workfit/features/log_run/domain/usecases/get_challenge_contributions.dart';
import 'package:co_workfit/features/log_run/domain/repositories/log_run_repository.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 통나무런 BLoC
class LogRunBloc extends Bloc<LogRunEvent, LogRunState> {
  final CreateLogRunChallenge createChallengeUseCase;
  final JoinLogRunChallenge joinChallengeUseCase;
  final SubmitWorkoutToChallenge submitWorkoutUseCase;
  final GetActiveChallenges getActiveChallengesUseCase;
  final GetChallengeContributions getChallengeContributionsUseCase;
  final LogRunRepository repository;

  StreamSubscription? _challengeSubscription;
  StreamSubscription? _contributionsSubscription;

  LogRunBloc({
    required this.createChallengeUseCase,
    required this.joinChallengeUseCase,
    required this.submitWorkoutUseCase,
    required this.getActiveChallengesUseCase,
    required this.getChallengeContributionsUseCase,
    required this.repository,
  }) : super(const LogRunInitial()) {
    on<LoadActiveChallenges>(_onLoadActiveChallenges);
    on<LoadCompletedChallenges>(_onLoadCompletedChallenges);
    on<CreateChallenge>(_onCreateChallenge);
    on<JoinChallenge>(_onJoinChallenge);
    on<LeaveChallenge>(_onLeaveChallenge);
    on<SubmitWorkout>(_onSubmitWorkout);
    on<LoadChallengeDetail>(_onLoadChallengeDetail);
    on<LoadChallengeContributions>(_onLoadChallengeContributions);
    on<WatchChallenge>(_onWatchChallenge);
    on<WatchContributions>(_onWatchContributions);
    on<DeleteChallenge>(_onDeleteChallenge);
    on<RefreshChallenges>(_onRefreshChallenges);
  }

  Future<void> _onLoadActiveChallenges(
    LoadActiveChallenges event,
    Emitter<LogRunState> emit,
  ) async {
    // 초기 로딩이 아닌 경우 로딩 상태를 emit하지 않음 (깜빡임 방지)
    if (state is LogRunInitial) {
      emit(const LogRunLoading());
    }

    // 이전 완료 챌린지 상태 저장
    final previousCompletedChallenges = state is ChallengesLoaded
        ? (state as ChallengesLoaded).completedChallenges
        : (state is ChallengeDetailLoaded
            ? (state as ChallengeDetailLoaded).completedChallenges
            : <LogRunChallengeEntity>[]);

    final result = await getActiveChallengesUseCase(event.userId);

    result.fold(
      (failure) => emit(LogRunError(failure.toString())),
      (challenges) {
        if (challenges.isEmpty && previousCompletedChallenges.isEmpty) {
          emit(const LogRunEmpty());
        } else {
          emit(ChallengesLoaded(
            activeChallenges: challenges,
            completedChallenges: previousCompletedChallenges,
          ));
        }
      },
    );
  }

  Future<void> _onLoadCompletedChallenges(
    LoadCompletedChallenges event,
    Emitter<LogRunState> emit,
  ) async {
    final result = await repository.getCompletedChallenges(event.userId);

    result.fold(
      (failure) => AppLogger.error('LogRunBloc', 'Error loading completed challenges: $failure'),
      (challenges) {
        if (state is ChallengesLoaded) {
          final currentState = state as ChallengesLoaded;
          emit(ChallengesLoaded(
            activeChallenges: currentState.activeChallenges,
            completedChallenges: challenges,
          ));
        } else if (state is ChallengeDetailLoaded) {
          final currentState = state as ChallengeDetailLoaded;
          emit(ChallengeDetailLoaded(
            challenge: currentState.challenge,
            contributions: currentState.contributions,
            activeChallenges: currentState.activeChallenges,
            completedChallenges: challenges,
          ));
        } else {
          // 아직 활성 챌린지가 로드되지 않은 경우, 완료 챌린지만 먼저 로드
          emit(ChallengesLoaded(
            activeChallenges: const [],
            completedChallenges: challenges,
          ));
        }
      },
    );
  }

  Future<void> _onCreateChallenge(
    CreateChallenge event,
    Emitter<LogRunState> emit,
  ) async {
    // 챌린지 생성 중에는 현재 상태 유지 (로딩 상태로 바꾸지 않음)
    final result = await createChallengeUseCase(
      CreateChallengeParams(
        userId: event.userId,
        userName: event.userName,
        targetWeight: event.targetWeight,
        recordTimeLimit: event.recordTimeLimit,
        allowFutureRecordsOnly: event.allowFutureRecordsOnly,
        expiresAt: event.expiresAt,
      ),
    );

    result.fold(
      (failure) => emit(LogRunError(failure.toString())),
      (challenge) {
        AppLogger.info('LogRunBloc', 'Challenge created: ${challenge.id}');
        emit(ChallengeCreated(challenge));
      },
    );
  }

  Future<void> _onJoinChallenge(
    JoinChallenge event,
    Emitter<LogRunState> emit,
  ) async {
    final result = await joinChallengeUseCase(
      JoinChallengeParams(
        challengeId: event.challengeId,
        userId: event.userId,
        userName: event.userName,
      ),
    );

    result.fold(
      (failure) => emit(LogRunError(failure.toString())),
      (_) {
        AppLogger.info('LogRunBloc', 'Joined challenge: ${event.challengeId}');
        emit(ChallengeJoined(event.challengeId));
      },
    );
  }

  Future<void> _onLeaveChallenge(
    LeaveChallenge event,
    Emitter<LogRunState> emit,
  ) async {
    final result = await repository.leaveChallenge(
      challengeId: event.challengeId,
      userId: event.userId,
    );

    result.fold(
      (failure) => emit(LogRunError(failure.toString())),
      (_) {
        AppLogger.info('LogRunBloc', 'Left challenge: ${event.challengeId}');
        add(RefreshChallenges(event.userId));
      },
    );
  }

  Future<void> _onSubmitWorkout(
    SubmitWorkout event,
    Emitter<LogRunState> emit,
  ) async {
    AppLogger.info('LogRunBloc', '📤 Submitting workout to challenge: ${event.challengeId}');
    AppLogger.debug('LogRunBloc', '   Current state before submit: ${state.runtimeType}');

    final result = await submitWorkoutUseCase(
      SubmitWorkoutParams(
        challengeId: event.challengeId,
        userId: event.userId,
        userName: event.userName,
        workoutId: event.workoutId,
        distance: event.distance,
        workoutType: event.workoutType,
        workoutDate: event.workoutDate,
      ),
    );

    result.fold(
      (failure) {
        AppLogger.error('LogRunBloc', '❌ Workout submission failed: $failure');
        emit(LogRunError(failure.toString()));
      },
      (contribution) {
        AppLogger.info('LogRunBloc', '✅ Workout submitted successfully: ${contribution.id}');
        AppLogger.debug('LogRunBloc', '   Emitting WorkoutSubmitted state');
        emit(WorkoutSubmitted(contribution));
      },
    );
  }

  Future<void> _onLoadChallengeDetail(
    LoadChallengeDetail event,
    Emitter<LogRunState> emit,
  ) async {
    // 이전 목록 상태 저장
    final previousActiveChallenges = state is ChallengesLoaded
        ? (state as ChallengesLoaded).activeChallenges
        : (state is ChallengeDetailLoaded
            ? (state as ChallengeDetailLoaded).activeChallenges
            : <LogRunChallengeEntity>[]);
    final previousCompletedChallenges = state is ChallengesLoaded
        ? (state as ChallengesLoaded).completedChallenges
        : (state is ChallengeDetailLoaded
            ? (state as ChallengeDetailLoaded).completedChallenges
            : <LogRunChallengeEntity>[]);

    final challengeResult = await repository.getChallengeById(event.challengeId);
    final contributionsResult = await getChallengeContributionsUseCase(event.challengeId);

    await challengeResult.fold(
      (failure) async => emit(LogRunError(failure.toString())),
      (challenge) async {
        await contributionsResult.fold(
          (failure) async => emit(LogRunError(failure.toString())),
          (contributions) async {
            emit(ChallengeDetailLoaded(
              challenge: challenge,
              contributions: contributions,
              activeChallenges: previousActiveChallenges,
              completedChallenges: previousCompletedChallenges,
            ));
          },
        );
      },
    );
  }

  Future<void> _onLoadChallengeContributions(
    LoadChallengeContributions event,
    Emitter<LogRunState> emit,
  ) async {
    final result = await getChallengeContributionsUseCase(event.challengeId);

    result.fold(
      (failure) => emit(LogRunError(failure.toString())),
      (contributions) => emit(ContributionsUpdated(contributions)),
    );
  }

  Future<void> _onWatchChallenge(
    WatchChallenge event,
    Emitter<LogRunState> emit,
  ) async {
    await _challengeSubscription?.cancel();

    await emit.forEach<Either<Failure, LogRunChallengeEntity>>(
      repository.watchChallenge(event.challengeId),
      onData: (result) {
        return result.fold(
          (failure) {
            AppLogger.error('LogRunBloc', '❌ Error watching challenge: $failure');
            return state; // Keep current state on error
          },
          (challenge) {
            AppLogger.debug('LogRunBloc', '🔄 Challenge updated: ${challenge.id}');
            // 현재 기여 내역 유지하면서 챌린지만 업데이트
            if (state is ChallengeDetailLoaded) {
              final currentState = state as ChallengeDetailLoaded;
              return ChallengeDetailLoaded(
                challenge: challenge,
                contributions: currentState.contributions,
                activeChallenges: currentState.activeChallenges,
                completedChallenges: currentState.completedChallenges,
              );
            } else {
              // 폴백: 기존 동작 유지
              return ChallengeUpdated(challenge);
            }
          },
        );
      },
    );
  }

  Future<void> _onWatchContributions(
    WatchContributions event,
    Emitter<LogRunState> emit,
  ) async {
    AppLogger.info('LogRunBloc', '👀 Starting to watch contributions for challenge: ${event.challengeId}');
    await _contributionsSubscription?.cancel();

    await emit.forEach<Either<Failure, List<LogRunContributionEntity>>>(
      repository.watchContributions(event.challengeId),
      onData: (result) {
        return result.fold(
          (failure) {
            AppLogger.error('LogRunBloc', '❌ Error watching contributions: $failure');
            return state; // Keep current state on error
          },
          (contributions) {
            AppLogger.info('LogRunBloc', '🔄 Contributions updated: ${contributions.length} contributions');
            AppLogger.debug('LogRunBloc', '   Current state: ${state.runtimeType}');

            // 현재 챌린지 상태 유지하면서 기여 내역만 업데이트
            if (state is ChallengeDetailLoaded) {
              final currentState = state as ChallengeDetailLoaded;
              AppLogger.debug('LogRunBloc', '   ✅ ChallengeDetailLoaded - Preserving active:${currentState.activeChallenges.length} completed:${currentState.completedChallenges.length}');
              return ChallengeDetailLoaded(
                challenge: currentState.challenge,
                contributions: contributions,
                activeChallenges: currentState.activeChallenges,
                completedChallenges: currentState.completedChallenges,
              );
            } else if (state is ChallengeUpdated) {
              AppLogger.debug('LogRunBloc', '   ⚠️ ChallengeUpdated - Converting to ChallengeDetailLoaded');
              // ChallengeUpdated 상태에서도 챌린지 정보 유지
              final currentState = state as ChallengeUpdated;
              return ChallengeDetailLoaded(
                challenge: currentState.challenge,
                contributions: contributions,
              );
            } else {
              AppLogger.warning('LogRunBloc', '   ⚠️ Unexpected state (${state.runtimeType}) - Using fallback ContributionsUpdated');
              // 폴백: 기존 동작 유지
              return ContributionsUpdated(contributions);
            }
          },
        );
      },
    );
  }

  Future<void> _onDeleteChallenge(
    DeleteChallenge event,
    Emitter<LogRunState> emit,
  ) async {
    final result = await repository.deleteChallenge(
      challengeId: event.challengeId,
      userId: event.userId,
    );

    result.fold(
      (failure) => emit(LogRunError(failure.toString())),
      (_) {
        AppLogger.info('LogRunBloc', 'Challenge deleted: ${event.challengeId}');
        emit(ChallengeDeleted(event.challengeId));
      },
    );
  }

  Future<void> _onRefreshChallenges(
    RefreshChallenges event,
    Emitter<LogRunState> emit,
  ) async {
    add(LoadActiveChallenges(event.userId));
    add(LoadCompletedChallenges(event.userId));
  }

  @override
  Future<void> close() {
    _challengeSubscription?.cancel();
    _contributionsSubscription?.cancel();
    return super.close();
  }
}
