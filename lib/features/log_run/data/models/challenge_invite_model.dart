import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_invite_entity.dart';

/// 챌린지 초대 Model
class ChallengeInviteModel extends ChallengeInviteEntity {
  const ChallengeInviteModel({
    required super.id,
    required super.challengeId,
    required super.challengeName,
    required super.inviterId,
    required super.inviterNickname,
    required super.inviteeId,
    required super.createdAt,
    required super.status,
    required super.targetWeight,
    required super.startDate,
    required super.endDate,
    required super.participantCount,
  });

  /// Firestore DocumentSnapshot에서 생성
  factory ChallengeInviteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChallengeInviteModel(
      id: doc.id,
      challengeId: data['challengeId'] ?? '',
      challengeName: data['challengeName'] ?? '',
      inviterId: data['inviterId'] ?? '',
      inviterNickname: data['inviterNickname'] ?? '',
      inviteeId: data['inviteeId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      targetWeight: (data['targetWeight'] ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      participantCount: data['participantCount'] ?? 0,
    );
  }

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'challengeName': challengeName,
      'inviterId': inviterId,
      'inviterNickname': inviterNickname,
      'inviteeId': inviteeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'targetWeight': targetWeight,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'participantCount': participantCount,
    };
  }

  /// Entity에서 생성
  factory ChallengeInviteModel.fromEntity(ChallengeInviteEntity entity) {
    return ChallengeInviteModel(
      id: entity.id,
      challengeId: entity.challengeId,
      challengeName: entity.challengeName,
      inviterId: entity.inviterId,
      inviterNickname: entity.inviterNickname,
      inviteeId: entity.inviteeId,
      createdAt: entity.createdAt,
      status: entity.status,
      targetWeight: entity.targetWeight,
      startDate: entity.startDate,
      endDate: entity.endDate,
      participantCount: entity.participantCount,
    );
  }

  /// Entity로 변환
  ChallengeInviteEntity toEntity() {
    return ChallengeInviteEntity(
      id: id,
      challengeId: challengeId,
      challengeName: challengeName,
      inviterId: inviterId,
      inviterNickname: inviterNickname,
      inviteeId: inviteeId,
      createdAt: createdAt,
      status: status,
      targetWeight: targetWeight,
      startDate: startDate,
      endDate: endDate,
      participantCount: participantCount,
    );
  }
}
