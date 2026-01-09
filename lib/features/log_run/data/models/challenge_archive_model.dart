import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_archive_entity.dart';

/// 챌린지 아카이브 모델
class ChallengeArchiveModel extends ChallengeArchiveEntity {
  const ChallengeArchiveModel({
    required super.challengeId,
    required super.isSuccess,
    required super.targetWeight,
    required super.endDate,
    required super.archivedAt,
  });

  /// Firestore 문서에서 생성
  factory ChallengeArchiveModel.fromFirestore(Map<String, dynamic> data) {
    return ChallengeArchiveModel(
      challengeId: data['challengeId'] as String,
      isSuccess: data['isSuccess'] as bool,
      targetWeight: (data['targetWeight'] as num).toDouble(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      archivedAt: (data['archivedAt'] as Timestamp).toDate(),
    );
  }

  /// Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'isSuccess': isSuccess,
      'targetWeight': targetWeight,
      'endDate': Timestamp.fromDate(endDate),
      'archivedAt': Timestamp.fromDate(archivedAt),
    };
  }

  /// Entity에서 생성
  factory ChallengeArchiveModel.fromEntity(ChallengeArchiveEntity entity) {
    return ChallengeArchiveModel(
      challengeId: entity.challengeId,
      isSuccess: entity.isSuccess,
      targetWeight: entity.targetWeight,
      endDate: entity.endDate,
      archivedAt: entity.archivedAt,
    );
  }
}
