import 'package:equatable/equatable.dart';

/// 친구 관계 엔티티
class FriendshipEntity extends Equatable {
  final String id;
  final String userId;
  final String friendId;
  final String friendName;
  final String friendEmail;
  final String? friendPhotoUrl;
  final int friendTotalScore;
  final int friendWorkoutCount;
  final DateTime createdAt;

  const FriendshipEntity({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendName,
    required this.friendEmail,
    this.friendPhotoUrl,
    required this.friendTotalScore,
    required this.friendWorkoutCount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        friendId,
        friendName,
        friendEmail,
        friendPhotoUrl,
        friendTotalScore,
        friendWorkoutCount,
        createdAt,
      ];

  FriendshipEntity copyWith({
    String? id,
    String? userId,
    String? friendId,
    String? friendName,
    String? friendEmail,
    String? friendPhotoUrl,
    int? friendTotalScore,
    int? friendWorkoutCount,
    DateTime? createdAt,
  }) {
    return FriendshipEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      friendEmail: friendEmail ?? this.friendEmail,
      friendPhotoUrl: friendPhotoUrl ?? this.friendPhotoUrl,
      friendTotalScore: friendTotalScore ?? this.friendTotalScore,
      friendWorkoutCount: friendWorkoutCount ?? this.friendWorkoutCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
