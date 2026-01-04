import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_event.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_state.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_contribution_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/workout_type.dart';
import 'package:co_workfit/features/log_run/domain/usecases/create_log_run_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/join_log_run_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/join_challenge_by_invite_code.dart';
import 'package:co_workfit/features/log_run/domain/usecases/submit_workout_to_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/get_active_challenges.dart';
import 'package:co_workfit/features/log_run/domain/usecases/get_challenge_contributions.dart';
import 'package:co_workfit/features/log_run/domain/usecases/delete_contribution.dart';
import 'package:co_workfit/features/log_run/domain/repositories/log_run_repository.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 챌린지 BLoC
class LogRunBloc extends Bloc<LogRunEvent, LogRunState> {
  final CreateLogRunChallenge createChallengeUseCase;
  final JoinLogRunChallenge joinChallengeUseCase;
  final JoinChallengeByInviteCode joinChallengeByCodeUseCase;
  final SubmitWorkoutToChallenge submitWorkoutUseCase;
  final GetAllChallenges getAllChallengesUseCase;
  final GetChallengeContributions getChallengeContributionsUseCase;
  final DeleteContribution deleteContributionUseCase;
  final LogRunRepository repository;

  StreamSubscription? _challengeSubscription;
  StreamSubscription? _contributionsSubscription;

  LogRunBloc({
    required this.createChallengeUseCase,
    required this.joinChallengeUseCase,
    required this.joinChallengeByCodeUseCase,
    required this.submitWorkoutUseCase,
    required this.getAllChallengesUseCase,
    required this.getChallengeContributionsUseCase,
    required this.deleteContributionUseCase,
    required this.repository,
  }) : super(const LogRunInitial()) {
    on<LoadChallenges>(_onLoadChallenges);
    on<CreateChallenge>(_onCreateChallenge);
    on<JoinChallenge>(_onJoinChallenge);
    on<JoinChallengeByCode>(_onJoinChallengeByCode);
    on<LeaveChallenge>(_onLeaveChallenge);
    on<SubmitWorkout>(_onSubmitWorkout);
    on<LoadChallengeDetail>(_onLoadChallengeDetail);
    on<LoadChallengeContributions>(_onLoadChallengeContributions);
    on<WatchChallenge>(_onWatchChallenge);
    on<WatchContributions>(_onWatchContributions);
    on<DeleteChallenge>(_onDeleteChallenge);
    on<DeleteContributionEvent>(_onDeleteContribution);
  }

  /// 현재 상태에서 챌린지 목록 추출
  List<LogRunChallengeEntity> _getCurrentChallenges() {
    if (state is ChallengesLoaded) {
      return (state as ChallengesLoaded).challenges;
    } else if (state is ChallengeDetailLoaded) {
      return (state as ChallengeDetailLoaded).challenges;
    } else if (state is WorkoutSubmitted) {
      return (state as WorkoutSubmitted).challenges;
    }
    return [];
  }

  Future<void> _onLoadChallenges(
    LoadChallenges event,
    Emitter<LogRunState> emit,
  ) async {
    // 초기 로딩인 경우에만 로딩 상태 표시
    if (state is LogRunInitial) {
      emit(const LogRunLoading());
    }

    AppLogger.info('LogRunBloc', 'LoadChallenges 시작: userId=${event.userId}');
    final result = await getAllChallengesUseCase(event.userId);

    result.fold(
      (failure) {
        AppLogger.error('LogRunBloc', 'LoadChallenges 실패: $failure');
        emit(LogRunError(failure.toString()));
      },
      (challenges) {
        AppLogger.info('LogRunBloc', 'LoadChallenges 성공: ${challenges.length}개');
        if (challenges.isEmpty) {
          emit(const LogRunEmpty());
        } else {
          emit(ChallengesLoaded(challenges: challenges));
        }
      },
    );
  }

