import 'package:equatable/equatable.dart';

/// 챌린지 초대 엔티티
class ChallengeInviteEntity extends Equatable {
  final String id;
  final String challengeId;
  final String challengeName;
  final String inviterId;
  final String inviterNickname;
  final String inviteeId;
  final DateTime createdAt;
  final String status; // 'pending', 'accepted', 'rejected'

  // 챌린지 간략 정보
  final double targetWeight;
  final DateTime startDate;
  final DateTime endDate;
  final int participantCount;

  const ChallengeInviteEntity({
    required this.id,
    required this.challengeId,
    required this.challengeName,
    required this.inviterId,
    required this.inviterNickname,
    required this.inviteeId,
    required this.createdAt,
    required this.status,
    required this.targetWeight,
    required this.startDate,
    required this.endDate,
    required this.participantCount,
  });

  @override
  List<Object?> get props => [
        id,
        challengeId,
        challengeName,
        inviterId,
        inviterNickname,
        inviteeId,
        createdAt,
        status,
        targetWeight,
        startDate,
        endDate,
        participantCount,
      ];

  ChallengeInviteEntity copyWith({
    String? id,
    String? challengeId,
    String? challengeName,
    String? inviterId,
    String? inviterNickname,
    String? inviteeId,
    DateTime? createdAt,
    String? status,
    double? targetWeight,
    DateTime? startDate,
    DateTime? endDate,
    int? participantCount,
  }) {
    return ChallengeInviteEntity(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      challengeName: challengeName ?? this.challengeName,
      inviterId: inviterId ?? this.inviterId,
      inviterNickname: inviterNickname ?? this.inviterNickname,
      inviteeId: inviteeId ?? this.inviteeId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      targetWeight: targetWeight ?? this.targetWeight,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      participantCount: participantCount ?? this.participantCount,
    );
  }
}
