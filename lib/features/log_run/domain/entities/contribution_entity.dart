import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

/// 챌린지 기여 엔티티
///
/// 참가자가 챌린지에 제출한 운동 기록
/// workout 상세 데이터는 workoutId로 /workouts/{workoutId}에서 조회
class ContributionEntity extends Equatable {
  /// 기여 ID
  final String id;

  /// 챌린지 ID
  final String challengeId;

  /// 사용자 ID
  final String userId;

  /// 사용자 닉네임
  final String userNickname;

  /// 원본 운동 기록 ID (/workouts/{workoutId} 참조)
  final String workoutId;

  /// 기여 무게 (kg) - 챌린지 목표 대비 기여량
  final double contributionValue;

  /// 기록을 제출한 시간
  final DateTime submittedAt;

  /// 전체 목표 대비 기여 비율 (0.0 ~ 1.0)
  final double percentage;

  /// 운동 유형 (피드 표시용 캐시)
  final WorkoutType? workoutType;

  /// 실제 운동한 날짜 (피드 표시용 캐시)
  final DateTime? workoutDate;

  const ContributionEntity({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userNickname,
    required this.workoutId,
    required this.contributionValue,
    required this.submittedAt,
    required this.percentage,
    this.workoutType,
    this.workoutDate,
  });

  @override
  List<Object?> get props => [
        id,
        challengeId,
        userId,
        userNickname,
        workoutId,
        contributionValue,
        submittedAt,
        percentage,
        workoutType,
        workoutDate,
      ];
}
