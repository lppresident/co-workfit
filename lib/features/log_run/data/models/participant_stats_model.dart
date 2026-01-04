import 'package:co_workfit/features/log_run/domain/entities/participant_stats_entity.dart';

/// 참가자 통계 모델 (Firestore 직렬화)
class ParticipantStatsModel extends ParticipantStatsEntity {
  const ParticipantStatsModel({
    required super.userId,
    super.totalContribution,
    super.runningContribution,
    super.strengthContribution,
    super.runningCount,
    super.strengthCount,
  });

  /// Firestore 문서에서 모델 생성
  factory ParticipantStatsModel.fromJson(Map<String, dynamic> json) {
    return ParticipantStatsModel(
      userId: json['userId'] as String,
      totalContribution: (json['totalContribution'] as num?)?.toDouble() ?? 0.0,
      runningContribution:
          (json['runningContribution'] as num?)?.toDouble() ?? 0.0,
      strengthContribution:
          (json['strengthContribution'] as num?)?.toDouble() ?? 0.0,
      runningCount: json['runningCount'] as int? ?? 0,
      strengthCount: json['strengthCount'] as int? ?? 0,
    );
  }

  /// Entity에서 모델 생성
  factory ParticipantStatsModel.fromEntity(ParticipantStatsEntity entity) {
    return ParticipantStatsModel(
      userId: entity.userId,
      totalContribution: entity.totalContribution,
      runningContribution: entity.runningContribution,
      strengthContribution: entity.strengthContribution,
      runningCount: entity.runningCount,
      strengthCount: entity.strengthCount,
    );
  }

  /// Firestore에 저장할 JSON 생성
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalContribution': totalContribution,
      'runningContribution': runningContribution,
      'strengthContribution': strengthContribution,
      'runningCount': runningCount,
      'strengthCount': strengthCount,
    };
  }

  /// Entity 복사본 생성
  @override
  ParticipantStatsModel copyWith({
    String? userId,
    double? totalContribution,
    double? runningContribution,
    double? strengthContribution,
    int? runningCount,
    int? strengthCount,
  }) {
    return ParticipantStatsModel(
      userId: userId ?? this.userId,
      totalContribution: totalContribution ?? this.totalContribution,
      runningContribution: runningContribution ?? this.runningContribution,
      strengthContribution: strengthContribution ?? this.strengthContribution,
      runningCount: runningCount ?? this.runningCount,
      strengthCount: strengthCount ?? this.strengthCount,
    );
  }

  /// 새로운 기여 추가
  @override
  ParticipantStatsModel addContribution({
    required double contributionKg,
    required bool isRunning,
  }) {
    return ParticipantStatsModel(
      userId: userId,
      totalContribution: totalContribution + contributionKg,
      runningContribution:
          isRunning ? runningContribution + contributionKg : runningContribution,
      strengthContribution: !isRunning
          ? strengthContribution + contributionKg
          : strengthContribution,
      runningCount: isRunning ? runningCount + 1 : runningCount,
      strengthCount: !isRunning ? strengthCount + 1 : strengthCount,
    );
  }
}
