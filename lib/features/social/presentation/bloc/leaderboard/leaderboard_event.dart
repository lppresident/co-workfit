import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadGlobalLeaderboard extends LeaderboardEvent {
  final LeaderboardType type;

  const LoadGlobalLeaderboard({this.type = LeaderboardType.allTime});

  @override
  List<Object?> get props => [type];
}

class LoadFriendsLeaderboard extends LeaderboardEvent {
  final String userId;
  final LeaderboardType type;

  const LoadFriendsLeaderboard({
    required this.userId,
    this.type = LeaderboardType.allTime,
  });

  @override
  List<Object?> get props => [userId, type];
}

class RefreshGlobalLeaderboard extends LeaderboardEvent {
  final LeaderboardType type;

  const RefreshGlobalLeaderboard({this.type = LeaderboardType.allTime});

  @override
  List<Object?> get props => [type];
}

class RefreshFriendsLeaderboard extends LeaderboardEvent {
  final String userId;
  final LeaderboardType type;

  const RefreshFriendsLeaderboard({
    required this.userId,
    this.type = LeaderboardType.allTime,
  });

  @override
  List<Object?> get props => [userId, type];
}

class ChangeLeaderboardType extends LeaderboardEvent {
  final LeaderboardType type;

  const ChangeLeaderboardType(this.type);

  @override
  List<Object?> get props => [type];
}
