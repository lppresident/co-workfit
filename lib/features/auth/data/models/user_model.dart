import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// User 데이터 모델
@JsonSerializable()
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.displayName,
    super.photoUrl,
    super.totalScore,
    super.workoutCount,
    required super.createdAt,
    super.lastActiveAt,
  });

  /// JSON으로부터 UserModel 생성
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// UserModel을 JSON으로 변환
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Firestore DocumentSnapshot으로부터 UserModel 생성
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      photoUrl: data['photoUrl'] as String?,
      totalScore: (data['totalScore'] as num?)?.toInt() ?? 0,
      workoutCount: (data['workoutCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// UserModel을 Firestore용 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'totalScore': totalScore,
      'workoutCount': workoutCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }

  /// UserEntity로부터 UserModel 생성
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      totalScore: entity.totalScore,
      workoutCount: entity.workoutCount,
      createdAt: entity.createdAt,
      lastActiveAt: entity.lastActiveAt,
    );
  }

  /// Firebase Auth User로부터 UserModel 생성
  factory UserModel.fromFirebaseUser(
    String uid,
    String email,
    String? displayName,
    String? photoUrl,
  ) {
    return UserModel(
      id: uid,
      email: email,
      displayName: displayName ?? email.split('@')[0],
      photoUrl: photoUrl,
      totalScore: 0,
      workoutCount: 0,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );
  }

  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    int? totalScore,
    int? workoutCount,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      totalScore: totalScore ?? this.totalScore,
      workoutCount: workoutCount ?? this.workoutCount,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
