import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';

/// 통나무런 챌린지 모델
class LogRunChallengeModel extends LogRunChallengeEntity {
  const LogRunChallengeModel({
    required super.id,
    required super.createdBy,
    required super.creatorName,
    required super.targetWeight,
    required super.targetDistance,
    required super.currentDistance,
    required super.remainingWeight,
    required super.participants,
    required super.participantNames,
    required super.status,
    required super.createdAt,
    required super.inviteCode,
    super.expiresAt,
    super.recordTimeLimit,
    super.allowFutureRecordsOnly,
    super.maxParticipants,
  });

  /// Firestore 문서에서 모델 생성
  factory LogRunChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LogRunChallengeModel(
      id: doc.id,
      createdBy: data['createdBy'] as String,
      creatorName: data['creatorName'] as String,
      targetWeight: (data['targetWeight'] as num).toDouble(),
      targetDistance: (data['targetDistance'] as num).toDouble(),
      currentDistance: (data['currentDistance'] as num?)?.toDouble() ?? 0.0,
      remainingWeight: (data['remainingWeight'] as num?)?.toDouble() ?? (data['targetWeight'] as num).toDouble(),
      participants: List<String>.from(data['participants'] as List),
      participantNames: Map<String, String>.from(data['participantNames'] as Map),
      status: ChallengeStatusExtension.fromFirestore(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      inviteCode: data['inviteCode'] as String,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      recordTimeLimit: data['recordTimeLimit'] as int? ?? 7,
      allowFutureRecordsOnly: data['allowFutureRecordsOnly'] as bool? ?? false,
      maxParticipants: data['maxParticipants'] as int?,
    );
  }

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'createdBy': createdBy,
      'creatorName': creatorName,
      'targetWeight': targetWeight,
      'targetDistance': targetDistance,
      'currentDistance': currentDistance,
      'remainingWeight': remainingWeight,
      'participants': participants,
      'participantNames': participantNames,
      'status': status.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'inviteCode': inviteCode,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'recordTimeLimit': recordTimeLimit,
      'allowFutureRecordsOnly': allowFutureRecordsOnly,
      'maxParticipants': maxParticipants,
    };
  }

  /// 엔티티를 모델로 변환
  factory LogRunChallengeModel.fromEntity(LogRunChallengeEntity entity) {
    return LogRunChallengeModel(
      id: entity.id,
      createdBy: entity.createdBy,
      creatorName: entity.creatorName,
      targetWeight: entity.targetWeight,
      targetDistance: entity.targetDistance,
      currentDistance: entity.currentDistance,
      remainingWeight: entity.remainingWeight,
      participants: entity.participants,
      participantNames: entity.participantNames,
      status: entity.status,
      createdAt: entity.createdAt,
      inviteCode: entity.inviteCode,
      expiresAt: entity.expiresAt,
      recordTimeLimit: entity.recordTimeLimit,
      allowFutureRecordsOnly: entity.allowFutureRecordsOnly,
      maxParticipants: entity.maxParticipants,
    );
  }
}
