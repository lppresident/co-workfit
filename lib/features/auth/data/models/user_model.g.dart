// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      nickname: json['nickname'] as String,
      isNicknameSet: json['isNicknameSet'] as bool? ?? false,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: json['lastActiveAt'] == null
          ? null
          : DateTime.parse(json['lastActiveAt'] as String),
      woodAmount: (json['woodAmount'] as num?)?.toInt() ?? 0,
      woodLifetimeEarned: (json['woodLifetimeEarned'] as num?)?.toInt() ?? 0,
      lastWoodSettlementDate: json['lastWoodSettlementDate'] as String?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'displayName': instance.displayName,
      'nickname': instance.nickname,
      'isNicknameSet': instance.isNicknameSet,
      'photoUrl': instance.photoUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastActiveAt': instance.lastActiveAt?.toIso8601String(),
      'woodAmount': instance.woodAmount,
      'woodLifetimeEarned': instance.woodLifetimeEarned,
      'lastWoodSettlementDate': instance.lastWoodSettlementDate,
    };
