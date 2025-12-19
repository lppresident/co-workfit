import 'package:equatable/equatable.dart';

/// 친구 요청 상태
enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

/// 친구 요청 엔티티
///
/// senderId와 receiverId(userId)만 저장하는 참조 구조
/// 보낸 사람의 실제 정보는 UI에서 users 컬렉션에서 조회
class FriendRequestEntity extends Equatable {
  final String id;
  final String senderId; // 보낸 사람의 userId
  final String receiverId; // 받는 사람의 userId
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const FriendRequestEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        status,
        createdAt,
        respondedAt,
      ];

  FriendRequestEntity copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendRequestEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
