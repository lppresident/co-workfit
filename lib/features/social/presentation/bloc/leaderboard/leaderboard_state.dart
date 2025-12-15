import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';

abstract class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

class LeaderboardLoaded extends LeaderboardState {
  final List<LeaderboardEntryEntity> globalLeaderboard;
  final List<LeaderboardEntryEntity> friendsLeaderboard;
  final LeaderboardType currentType;

  const LeaderboardLoaded({
    this.globalLeaderboard = const [],
    this.friendsLeaderboard = const [],
    this.currentType = LeaderboardType.allTime,
  });

  @override
  List<Object?> get props => [globalLeaderboard, friendsLeaderboard, currentType];

  LeaderboardLoaded copyWith({
    List<LeaderboardEntryEntity>? globalLeaderboard,
    List<LeaderboardEntryEntity>? friendsLeaderboard,
    LeaderboardType? currentType,
  }) {
    return LeaderboardLoaded(
      globalLeaderboard: globalLeaderboard ?? this.globalLeaderboard,
      friendsLeaderboard: friendsLeaderboard ?? this.friendsLeaderboard,
      currentType: currentType ?? this.currentType,
    );
  }
}

class LeaderboardError extends LeaderboardState {
  final String message;
  final LeaderboardLoaded? previousState;

  const LeaderboardError(this.message, {this.previousState});

  @override
  List<Object?> get props => [message, previousState];
}
