import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_event.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_state.dart';
import 'package:co_workfit/features/social/domain/usecases/get_leaderboard.dart';
import 'package:co_workfit/features/social/domain/usecases/get_friends_leaderboard.dart';

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final GetLeaderboard getLeaderboard;
  final GetFriendsLeaderboard getFriendsLeaderboard;

  LeaderboardBloc({
    required this.getLeaderboard,
    required this.getFriendsLeaderboard,
  }) : super(const LeaderboardInitial()) {
    on<LoadGlobalLeaderboard>(_onLoadGlobalLeaderboard);
    on<LoadFriendsLeaderboard>(_onLoadFriendsLeaderboard);
    on<RefreshGlobalLeaderboard>(_onRefreshGlobalLeaderboard);
    on<RefreshFriendsLeaderboard>(_onRefreshFriendsLeaderboard);
    on<ChangeLeaderboardType>(_onChangeLeaderboardType);
  }

  Future<void> _onLoadGlobalLeaderboard(
    LoadGlobalLeaderboard event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());

    final result = await getLeaderboard(type: event.type);

    result.fold(
      (failure) => emit(LeaderboardError(failure.message)),
      (leaderboard) => emit(LeaderboardLoaded(
        globalLeaderboard: leaderboard,
        currentType: event.type,
      )),
    );
  }

  Future<void> _onLoadFriendsLeaderboard(
    LoadFriendsLeaderboard event,
    Emitter<LeaderboardState> emit,
  ) async {
    final currentState = state;

    final result = await getFriendsLeaderboard(
      userId: event.userId,
      type: event.type,
    );

    result.fold(
      (failure) {
        if (currentState is LeaderboardLoaded) {
          emit(LeaderboardError(failure.message, previousState: currentState));
        } else {
          emit(LeaderboardError(failure.message));
        }
      },
      (leaderboard) {
        if (currentState is LeaderboardLoaded) {
          emit(currentState.copyWith(
            friendsLeaderboard: leaderboard,
            currentType: event.type,
          ));
        } else {
          emit(LeaderboardLoaded(
            friendsLeaderboard: leaderboard,
            currentType: event.type,
          ));
        }
      },
    );
  }

  Future<void> _onRefreshGlobalLeaderboard(
    RefreshGlobalLeaderboard event,
    Emitter<LeaderboardState> emit,
  ) async {
    final currentState = state;

    final result = await getLeaderboard(type: event.type);

    result.fold(
      (failure) {
        if (currentState is LeaderboardLoaded) {
          emit(LeaderboardError(failure.message, previousState: currentState));
        } else {
          emit(LeaderboardError(failure.message));
        }
      },
      (leaderboard) {
        if (currentState is LeaderboardLoaded) {
          emit(currentState.copyWith(
            globalLeaderboard: leaderboard,
            currentType: event.type,
          ));
        } else {
          emit(LeaderboardLoaded(
            globalLeaderboard: leaderboard,
            currentType: event.type,
          ));
        }
      },
    );
  }

  Future<void> _onRefreshFriendsLeaderboard(
    RefreshFriendsLeaderboard event,
    Emitter<LeaderboardState> emit,
  ) async {
    final currentState = state;

    final result = await getFriendsLeaderboard(
      userId: event.userId,
      type: event.type,
    );

    result.fold(
      (failure) {
        if (currentState is LeaderboardLoaded) {
          emit(LeaderboardError(failure.message, previousState: currentState));
        } else {
          emit(LeaderboardError(failure.message));
        }
      },
      (leaderboard) {
        if (currentState is LeaderboardLoaded) {
          emit(currentState.copyWith(
            friendsLeaderboard: leaderboard,
            currentType: event.type,
          ));
        } else {
          emit(LeaderboardLoaded(
            friendsLeaderboard: leaderboard,
            currentType: event.type,
          ));
        }
      },
    );
  }

  Future<void> _onChangeLeaderboardType(
    ChangeLeaderboardType event,
    Emitter<LeaderboardState> emit,
  ) async {
    final currentState = state;

    if (currentState is LeaderboardLoaded) {
      emit(currentState.copyWith(currentType: event.type));
    }
  }
}
