import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/social/domain/entities/friend_request_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'friend_request_model.g.dart';

/// FriendRequest 데이터 모델
@JsonSerializable()
class FriendRequestModel extends FriendRequestEntity {
  const FriendRequestModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    super.senderPhotoUrl,
    required super.receiverId,
    required super.status,
    required super.createdAt,
    super.respondedAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendRequestModelToJson(this);

  factory FriendRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequestModel(
      id: doc.id,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      receiverId: data['receiverId'] as String,
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  factory FriendRequestModel.fromEntity(FriendRequestEntity entity) {
    return FriendRequestModel(
      id: entity.id,
      senderId: entity.senderId,
      senderName: entity.senderName,
      senderPhotoUrl: entity.senderPhotoUrl,
      receiverId: entity.receiverId,
      status: entity.status,
      createdAt: entity.createdAt,
      respondedAt: entity.respondedAt,
    );
  }

  @override
  FriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendRequestModel(
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
