import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_event.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_state.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/contribution_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_invite_entity.dart';
import 'package:co_workfit/features/log_run/domain/usecases/create_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/join_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/join_challenge_by_invite_code.dart';
import 'package:co_workfit/features/log_run/domain/usecases/submit_workout_to_challenge.dart';
import 'package:co_workfit/features/log_run/domain/usecases/get_active_challenges.dart';
import 'package:co_workfit/features/log_run/domain/usecases/get_challenge_contributions.dart';
import 'package:co_workfit/features/log_run/domain/usecases/delete_contribution.dart';
import 'package:co_workfit/features/log_run/domain/usecases/create_challenge_invites.dart' as usecases;
import 'package:co_workfit/features/log_run/domain/usecases/get_my_invites.dart';
import 'package:co_workfit/features/log_run/domain/usecases/accept_invite.dart';
import 'package:co_workfit/features/log_run/domain/usecases/reject_invite.dart';
import 'package:co_workfit/features/log_run/domain/usecases/get_challenge_archives.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 챌린지 BLoC
class ChallengeBloc extends Bloc<ChallengeEvent, ChallengeState> {
  final CreateChallenge createChallengeUseCase;
  final JoinChallenge joinChallengeUseCase;
  final JoinChallengeByInviteCode joinChallengeByCodeUseCase;
  final SubmitWorkoutToChallenge submitWorkoutUseCase;
  final GetAllChallenges getAllChallengesUseCase;
  final GetChallengeContributions getChallengeContributionsUseCase;
  final DeleteContribution deleteContributionUseCase;
  final usecases.CreateChallengeInvites createChallengeInvitesUseCase;
  final GetMyInvites getMyInvitesUseCase;
  final AcceptInvite acceptInviteUseCase;
  final RejectInvite rejectInviteUseCase;
  final GetChallengeArchives getChallengeArchivesUseCase;
  final ChallengeRepository repository;

  StreamSubscription? _challengeSubscription;
  StreamSubscription? _contributionsSubscription;

  ChallengeBloc({
    required this.createChallengeUseCase,
    required this.joinChallengeUseCase,
    required this.joinChallengeByCodeUseCase,
    required this.submitWorkoutUseCase,
    required this.getAllChallengesUseCase,
    required this.getChallengeContributionsUseCase,
    required this.deleteContributionUseCase,
    required this.createChallengeInvitesUseCase,
    required this.getMyInvitesUseCase,
    required this.acceptInviteUseCase,
    required this.rejectInviteUseCase,
    required this.getChallengeArchivesUseCase,
    required this.repository,
  }) : super(const ChallengeInitial()) {
    on<LoadChallenges>(_onLoadChallenges);
    on<CreateChallengeEvent>(_onCreateChallenge);
    on<JoinChallengeEvent>(_onJoinChallenge);
    on<JoinChallengeByCode>(_onJoinChallengeByCode);
    on<LeaveChallenge>(_onLeaveChallenge);
    on<SubmitWorkout>(_onSubmitWorkout);
    on<LoadChallengeDetail>(_onLoadChallengeDetail);
    on<LoadChallengeContributions>(_onLoadChallengeContributions);
    on<WatchChallenge>(_onWatchChallenge);
    on<WatchContributions>(_onWatchContributions);
    on<DeleteChallenge>(_onDeleteChallenge);
    on<DeleteContributionEvent>(_onDeleteContribution);
    on<CreateChallengeInvites>(_onCreateChallengeInvites);
    on<LoadMyInvites>(_onLoadMyInvites);
    on<WatchMyInvites>(_onWatchMyInvites);
    on<AcceptInviteEvent>(_onAcceptInvite);
    on<RejectInviteEvent>(_onRejectInvite);
    on<LoadChallengeArchives>(_onLoadChallengeArchives);
  }