  Future<void> _onCreateChallenge(
    CreateChallenge event,
    Emitter<LogRunState> emit,
  ) async {
    final result = await createChallengeUseCase(
      CreateChallengeParams(
        userId: event.userId,
        userNickname: event.userNickname,
        targetWeight: event.targetWeight,
        challengeDate: event.challengeDate,
        maxParticipants: event.maxParticipants,
        challengeType: event.challengeType,
      ),
    );

    result.fold(
      (failure) => emit(LogRunError(failure.toString())),
      (challenge) {
        AppLogger.info('LogRunBloc', 'Challenge created: ${challenge.id}, type: ${event.challengeType.displayName}');
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
        userNickname: event.userNickname,
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

  Future<void> _onJoinChallengeByCode(
    JoinChallengeByCode event,
    Emitter<LogRunState> emit,
  ) async {
    emit(const LogRunLoading());

    final result = await joinChallengeByCodeUseCase(
      JoinByCodeParams(
        inviteCode: event.inviteCode,
        userId: event.userId,
        userNickname: event.userNickname,
      ),
    );

    result.fold(
      (failure) => emit(LogRunError(failure.toString())),
      (challenge) {
        AppLogger.info('LogRunBloc', 'Joined challenge by code: ${challenge.id}');
        emit(ChallengeJoined(challenge.id));
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
        add(LoadChallenges(event.userId));
      },
    );
  }

  Future<void> _onSubmitWorkout(
    SubmitWorkout event,
    Emitter<LogRunState> emit,
  ) async {
    // 현재 상태에서 챌린지 정보 추출
    LogRunChallengeEntity? currentChallenge;
    final challenges = _getCurrentChallenges();

    if (state is ChallengeDetailLoaded) {
      currentChallenge = (state as ChallengeDetailLoaded).challenge;
    }

    final result = await submitWorkoutUseCase(
      SubmitWorkoutParams(
        challengeId: event.challengeId,
        userId: event.userId,
        userNickname: event.userNickname,
        workout: event.workout,
      ),
    );

    result.fold(
      (failure) => emit(LogRunError(failure.toString())),
      (contribution) {
        if (currentChallenge != null) {
          emit(WorkoutSubmitted(
            contribution: contribution,
            challenge: currentChallenge,
            challenges: challenges,
          ));
        } else {
          emit(const LogRunError('챌린지 정보를 찾을 수 없습니다'));
        }
      },
    );
  }

  Future<void> _onLoadChallengeDetail(
    LoadChallengeDetail event,
    Emitter<LogRunState> emit,
  ) async {
    // 이전 목록 상태 유지
    final previousChallenges = _getCurrentChallenges();

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
              challenges: previousChallenges,
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
          (failure) => state,
          (challenge) {
            List<LogRunContributionEntity> currentContributions = [];
            final challenges = _getCurrentChallenges();

            if (state is ChallengeDetailLoaded) {
              currentContributions = (state as ChallengeDetailLoaded).contributions;
            }

            return ChallengeDetailLoaded(
              challenge: challenge,
              contributions: currentContributions,
              challenges: challenges,
            );
          },
        );
      },
    );
  }

  Future<void> _onWatchContributions(
    WatchContributions event,
    Emitter<LogRunState> emit,
  ) async {
    await _contributionsSubscription?.cancel();

    await emit.forEach<Either<Failure, List<LogRunContributionEntity>>>(
      repository.watchContributions(event.challengeId),
      onData: (result) {
        return result.fold(
          (failure) => state,
          (contributions) {
            LogRunChallengeEntity? currentChallenge;
            final challenges = _getCurrentChallenges();

            if (state is ChallengeDetailLoaded) {
              currentChallenge = (state as ChallengeDetailLoaded).challenge;
            } else if (state is WorkoutSubmitted) {
              currentChallenge = (state as WorkoutSubmitted).challenge;
            } else if (state is ChallengeUpdated) {
              currentChallenge = (state as ChallengeUpdated).challenge;
            }

            if (currentChallenge != null) {
              return ChallengeDetailLoaded(
                challenge: currentChallenge,
                contributions: contributions,
                challenges: challenges,
              );
            } else {
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

  Future<void> _onDeleteContribution(
    DeleteContributionEvent event,
    Emitter<LogRunState> emit,
  ) async {
    final result = await deleteContributionUseCase(
      DeleteContributionParams(
        challengeId: event.challengeId,
        contributionId: event.contributionId,
        userId: event.userId,
      ),
    );

    result.fold(
      (failure) => emit(LogRunError(failure.toString())),
      (_) {
        AppLogger.info('LogRunBloc', 'Contribution deleted: ${event.contributionId}');
        emit(ContributionDeleted(
          contributionId: event.contributionId,
          challengeId: event.challengeId,
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _challengeSubscription?.cancel();
    _contributionsSubscription?.cancel();
    return super.close();
  }
}
