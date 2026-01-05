import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/log_run/domain/entities/workout_type.dart';

/// 정산용 챌린지 데이터
class ChallengeSettlementData {
  /// 챌린지 ID
  final String challengeId;

  /// 챌린지 이름
  final String challengeName;

  /// 챌린지 운동 타입
  final ChallengeType challengeType;

  /// 목표 수치 (거리 km 또는 점수)
  final double targetValue;

  /// 달성 수치
  final double achievedValue;

  /// 성공 여부
  final bool isSuccess;

  /// 종료일
  final DateTime endDate;

  /// 참가자 수
  final int participantCount;

  /// 참가자별 기여 수치
  final Map<String, double> participantContributions;

  /// 사용자의 기여 수치
  final double userContribution;

  /// 사용자가 MVP인지
  final bool isUserMvp;

  /// 사용자의 총 운동 수치 (개인 운동 보상용)
  final double userTotalWorkoutValue;

  /// 사용자의 첫 기여 여부
  final bool isFirstContribution;

  const ChallengeSettlementData({
    required this.challengeId,
    required this.challengeName,
    required this.challengeType,
    required this.targetValue,
    required this.achievedValue,
    required this.isSuccess,
    required this.endDate,
    required this.participantCount,
    required this.participantContributions,
    required this.userContribution,
    required this.isUserMvp,
    required this.userTotalWorkoutValue,
    required this.isFirstContribution,
  });

  /// 해당하는 재화 타입 반환
  CurrencyType get currencyType {
    switch (challengeType) {
      case ChallengeType.running:
        return CurrencyType.wood;
      case ChallengeType.strengthTraining:
        return CurrencyType.iron;
      case ChallengeType.other:
        return CurrencyType.soil;
    }
  }

  /// 달리기 챌린지인지
  bool get isRunning => challengeType == ChallengeType.running;

  /// 헬스 챌린지인지
  bool get isStrengthTraining => challengeType == ChallengeType.strengthTraining;
}

/// 개인 운동 데이터 (챌린지 없이 운동한 기록)
class SoloWorkoutData {
  /// 재화 타입
  final CurrencyType currencyType;

  /// 운동 수치 (거리 km 또는 점수)
  final double value;

  /// 단위 (km, 점)
  final String unit;

  /// 운동 횟수
  final int workoutCount;

  /// 운동 날짜
  final String date;

  const SoloWorkoutData({
    required this.currencyType,
    required this.value,
    required this.unit,
    required this.workoutCount,
    required this.date,
  });

  bool get hasData => value > 0;
  
  /// 달리기 운동 데이터 생성
  factory SoloWorkoutData.running({
    required double distanceKm,
    required int workoutCount,
    required String date,
  }) {
    return SoloWorkoutData(
      currencyType: CurrencyType.wood,
      value: distanceKm,
      unit: 'km',
      workoutCount: workoutCount,
      date: date,
    );
  }
  
  /// 헬스 운동 데이터 생성
  factory SoloWorkoutData.strength({
    required double score,
    required int workoutCount,
    required String date,
  }) {
    return SoloWorkoutData(
      currencyType: CurrencyType.iron,
      value: score,
      unit: '점',
      workoutCount: workoutCount,
      date: date,
    );
  }
  
  /// 기타 운동 데이터 생성 (시간 기반)
  factory SoloWorkoutData.other({
    required double minutes,
    required int workoutCount,
    required String date,
  }) {
    return SoloWorkoutData(
      currencyType: CurrencyType.soil,
      value: minutes,
      unit: '분',
      workoutCount: workoutCount,
      date: date,
    );
  }
}

