import 'package:equatable/equatable.dart';

/// 참가자별 챌린지 기여 통계
///
/// 참가자가 챌린지에 기여한 운동 타입별 통계를 추적합니다.
/// 달리기/헬스 비율에 따라 재화 보상이 차등 지급됩니다.
class ParticipantStatsEntity extends Equatable {
  /// 참가자 ID
  final String userId;

  /// 총 기여량 (kg)
  final double totalContribution;

  /// 달리기 기여량 (kg)
  /// 1km = 1kg
  final double runningContribution;

  /// 헬스 기여량 (kg)
  /// 10점 = 1kg
  final double strengthContribution;

  /// 기타 운동 기여량 (kg)
  /// 10분 = 1kg
  final double otherContribution;

  /// 달리기 운동 횟수
  final int runningCount;

  /// 헬스 운동 횟수
  final int strengthCount;

  /// 기타 운동 횟수
  final int otherCount;

  const ParticipantStatsEntity({
    required this.userId,
    this.totalContribution = 0.0,
    this.runningContribution = 0.0,
    this.strengthContribution = 0.0,
    this.otherContribution = 0.0,
    this.runningCount = 0,
    this.strengthCount = 0,
    this.otherCount = 0,
  });

  /// 달리기 비율 (0.0 ~ 1.0)
  double get runningRatio =>
      totalContribution > 0 ? runningContribution / totalContribution : 0.0;

  /// 헬스 비율 (0.0 ~ 1.0)
  double get strengthRatio =>
      totalContribution > 0 ? strengthContribution / totalContribution : 0.0;

  /// 기타 운동 비율 (0.0 ~ 1.0)
  double get otherRatio =>
      totalContribution > 0 ? otherContribution / totalContribution : 0.0;

  /// 총 운동 횟수
  int get totalCount => runningCount + strengthCount + otherCount;

  /// 주력 운동 타입
  /// - 'running': 달리기가 50% 이상
  /// - 'strength': 헬스가 50% 이상
  /// - 'mixed': 복합 (양쪽 모두 25% 이상)
  String get primaryWorkoutType {
    if (runningRatio >= 0.75) return 'running';
    if (strengthRatio >= 0.75) return 'strength';
    if (runningRatio >= 0.25 && strengthRatio >= 0.25) return 'mixed';
    return runningRatio > strengthRatio ? 'running' : 'strength';
  }

  /// 운동 타입별 주력 여부 확인
  bool get isPrimaryRunning => primaryWorkoutType == 'running';
  bool get isPrimaryStrength => primaryWorkoutType == 'strength';
  bool get isMixed => primaryWorkoutType == 'mixed';

  @override
  List<Object?> get props => [
        userId,
        totalContribution,
        runningContribution,
        strengthContribution,
        otherContribution,
        runningCount,
        strengthCount,
        otherCount,
      ];

  ParticipantStatsEntity copyWith({
    String? userId,
    double? totalContribution,
    double? runningContribution,
    double? strengthContribution,
    double? otherContribution,
    int? runningCount,
    int? strengthCount,
    int? otherCount,
  }) {
    return ParticipantStatsEntity(
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

  /// 새로운 기여를 추가하여 통계 업데이트
  ///
  /// [workoutType]: 'running', 'strength', 'other' 중 하나
  ParticipantStatsEntity addContribution({
    required double contributionKg,
    String workoutType = 'strength',
  }) {
    final isRunning = workoutType == 'running';
    final isOther = workoutType == 'other';

    return ParticipantStatsEntity(
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

  /// 기여를 제거하여 통계 업데이트
  ///
  /// [workoutType]: 'running', 'strength', 'other' 중 하나
  ParticipantStatsEntity removeContribution({
    required double contributionKg,
    String workoutType = 'strength',
  }) {
    final isRunning = workoutType == 'running';
    final isOther = workoutType == 'other';

    return ParticipantStatsEntity(
      userId: userId,
      totalContribution: (totalContribution - contributionKg).clamp(0.0, double.infinity),
      runningContribution: isRunning
          ? (runningContribution - contributionKg).clamp(0.0, double.infinity)
          : runningContribution,
      strengthContribution: !isRunning && !isOther
          ? (strengthContribution - contributionKg).clamp(0.0, double.infinity)
          : strengthContribution,
      otherContribution: isOther
          ? (otherContribution - contributionKg).clamp(0.0, double.infinity)
          : otherContribution,
      runningCount: isRunning ? (runningCount - 1).clamp(0, runningCount) : runningCount,
      strengthCount: !isRunning && !isOther ? (strengthCount - 1).clamp(0, strengthCount) : strengthCount,
      otherCount: isOther ? (otherCount - 1).clamp(0, otherCount) : otherCount,
    );
  }

  /// 빈 통계 (초기값)
  static ParticipantStatsEntity empty(String userId) {
    return ParticipantStatsEntity(userId: userId);
  }
}