  /// 현재 상태에서 챌린지 목록 추출
  List<ChallengeEntity> _getCurrentChallenges() {
    if (state is ChallengesLoaded) {
      return (state as ChallengesLoaded).challenges;
    } else if (state is ChallengeDetailLoaded) {
      return (state as ChallengeDetailLoaded).challenges;
    } else if (state is WorkoutSubmitted) {
      return (state as WorkoutSubmitted).challenges;
    } else if (state is MyInvitesUpdated) {
      return (state as MyInvitesUpdated).challenges;
    }
    return [];
  }

  /// 현재 상태에서 초대 목록 추출
  List<ChallengeInviteEntity> _getCurrentInvites() {
    if (state is ChallengesLoaded) {
      return (state as ChallengesLoaded).invites;
    } else if (state is MyInvitesLoaded) {
      return (state as MyInvitesLoaded).invites;
    } else if (state is MyInvitesUpdated) {
      return (state as MyInvitesUpdated).invites;
    }
    return [];
  }

  Future<void> _onLoadChallenges(
    LoadChallenges event,
    Emitter<ChallengeState> emit,
  ) async {
    // 항상 로딩 상태 표시하여 새로고침 시에도 로딩 인디케이터 표시
    emit(const ChallengeLoading());

    AppLogger.info('ChallengeBloc', 'LoadChallenges 시작: userId=${event.userId}');
    final result = await getAllChallengesUseCase(event.userId);

    result.fold(
      (failure) {
        AppLogger.error('ChallengeBloc', 'LoadChallenges 실패: $failure');
        emit(ChallengeError(failure.toString()));
      },
      (challenges) {
        AppLogger.info('ChallengeBloc', 'LoadChallenges 성공: ${challenges.length}개');
        // 현재 초대 목록 유지
        final currentInvites = _getCurrentInvites();
        // 챌린지가 비어있어도 초대가 있으면 ChallengesLoaded 사용
        if (challenges.isEmpty && currentInvites.isEmpty) {
          emit(const ChallengeEmpty());
        } else {
          emit(ChallengesLoaded(challenges: challenges, invites: currentInvites));
        }
      },
    );
  }

  Future<void> _onCreateChallenge(
    CreateChallengeEvent event,
    Emitter<ChallengeState> emit,
  ) async {
    final result = await createChallengeUseCase(
      CreateChallengeParams(
        userId: event.userId,
        userNickname: event.userNickname,
        targetWeight: event.targetWeight,
        challengeDate: event.challengeDate,
        maxParticipants: event.maxParticipants,
      ),
    );

    result.fold(
      (failure) => emit(ChallengeError(failure.toString())),
      (challenge) {
        AppLogger.info('ChallengeBloc', 'Challenge created: ${challenge.id}');
        emit(ChallengeCreated(challenge));
      },
    );
  }

  Future<void> _onJoinChallenge(
    JoinChallengeEvent event,
    Emitter<ChallengeState> emit,
  ) async {
    final result = await joinChallengeUseCase(
      JoinChallengeParams(
        challengeId: event.challengeId,
        userId: event.userId,
        userNickname: event.userNickname,
      ),
    );

    result.fold(
      (failure) => emit(ChallengeError(failure.toString())),
      (_) {
        AppLogger.info('ChallengeBloc', 'Joined challenge: ${event.challengeId}');
        emit(ChallengeJoined(event.challengeId));
      },
    );
  }

  Future<void> _onJoinChallengeByCode(
    JoinChallengeByCode event,
    Emitter<ChallengeState> emit,
  ) async {
    emit(const ChallengeLoading());

    final result = await joinChallengeByCodeUseCase(
      JoinByCodeParams(
        inviteCode: event.inviteCode,
        userId: event.userId,
        userNickname: event.userNickname,
      ),
    );

    result.fold(
      (failure) => emit(ChallengeError(failure.toString())),
      (challenge) {
        AppLogger.info('ChallengeBloc', 'Joined challenge by code: ${challenge.id}');
        emit(ChallengeJoined(challenge.id));
      },
    );
  }

