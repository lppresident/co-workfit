import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

/// 챌린지 기여 엔티티
///
/// 참가자가 챌린지에 제출한 러닝 기록
class LogRunContributionEntity extends Equatable {
  /// 기여 ID
  final String id;

  /// 챌린지 ID
  final String challengeId;

  /// 사용자 ID
  final String userId;

  /// 사용자 닉네임
  final String userNickname;

  /// 원본 운동 기록 ID (중복 방지용)
  final String workoutId;

  /// 기여 거리 (km)
  final double distance;

  /// 운동 유형
  final WorkoutType workoutType;

  /// 실제 운동한 날짜
  final DateTime workoutDate;

  /// 기록을 제출한 시간
  final DateTime submittedAt;

  /// 전체 목표 대비 기여 비율 (0.0 ~ 1.0)
  final double percentage;

  const LogRunContributionEntity({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userNickname,
    required this.workoutId,
    required this.distance,
    required this.workoutType,
    required this.workoutDate,
    required this.submittedAt,
    required this.percentage,
  });

  @override
  List<Object?> get props => [
        id,
        challengeId,
        userId,
        userNickname,
        workoutId,
        distance,
        workoutType,
        workoutDate,
        submittedAt,
        percentage,
      ];
}
