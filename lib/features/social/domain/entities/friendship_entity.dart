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
  final String? friendNickname;
  final String? friendEmail;
  final String? friendPhotoUrl;

  const FriendshipEntity({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.createdAt,
    this.friendName,
    this.friendNickname,
    this.friendEmail,
    this.friendPhotoUrl,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        friendId,
        createdAt,
        friendName,
        friendNickname,
        friendEmail,
        friendPhotoUrl,
      ];

  FriendshipEntity copyWith({
    String? id,
    String? userId,
    String? friendId,
    DateTime? createdAt,
    String? friendName,
    String? friendNickname,
    String? friendEmail,
    String? friendPhotoUrl,
  }) {
    return FriendshipEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      createdAt: createdAt ?? this.createdAt,
      friendName: friendName ?? this.friendName,
      friendNickname: friendNickname ?? this.friendNickname,
      friendEmail: friendEmail ?? this.friendEmail,
      friendPhotoUrl: friendPhotoUrl ?? this.friendPhotoUrl,
    );
  }
}
