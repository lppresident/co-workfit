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
    required super.nickname,
    super.isNicknameSet,
    super.photoUrl,
    required super.createdAt,
    super.lastActiveAt,
    super.woodAmount,
    super.woodLifetimeEarned,
    super.lastWoodSettlementDate,
    super.ironAmount,
    super.ironLifetimeEarned,
    super.lastIronSettlementDate,
  });

  /// JSON으로부터 UserModel 생성
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// UserModel을 JSON으로 변환
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Firestore DocumentSnapshot으로부터 UserModel 생성
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final email = data['email'] as String;

    // 기존 사용자의 경우 nickname이 없을 수 있으므로 임시 닉네임 생성
    final nickname = data['nickname'] as String? ??
                     email.split('@')[0];
    final isNicknameSet = data['isNicknameSet'] as bool? ?? false;

    return UserModel(
      id: doc.id,
      email: email,
      displayName: data['displayName'] as String,
      nickname: nickname,
      isNicknameSet: isNicknameSet,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
      woodAmount: (data['woodAmount'] as num?)?.toInt() ?? 0,
      woodLifetimeEarned: (data['woodLifetimeEarned'] as num?)?.toInt() ?? 0,
      lastWoodSettlementDate: data['lastWoodSettlementDate'] as String?,
      ironAmount: (data['ironAmount'] as num?)?.toInt() ?? 0,
      ironLifetimeEarned: (data['ironLifetimeEarned'] as num?)?.toInt() ?? 0,
      lastIronSettlementDate: data['lastIronSettlementDate'] as String?,
    );
  }

  /// UserModel을 Firestore용 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'nickname': nickname,
      'isNicknameSet': isNicknameSet,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'woodAmount': woodAmount,
      'woodLifetimeEarned': woodLifetimeEarned,
      'lastWoodSettlementDate': lastWoodSettlementDate,
      'ironAmount': ironAmount,
      'ironLifetimeEarned': ironLifetimeEarned,
      'lastIronSettlementDate': lastIronSettlementDate,
    };
  }

  /// UserEntity로부터 UserModel 생성
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      nickname: entity.nickname,
      isNicknameSet: entity.isNicknameSet,
      photoUrl: entity.photoUrl,
      createdAt: entity.createdAt,
      lastActiveAt: entity.lastActiveAt,
      woodAmount: entity.woodAmount,
      woodLifetimeEarned: entity.woodLifetimeEarned,
      lastWoodSettlementDate: entity.lastWoodSettlementDate,
      ironAmount: entity.ironAmount,
      ironLifetimeEarned: entity.ironLifetimeEarned,
      lastIronSettlementDate: entity.lastIronSettlementDate,
    );
  }

  /// Firebase Auth User로부터 UserModel 생성
  factory UserModel.fromFirebaseUser(
    String uid,
    String email,
    String? displayName,
    String nickname,
    String? photoUrl, {
    bool isNicknameSet = false,
  }) {
    return UserModel(
      id: uid,
      email: email,
      displayName: displayName ?? email.split('@')[0],
      nickname: nickname,
      isNicknameSet: isNicknameSet,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      woodAmount: 0,
      woodLifetimeEarned: 0,
      lastWoodSettlementDate: null,
      ironAmount: 0,
      ironLifetimeEarned: 0,
      lastIronSettlementDate: null,
    );
  }

  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? nickname,
    bool? isNicknameSet,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    int? woodAmount,
    int? woodLifetimeEarned,
    String? lastWoodSettlementDate,
    int? ironAmount,
    int? ironLifetimeEarned,
    String? lastIronSettlementDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname,
      isNicknameSet: isNicknameSet ?? this.isNicknameSet,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      woodAmount: woodAmount ?? this.woodAmount,
      woodLifetimeEarned: woodLifetimeEarned ?? this.woodLifetimeEarned,
      lastWoodSettlementDate: lastWoodSettlementDate ?? this.lastWoodSettlementDate,
      ironAmount: ironAmount ?? this.ironAmount,
      ironLifetimeEarned: ironLifetimeEarned ?? this.ironLifetimeEarned,
      lastIronSettlementDate: lastIronSettlementDate ?? this.lastIronSettlementDate,
    );
  }
}
