import 'package:equatable/equatable.dart';

/// 친구 요청 상태
enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

/// 친구 요청 엔티티
///
/// senderId와 receiverId(userId)를 저장하고,
/// UI 표시를 위해 보낸 사람의 정보도 함께 포함
class FriendRequestEntity extends Equatable {
  final String id;
  final String senderId; // 보낸 사람의 userId
  final String receiverId; // 받는 사람의 userId
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  // 보낸 사람의 정보 (UI 표시용)
  final String? senderName;
  final String? senderNickname;
  final String? senderEmail;
  final String? senderPhotoUrl;

  const FriendRequestEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.senderName,
    this.senderNickname,
    this.senderEmail,
    this.senderPhotoUrl,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        status,
        createdAt,
        respondedAt,
        senderName,
        senderNickname,
        senderEmail,
        senderPhotoUrl,
      ];

  FriendRequestEntity copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? senderName,
    String? senderNickname,
    String? senderEmail,
    String? senderPhotoUrl,
  }) {
    return FriendRequestEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      senderName: senderName ?? this.senderName,
      senderNickname: senderNickname ?? this.senderNickname,
      senderEmail: senderEmail ?? this.senderEmail,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
    );
  }
}
