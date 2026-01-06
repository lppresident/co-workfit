import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/data/models/participant_stats_model.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/participant_stats_entity.dart';

/// 챌린지 모델
class ChallengeModel extends ChallengeEntity {
  const ChallengeModel({
    required super.id,
    required super.createdBy,
    required super.targetWeight,
    required super.currentWeight,
    required super.remainingWeight,
    required super.participants,
    super.participantNicknames,
    super.participantStats,
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
    super.isSuccess,
  });

  /// Firestore 문서에서 모델 생성
  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // participantStats 파싱
    Map<String, ParticipantStatsEntity> participantStats = {};
    if (data['participantStats'] != null) {
      final statsData = data['participantStats'] as Map<String, dynamic>;
      participantStats = statsData.map(
        (key, value) => MapEntry(
          key,
          ParticipantStatsModel.fromJson(value as Map<String, dynamic>),
        ),
      );
    }

    // participantNicknames 파싱
    Map<String, String> participantNicknames = {};
    if (data['participantNicknames'] != null) {
      final nicknamesData = data['participantNicknames'] as Map<String, dynamic>;
      participantNicknames = nicknamesData.map(
        (key, value) => MapEntry(key, value as String? ?? ''),
      );
    }

    return ChallengeModel(
      id: doc.id,
      createdBy: data['createdBy'] as String? ?? '',
      targetWeight: (data['targetWeight'] as num?)?.toDouble() ?? 0.0,
      currentWeight: (data['currentWeight'] as num?)?.toDouble() ?? 0.0,
      remainingWeight: (data['remainingWeight'] as num?)?.toDouble() ?? 0.0,
      participants: List<String>.from(data['participants'] as List? ?? []),
      participantNicknames: participantNicknames,
      participantStats: participantStats,
      status: ChallengeStatusExtension.fromFirestore(data['status'] as String? ?? 'active'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      inviteCode: data['inviteCode'] as String? ?? '',
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
                (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
              ),
            )
          : const {},
      isSuccess: data['isSuccess'] as bool?,
    );
  }

  /// Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'createdBy': createdBy,
      'targetWeight': targetWeight,
      'currentWeight': currentWeight,
      'remainingWeight': remainingWeight,
      'participants': participants,
      'participantNicknames': participantNicknames,
      'participantStats': participantStats.map(
        (key, value) => MapEntry(key, ParticipantStatsModel.fromEntity(value).toJson()),
      ),
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
      'isSuccess': isSuccess,
    };
  }

  /// 엔티티를 모델로 변환
  factory ChallengeModel.fromEntity(ChallengeEntity entity) {
    return ChallengeModel(
      id: entity.id,
      createdBy: entity.createdBy,
      targetWeight: entity.targetWeight,
      currentWeight: entity.currentWeight,
      remainingWeight: entity.remainingWeight,
      participants: entity.participants,
      participantNicknames: entity.participantNicknames,
      participantStats: entity.participantStats,
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
      isSuccess: entity.isSuccess,
    );
  }

  /// 일부 필드만 변경한 새 인스턴스 생성
  ChallengeModel copyWith({
    String? id,
    String? createdBy,
    double? targetWeight,
    double? currentWeight,
    double? remainingWeight,
    List<String>? participants,
    Map<String, String>? participantNicknames,
    Map<String, ParticipantStatsEntity>? participantStats,
    ChallengeStatus? status,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    String? inviteCode,
    DateTime? completedAt,
    DateTime? expireAt,
    int? maxParticipants,
    bool? scoreAwarded,
    Map<String, int>? awardedScores,
    bool? isSuccess,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      targetWeight: targetWeight ?? this.targetWeight,
      currentWeight: currentWeight ?? this.currentWeight,
      remainingWeight: remainingWeight ?? this.remainingWeight,
      participants: participants ?? this.participants,
      participantNicknames: participantNicknames ?? this.participantNicknames,
      participantStats: participantStats ?? this.participantStats,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      inviteCode: inviteCode ?? this.inviteCode,
      completedAt: completedAt ?? this.completedAt,
      expireAt: expireAt ?? this.expireAt,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      scoreAwarded: scoreAwarded ?? this.scoreAwarded,
      awardedScores: awardedScores ?? this.awardedScores,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
