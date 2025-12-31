import 'package:equatable/equatable.dart';

/// 사용자 엔티티
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String nickname;
  final bool isNicknameSet; // 사용자가 직접 닉네임을 설정했는지 여부
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  // 재화 정보
  final int woodAmount; // 현재 보유 통나무
  final int woodLifetimeEarned; // 누적 획득 통나무
  final String? lastWoodSettlementDate; // 마지막 정산 날짜 (yyyy-MM-dd)

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    required this.nickname,
    this.isNicknameSet = false,
    this.photoUrl,
    required this.createdAt,
    this.lastActiveAt,
    this.woodAmount = 0,
    this.woodLifetimeEarned = 0,
    this.lastWoodSettlementDate,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        nickname,
        isNicknameSet,
        photoUrl,
        createdAt,
        lastActiveAt,
        woodAmount,
        woodLifetimeEarned,
        lastWoodSettlementDate,
      ];

  UserEntity copyWith({
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
  }) {
    return UserEntity(
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
    );
  }
}
