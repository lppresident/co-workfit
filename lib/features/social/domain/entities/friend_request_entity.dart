import 'package:equatable/equatable.dart';

/// 친구 요청 상태
enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

/// 친구 요청 엔티티
class FriendRequestEntity extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const FriendRequestEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderName,
        senderPhotoUrl,
        receiverId,
        status,
        createdAt,
        respondedAt,
      ];

  FriendRequestEntity copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendRequestEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
