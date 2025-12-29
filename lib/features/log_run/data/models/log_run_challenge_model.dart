import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';

/// 통나무런 챌린지 모델
class LogRunChallengeModel extends LogRunChallengeEntity {
  const LogRunChallengeModel({
    required super.id,
    required super.createdBy,
    required super.targetWeight,
    required super.targetDistance,
    required super.currentDistance,
    required super.remainingWeight,
    required super.participants,
    required super.status,
    required super.createdAt,
    required super.startDate,
    required super.endDate,
    required super.inviteCode,
    super.completedAt,
    super.expireAt,
    super.maxParticipants,
    super.scoreAwarded,
    super.awardedScores,
  });

  /// Firestore 문서에서 모델 생성
  factory LogRunChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = (data['createdAt'] as Timestamp).toDate();

    return LogRunChallengeModel(
      id: doc.id,
      createdBy: data['createdBy'] as String,
      targetWeight: (data['targetWeight'] as num).toDouble(),
      targetDistance: (data['targetDistance'] as num).toDouble(),
      currentDistance: (data['currentDistance'] as num?)?.toDouble() ?? 0.0,
      remainingWeight: (data['remainingWeight'] as num?)?.toDouble() ?? (data['targetWeight'] as num).toDouble(),
      participants: List<String>.from(data['participants'] as List),
      status: ChallengeStatusExtension.fromFirestore(data['status'] as String),
      createdAt: createdAt,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : createdAt, // 기존 데이터 호환: startDate 없으면 createdAt 사용
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : createdAt.add(const Duration(days: 30)), // 기존 데이터 호환: endDate 없으면 30일 후
      inviteCode: data['inviteCode'] as String,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      expireAt: data['expireAt'] != null
          ? (data['expireAt'] as Timestamp).toDate()
          : null,
      maxParticipants: data['maxParticipants'] as int?,
      scoreAwarded: data['scoreAwarded'] as bool? ?? false,
      awardedScores: data['awardedScores'] != null
          ? Map<String, int>.from(
              (data['awardedScores'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, (value as num).toInt()),
              ),
            )
          : const {},
    );
  }

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'createdBy': createdBy,
      'targetWeight': targetWeight,
      'targetDistance': targetDistance,
      'currentDistance': currentDistance,
      'remainingWeight': remainingWeight,
      'participants': participants,
      'status': status.toFirestore(),
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'inviteCode': inviteCode,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'expireAt': expireAt != null ? Timestamp.fromDate(expireAt!) : null,
      'maxParticipants': maxParticipants,
      'scoreAwarded': scoreAwarded,
      'awardedScores': awardedScores,
    };
  }

  /// 엔티티를 모델로 변환
  factory LogRunChallengeModel.fromEntity(LogRunChallengeEntity entity) {
    return LogRunChallengeModel(
      id: entity.id,
      createdBy: entity.createdBy,
      targetWeight: entity.targetWeight,
      targetDistance: entity.targetDistance,
      currentDistance: entity.currentDistance,
      remainingWeight: entity.remainingWeight,
      participants: entity.participants,
      status: entity.status,
      createdAt: entity.createdAt,
      startDate: entity.startDate,
      endDate: entity.endDate,
      inviteCode: entity.inviteCode,
      completedAt: entity.completedAt,
      expireAt: entity.expireAt,
      maxParticipants: entity.maxParticipants,
      scoreAwarded: entity.scoreAwarded,
      awardedScores: entity.awardedScores,
    );
  }
}
