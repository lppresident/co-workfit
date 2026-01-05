import 'package:equatable/equatable.dart';
import 'participant_stats_entity.dart';

/// 챌린지 엔티티
///
/// 여러 명이 하나의 목표 무게(kg)를 함께 완주하는 팀 챌린지
/// 달리기/헬스 운동 모두 제출 가능하며, 각 운동 비율에 따라 재화 지급
class ChallengeEntity extends Equatable {
  /// 챌린지 ID
  final String id;

  /// 생성자 ID (userId)
  final String createdBy;

  /// 목표 무게 (kg)
  /// - 달리기: 1km = 1kg
  /// - 헬스: 10점 = 1kg
  final double targetWeight;

  /// 현재 달성 무게 (kg)
  final double currentWeight;

  /// 남은 무게 (kg)
  final double remainingWeight;

  /// 참가자 ID 목록 (userId 배열)
  final List<String> participants;

  /// 참가자별 닉네임 (userId -> nickname)
  final Map<String, String> participantNicknames;

  /// 참가자별 기여 통계 (userId -> ParticipantStats)
  final Map<String, ParticipantStatsEntity> participantStats;

  /// 챌린지 상태
  final ChallengeStatus status;

  /// 생성 시간
  final DateTime createdAt;

  /// 챌린지 시작일 (이 날짜 이후의 운동만 제출 가능)
  final DateTime startDate;

  /// 챌린지 종료일 (이 날짜까지의 운동만 제출 가능)
  final DateTime endDate;

  /// 완료 시간 (챌린지 완료 시 기록)
  final DateTime? completedAt;

  /// TTL 만료 시간 (완료 후 7일 뒤 자동 삭제)
  final DateTime? expireAt;

  /// 초대 코드 (6자리 영숫자)
  final String inviteCode;

  /// 최대 참가자 수 (null이면 무제한)
  final int? maxParticipants;

  /// 점수 지급 완료 여부
  final bool scoreAwarded;

  /// 참가자별 획득 점수 (userId -> score)
  final Map<String, int> awardedScores;

  const ChallengeEntity({
    required this.id,
    required this.createdBy,
    required this.targetWeight,
    required this.currentWeight,
    required this.remainingWeight,
    required this.participants,
    this.participantNicknames = const {},
    this.participantStats = const {},
    required this.status,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.inviteCode,
    this.completedAt,
    this.expireAt,
    this.maxParticipants,
    this.scoreAwarded = false,
    this.awardedScores = const {},
  });

  /// 진행률 (0.0 ~ 1.0)
  double get progress => targetWeight > 0 ? currentWeight / targetWeight : 0.0;

  /// 완료 여부
  bool get isCompleted => status == ChallengeStatus.completed;

  /// 활성 여부
  bool get isActive => status == ChallengeStatus.active;

  /// 만료 여부 (종료일이 지났는지)
  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  /// 챌린지가 아직 시작되지 않았는지
  bool get isNotStarted {
    return DateTime.now().isBefore(startDate);
  }

  /// 현재 운동 제출이 가능한 기간인지
  bool get isSubmissionPeriod {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// 운동 날짜가 제출 가능한 기간인지 확인
  bool isWorkoutDateValid(DateTime workoutDate) {
    // 운동 날짜가 시작일 이후이고 종료일 이전이어야 함
    final startOfStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return workoutDate.isAfter(startOfStartDate.subtract(const Duration(seconds: 1))) &&
           workoutDate.isBefore(endOfEndDate.add(const Duration(seconds: 1)));
  }

  /// 완료 후 보관 기간이 지났는지 (7일)
  bool get isRetentionExpired {
    if (completedAt == null) return false;
    return DateTime.now().isAfter(completedAt!.add(const Duration(days: 7)));
  }

  /// 정원 초과 여부
  bool get isFull {
    if (maxParticipants == null) return false;
    return participants.length >= maxParticipants!;
  }

  /// 목표 단위 표시 (kg)
  String get targetUnitDisplay => '${targetWeight.toStringAsFixed(0)}kg';

  /// 현재 진행 단위 표시 (kg)
  String get currentUnitDisplay => '${currentWeight.toStringAsFixed(1)}kg';

  /// 특정 참가자의 통계 가져오기
  ParticipantStatsEntity? getParticipantStats(String userId) {
    return participantStats[userId];
  }

  /// 참가자 닉네임 가져오기
  String getParticipantNickname(String userId) {
    return participantNicknames[userId] ?? '알 수 없음';
  }

  @override
  List<Object?> get props => [
        id,
        createdBy,
        targetWeight,
        currentWeight,
        remainingWeight,
        participants,
        participantNicknames,
        participantStats,
        status,
        createdAt,
        startDate,
        endDate,
        completedAt,
        expireAt,
        inviteCode,
        maxParticipants,
        scoreAwarded,
        awardedScores,
      ];
}

/// 챌린지 상태
enum ChallengeStatus {
  /// 진행 중
  active,

  /// 완료됨
  completed,

  /// 만료됨
  expired,
}

/// ChallengeStatus 확장
extension ChallengeStatusExtension on ChallengeStatus {
  String toFirestore() {
    switch (this) {
      case ChallengeStatus.active:
        return 'active';
      case ChallengeStatus.completed:
        return 'completed';
      case ChallengeStatus.expired:
        return 'expired';
    }
  }

  static ChallengeStatus fromFirestore(String value) {
    switch (value) {
      case 'active':
        return ChallengeStatus.active;
      case 'completed':
        return ChallengeStatus.completed;
      case 'expired':
        return ChallengeStatus.expired;
      default:
        return ChallengeStatus.active;
    }
  }

  String get displayName {
    switch (this) {
      case ChallengeStatus.active:
        return '진행 중';
      case ChallengeStatus.completed:
        return '성공';
      case ChallengeStatus.expired:
        return '실패';
    }
  }
}
