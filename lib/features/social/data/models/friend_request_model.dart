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
    required super.receiverId,
    required super.status,
    required super.createdAt,
    super.respondedAt,
    super.senderName,
    super.senderEmail,
    super.senderPhotoUrl,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendRequestModelToJson(this);

  factory FriendRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequestModel(
      id: doc.id,
      senderId: data['senderId'] as String,
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

  /// Firestore에서 가져온 데이터에 sender 정보를 추가하여 생성
  factory FriendRequestModel.fromFirestoreWithSender(
    DocumentSnapshot doc,
    Map<String, dynamic> senderData,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequestModel(
      id: doc.id,
      senderId: data['senderId'] as String,
      receiverId: data['receiverId'] as String,
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      senderName: senderData['displayName'] as String?,
      senderEmail: senderData['email'] as String?,
      senderPhotoUrl: senderData['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
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
      receiverId: entity.receiverId,
      status: entity.status,
      createdAt: entity.createdAt,
      respondedAt: entity.respondedAt,
      senderName: entity.senderName,
      senderEmail: entity.senderEmail,
      senderPhotoUrl: entity.senderPhotoUrl,
    );
  }

  @override
  FriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? senderName,
    String? senderEmail,
    String? senderPhotoUrl,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
    );
  }
}
