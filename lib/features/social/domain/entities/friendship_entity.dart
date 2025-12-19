import 'package:equatable/equatable.dart';

/// 친구 관계 엔티티
///
/// userId와 friendId(userId)만 저장하는 참조 구조
/// 친구의 실제 정보는 UI에서 users 컬렉션에서 조회
class FriendshipEntity extends Equatable {
  final String id;
  final String userId;
  final String friendId; // 친구의 userId
  final DateTime createdAt;

  const FriendshipEntity({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        friendId,
        createdAt,
      ];

  FriendshipEntity copyWith({
    String? id,
    String? userId,
    String? friendId,
    DateTime? createdAt,
  }) {
    return FriendshipEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