  Future<void> _onLeaveChallenge(
    LeaveChallenge event,
    Emitter<ChallengeState> emit,
  ) async {
    final result = await repository.leaveChallenge(
      challengeId: event.challengeId,
      userId: event.userId,
    );

    result.fold(
      (failure) => emit(ChallengeError(failure.toString())),
      (_) {
        AppLogger.info('ChallengeBloc', 'Left challenge: ${event.challengeId}');
        // 챌린지를 나갔음을 알리는 상태 발행 (상세 페이지에서 감지)
        emit(ChallengeDeleted(event.challengeId));
        // 챌린지 목록 새로고침
        add(LoadChallenges(event.userId));
      },
    );
  }

  Future<void> _onSubmitWorkout(
    SubmitWorkout event,
    Emitter<ChallengeState> emit,
  ) async {
    // 현재 상태에서 챌린지 정보 추출
    ChallengeEntity? currentChallenge;
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
      (failure) => emit(ChallengeError(failure.toString())),
      (contribution) {
        if (currentChallenge != null) {
          emit(WorkoutSubmitted(
            contribution: contribution,
            challenge: currentChallenge,
            challenges: challenges,
          ));
        } else {
          emit(const ChallengeError('챌린지 정보를 찾을 수 없습니다'));
        }
      },
    );
  }

  Future<void> _onLoadChallengeDetail(
    LoadChallengeDetail event,
    Emitter<ChallengeState> emit,
  ) async {
    // 이전 목록 상태 유지
    final previousChallenges = _getCurrentChallenges();

    final challengeResult = await repository.getChallengeById(event.challengeId);
    final contributionsResult = await getChallengeContributionsUseCase(event.challengeId);

    await challengeResult.fold(
      (failure) async => emit(ChallengeError(failure.toString())),
      (challenge) async {
        await contributionsResult.fold(
          (failure) async => emit(ChallengeError(failure.toString())),
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
    Emitter<ChallengeState> emit,
  ) async {
    final result = await getChallengeContributionsUseCase(event.challengeId);

    result.fold(
      (failure) => emit(ChallengeError(failure.toString())),
      (contributions) => emit(ContributionsUpdated(contributions)),
    );
  }

  Future<void> _onWatchChallenge(
    WatchChallenge event,
    Emitter<ChallengeState> emit,
  ) async {
    await _challengeSubscription?.cancel();

    await emit.forEach<Either<Failure, ChallengeEntity>>(
      repository.watchChallenge(event.challengeId),
      onData: (result) {
        return result.fold(
          (failure) => state,
          (challenge) {
            List<ContributionEntity> currentContributions = [];
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
    Emitter<ChallengeState> emit,
  ) async {
    await _contributionsSubscription?.cancel();

    await emit.forEach<Either<Failure, List<ContributionEntity>>>(
      repository.watchContributions(event.challengeId),
      onData: (result) {
        return result.fold(
          (failure) => state,
          (contributions) {
            ChallengeEntity? currentChallenge;
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
    Emitter<ChallengeState> emit,
  ) async {
    final result = await repository.deleteChallenge(
      challengeId: event.challengeId,
      userId: event.userId,
    );

    result.fold(
      (failure) => emit(ChallengeError(failure.toString())),
      (_) {
        AppLogger.info('ChallengeBloc', 'Challenge deleted: ${event.challengeId}');
        emit(ChallengeDeleted(event.challengeId));
      },
    );
  }

  Future<void> _onDeleteContribution(
    DeleteContributionEvent event,
    Emitter<ChallengeState> emit,
  ) async {
    final result = await deleteContributionUseCase(
      DeleteContributionParams(
        challengeId: event.challengeId,
        contributionId: event.contributionId,
        userId: event.userId,
      ),
    );

    result.fold(
      (failure) => emit(ChallengeError(failure.toString())),
      (_) {
        AppLogger.info('ChallengeBloc', 'Contribution deleted: ${event.contributionId}');
        emit(ContributionDeleted(
          contributionId: event.contributionId,
          challengeId: event.challengeId,
        ));
      },
    );
  }

  Future<void> _onCreateChallengeInvites(
    CreateChallengeInvites event,
    Emitter<ChallengeState> emit,
  ) async {
    AppLogger.info('ChallengeBloc', 'Creating invites for ${event.inviteeIds.length} friends');

    final result = await createChallengeInvitesUseCase(
      usecases.CreateChallengeInvitesParams(
        challengeId: event.challengeId,
        challengeName: event.challengeName,
        inviterId: event.inviterId,
        inviterNickname: event.inviterNickname,
        inviteeIds: event.inviteeIds,
        targetWeight: event.targetWeight,
        startDate: event.startDate,
        endDate: event.endDate,
        participantCount: event.participantCount,
      ),
    );

    result.fold(
      (failure) => emit(ChallengeError(failure.toString())),
      (_) {
        AppLogger.info('ChallengeBloc', 'Invites created successfully');
        emit(ChallengeInvitesCreated(event.inviteeIds.length));
      },
    );
  }

  Future<void> _onLoadMyInvites(
    LoadMyInvites event,
    Emitter<ChallengeState> emit,
  ) async {
    final result = await getMyInvitesUseCase(event.userId);

    result.fold(
      (failure) => emit(ChallengeError(failure.toString())),
      (invites) {
        AppLogger.info('ChallengeBloc', 'Loaded ${invites.length} invites');
        emit(MyInvitesLoaded(invites));
      },
    );
  }

  Future<void> _onWatchMyInvites(
    WatchMyInvites event,
    Emitter<ChallengeState> emit,
  ) async {
    await emit.forEach<Either<Failure, List<ChallengeInviteEntity>>>(
      repository.watchMyInvites(event.userId),
      onData: (either) {
        return either.fold(
          (failure) {
            AppLogger.error('ChallengeBloc', 'Failed to watch invites', failure);
            return ChallengeError(failure.toString());
          },
          (invites) {
            AppLogger.info('ChallengeBloc', 'Invites updated: ${invites.length} invites');
            // 현재 챌린지 목록 유지
            final currentChallenges = _getCurrentChallenges();
            return MyInvitesUpdated(invites, challenges: currentChallenges);
          },
        );
      },
      onError: (error, stackTrace) {
        AppLogger.error('ChallengeBloc', 'Error watching invites', error, stackTrace);
        return ChallengeError(error.toString());
      },
    );
  }

  Future<void> _onAcceptInvite(
    AcceptInviteEvent event,
    Emitter<ChallengeState> emit,
  ) async {
    final result = await acceptInviteUseCase(
      AcceptInviteParams(
        inviteId: event.inviteId,
        challengeId: event.challengeId,
        userId: event.userId,
        userNickname: event.userNickname,
      ),
    );

    result.fold(
      (failure) => emit(ChallengeError(failure.toString())),
      (_) {
        AppLogger.info('ChallengeBloc', 'Invite accepted: ${event.inviteId}');
        emit(InviteAccepted(inviteId: event.inviteId, challengeId: event.challengeId));
      },
    );
  }

  Future<void> _onRejectInvite(
    RejectInviteEvent event,
    Emitter<ChallengeState> emit,
  ) async {
    final result = await rejectInviteUseCase(
      RejectInviteParams(
        inviteId: event.inviteId,
        challengeId: event.challengeId,
      ),
    );

    result.fold(
      (failure) => emit(ChallengeError(failure.toString())),
      (_) {
        AppLogger.info('ChallengeBloc', 'Invite rejected: ${event.inviteId}');
        emit(InviteRejected(event.inviteId));
      },
    );
  }

  Future<void> _onLoadChallengeArchives(
    LoadChallengeArchives event,
    Emitter<ChallengeState> emit,
  ) async {
    final result = await getChallengeArchivesUseCase(event.userId);

    result.fold(
      (failure) => emit(ChallengeError(failure.toString())),
      (archives) {
        final currentChallenges = _getCurrentChallenges();
        AppLogger.info('ChallengeBloc', 'Loaded ${archives.length} archives');
        emit(ChallengeArchivesLoaded(
          archives: archives,
          challenges: currentChallenges,
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
