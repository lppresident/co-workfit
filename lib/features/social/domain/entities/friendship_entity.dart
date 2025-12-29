import 'package:equatable/equatable.dart';

/// 친구 관계 엔티티
///
/// userId와 friendId를 저장하고,
/// UI 표시를 위해 친구의 정보도 함께 포함
class FriendshipEntity extends Equatable {
  final String id;
  final String userId;
  final String friendId; // 친구의 userId
  final DateTime createdAt;

  // 친구의 정보 (UI 표시용)
  final String? friendName;
  final String? friendEmail;
  final String? friendPhotoUrl;
  final int? friendTotalScore;
  final int? friendWorkoutCount;

  const FriendshipEntity({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.createdAt,
    this.friendName,
    this.friendEmail,
    this.friendPhotoUrl,
    this.friendTotalScore,
    this.friendWorkoutCount,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        friendId,
        createdAt,
        friendName,
        friendEmail,
        friendPhotoUrl,
        friendTotalScore,
        friendWorkoutCount,
      ];

  FriendshipEntity copyWith({
    String? id,
    String? userId,
    String? friendId,
    DateTime? createdAt,
    String? friendName,
    String? friendEmail,
    String? friendPhotoUrl,
    int? friendTotalScore,
    int? friendWorkoutCount,
  }) {
    return FriendshipEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      createdAt: createdAt ?? this.createdAt,
      friendName: friendName ?? this.friendName,
      friendEmail: friendEmail ?? this.friendEmail,
      friendPhotoUrl: friendPhotoUrl ?? this.friendPhotoUrl,
      friendTotalScore: friendTotalScore ?? this.friendTotalScore,
      friendWorkoutCount: friendWorkoutCount ?? this.friendWorkoutCount,
    );
  }
}
