import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_event.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_state.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';
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
    emit(const LogRunLoading());

    final result = await getActiveChallengesUseCase(event.userId);

    result.fold(
      (failure) => emit(LogRunError(failure.toString())),
      (challenges) {
        if (challenges.isEmpty) {
          emit(const LogRunEmpty());
        } else {
          emit(ChallengesLoaded(
            activeChallenges: challenges,
            completedChallenges: const [],
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
        }
      },
    );
  }

  Future<void> _onCreateChallenge(
    CreateChallenge event,
    Emitter<LogRunState> emit,
  ) async {
    emit(const LogRunLoading());

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
      (failure) => emit(LogRunError(failure.toString())),
      (contribution) {
        AppLogger.info('LogRunBloc', 'Workout submitted: ${contribution.id}');
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

    _challengeSubscription = repository.watchChallenge(event.challengeId).listen(
      (result) {
        result.fold(
          (failure) => add(LoadChallengeDetail(event.challengeId)),
          (challenge) => emit(ChallengeUpdated(challenge)),
        );
      },
    );
  }

  Future<void> _onWatchContributions(
    WatchContributions event,
    Emitter<LogRunState> emit,
  ) async {
    await _contributionsSubscription?.cancel();

    _contributionsSubscription = repository.watchContributions(event.challengeId).listen(
      (result) {
        result.fold(
          (failure) => AppLogger.error('LogRunBloc', 'Error watching contributions: $failure'),
          (contributions) => emit(ContributionsUpdated(contributions)),
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
