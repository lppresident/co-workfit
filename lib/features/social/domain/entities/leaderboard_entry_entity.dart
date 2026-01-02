import 'package:equatable/equatable.dart';

/// 리더보드 엔트리 타입
enum LeaderboardType {
  weekly,
  monthly,
  allTime;

  /// Get display name for UI
  String getDisplayName() {
    switch (this) {
      case LeaderboardType.allTime:
        return '전체 기간';
      case LeaderboardType.monthly:
        return '이번 달';
      case LeaderboardType.weekly:
        return '이번 주';
    }
  }

  /// Get number of days for this period (null for all-time)
  int? getDays() {
    switch (this) {
      case LeaderboardType.allTime:
        return null;
      case LeaderboardType.monthly:
        return 30;
      case LeaderboardType.weekly:
        return 7;
    }
  }
}

/// 리더보드 엔트리 엔티티
class LeaderboardEntryEntity extends Equatable {
  final String userId;
  final String displayName;
  final String? nickname;
  final String? photoUrl;
  final int totalScore;
  final int workoutCount;
  final int rank;
  final LeaderboardType type;
  final DateTime updatedAt;

  const LeaderboardEntryEntity({
    required this.userId,
    required this.displayName,
    this.nickname,
    this.photoUrl,
    required this.totalScore,
    required this.workoutCount,
    required this.rank,
    required this.type,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        userId,
        displayName,
        nickname,
        photoUrl,
        totalScore,
        workoutCount,
        rank,
        type,
        updatedAt,
      ];

  LeaderboardEntryEntity copyWith({
    String? userId,
    String? displayName,
    String? nickname,
    String? photoUrl,
    int? totalScore,
    int? workoutCount,
    int? rank,
    LeaderboardType? type,
    DateTime? updatedAt,
  }) {
    return LeaderboardEntryEntity(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname,
      photoUrl: photoUrl ?? this.photoUrl,
      totalScore: totalScore ?? this.totalScore,
      workoutCount: workoutCount ?? this.workoutCount,
      rank: rank ?? this.rank,
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
