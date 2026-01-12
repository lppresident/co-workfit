import 'package:co_workfit/features/log_run/domain/entities/participant_stats_entity.dart';

/// 참가자 통계 모델 (Firestore 직렬화)
class ParticipantStatsModel extends ParticipantStatsEntity {
  const ParticipantStatsModel({
    required super.userId,
    super.totalContribution,
    super.runningContribution,
    super.strengthContribution,
    super.otherContribution,
    super.runningCount,
    super.strengthCount,
    super.otherCount,
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
      otherContribution:
          (json['otherContribution'] as num?)?.toDouble() ?? 0.0,
      runningCount: json['runningCount'] as int? ?? 0,
      strengthCount: json['strengthCount'] as int? ?? 0,
      otherCount: json['otherCount'] as int? ?? 0,
    );
  }

  /// Entity에서 모델 생성
  factory ParticipantStatsModel.fromEntity(ParticipantStatsEntity entity) {
    return ParticipantStatsModel(
      userId: entity.userId,
      totalContribution: entity.totalContribution,
      runningContribution: entity.runningContribution,
      strengthContribution: entity.strengthContribution,
      otherContribution: entity.otherContribution,
      runningCount: entity.runningCount,
      strengthCount: entity.strengthCount,
      otherCount: entity.otherCount,
    );
  }

  /// Firestore에 저장할 JSON 생성
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalContribution': totalContribution,
      'runningContribution': runningContribution,
      'strengthContribution': strengthContribution,
      'otherContribution': otherContribution,
      'runningCount': runningCount,
      'strengthCount': strengthCount,
      'otherCount': otherCount,
    };
  }

  /// Entity 복사본 생성
  @override
  ParticipantStatsModel copyWith({
    String? userId,
    double? totalContribution,
    double? runningContribution,
    double? strengthContribution,
    double? otherContribution,
    int? runningCount,
    int? strengthCount,
    int? otherCount,
  }) {
    return ParticipantStatsModel(
      userId: userId ?? this.userId,
      totalContribution: totalContribution ?? this.totalContribution,
      runningContribution: runningContribution ?? this.runningContribution,
      strengthContribution: strengthContribution ?? this.strengthContribution,
      otherContribution: otherContribution ?? this.otherContribution,
      runningCount: runningCount ?? this.runningCount,
      strengthCount: strengthCount ?? this.strengthCount,
      otherCount: otherCount ?? this.otherCount,
    );
  }

  /// 새로운 기여 추가
  @override
  ParticipantStatsModel addContribution({
    required double contributionKg,
    String workoutType = 'strength',
  }) {
    final isRunning = workoutType == 'running';
    final isOther = workoutType == 'other';

    return ParticipantStatsModel(
      userId: userId,
      totalContribution: totalContribution + contributionKg,
      runningContribution:
          isRunning ? runningContribution + contributionKg : runningContribution,
      strengthContribution: !isRunning && !isOther
          ? strengthContribution + contributionKg
          : strengthContribution,
      otherContribution: isOther
          ? otherContribution + contributionKg
          : otherContribution,
      runningCount: isRunning ? runningCount + 1 : runningCount,
      strengthCount: !isRunning && !isOther ? strengthCount + 1 : strengthCount,
      otherCount: isOther ? otherCount + 1 : otherCount,
    );
  }
}
