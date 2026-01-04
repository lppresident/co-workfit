import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/data/models/participant_stats_model.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/participant_stats_entity.dart';

/// 챌린지 모델
class LogRunChallengeModel extends LogRunChallengeEntity {
  const LogRunChallengeModel({
    required super.id,
    required super.createdBy,
    required super.targetWeight,
    required super.currentWeight,
    required super.remainingWeight,
    required super.participants,
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
  });

  /// Firestore 문서에서 모델 생성
  factory LogRunChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = (data['createdAt'] as Timestamp).toDate();

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

    return LogRunChallengeModel(
      id: doc.id,
      createdBy: data['createdBy'] as String,
      targetWeight: (data['targetWeight'] as num).toDouble(),
      currentWeight: (data['currentWeight'] as num?)?.toDouble() ??
                     (data['currentDistance'] as num?)?.toDouble() ?? 0.0, // 기존 데이터 호환
      remainingWeight: (data['remainingWeight'] as num?)?.toDouble() ?? (data['targetWeight'] as num).toDouble(),
      participants: List<String>.from(data['participants'] as List),
      participantStats: participantStats,
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
      'currentWeight': currentWeight,
      'remainingWeight': remainingWeight,
      'participants': participants,
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
    };
  }

  /// 엔티티를 모델로 변환
  factory LogRunChallengeModel.fromEntity(LogRunChallengeEntity entity) {
    return LogRunChallengeModel(
      id: entity.id,
      createdBy: entity.createdBy,
      targetWeight: entity.targetWeight,
      currentWeight: entity.currentWeight,
      remainingWeight: entity.remainingWeight,
      participants: entity.participants,
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
    );
  }

  /// 일부 필드만 변경한 새 인스턴스 생성
  LogRunChallengeModel copyWith({
    String? id,
    String? createdBy,
    double? targetWeight,
    double? currentWeight,
    double? remainingWeight,
    List<String>? participants,
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
  }) {
    return LogRunChallengeModel(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      targetWeight: targetWeight ?? this.targetWeight,
      currentWeight: currentWeight ?? this.currentWeight,
      remainingWeight: remainingWeight ?? this.remainingWeight,
      participants: participants ?? this.participants,
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
    );
  }
}
