import 'package:equatable/equatable.dart';

/// 통나무런 챌린지 엔티티
///
/// 여러 명이 하나의 목표 거리(무게)를 함께 완주하는 팀 챌린지
class LogRunChallengeEntity extends Equatable {
  /// 챌린지 ID
  final String id;

  /// 생성자 ID
  final String createdBy;

  /// 생성자 이름
  final String creatorName;

  /// 목표 통나무 무게 (kg)
  final double targetWeight;

  /// 목표 거리 (km) - targetWeight와 동일 (1kg = 1km)
  final double targetDistance;

  /// 현재까지 완주한 거리 (km)
  final double currentDistance;

  /// 남은 무게 (kg)
  final double remainingWeight;

  /// 참가자 ID 목록
  final List<String> participants;

  /// 참가자 이름 맵 (userId -> name)
  final Map<String, String> participantNames;

  /// 챌린지 상태
  final ChallengeStatus status;

  /// 생성 시간
  final DateTime createdAt;

  /// 만료 시간 (옵션)
  final DateTime? expiresAt;

  /// 제출 가능한 기록의 최대 나이 (일) - 기본값: 7일
  final int recordTimeLimit;

  /// 방 생성 후 기록만 허용할지 여부
  final bool allowFutureRecordsOnly;

  const LogRunChallengeEntity({
    required this.id,
    required this.createdBy,
    required this.creatorName,
    required this.targetWeight,
    required this.targetDistance,
    required this.currentDistance,
    required this.remainingWeight,
    required this.participants,
    required this.participantNames,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.recordTimeLimit = 7,
    this.allowFutureRecordsOnly = false,
  });

  /// 진행률 (0.0 ~ 1.0)
  double get progress => targetDistance > 0 ? currentDistance / targetDistance : 0.0;

  /// 완료 여부
  bool get isCompleted => status == ChallengeStatus.completed;

  /// 활성 여부
  bool get isActive => status == ChallengeStatus.active;

  /// 만료 여부
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  @override
  List<Object?> get props => [
        id,
        createdBy,
        creatorName,
        targetWeight,
        targetDistance,
        currentDistance,
        remainingWeight,
        participants,
        participantNames,
        status,
        createdAt,
        expiresAt,
        recordTimeLimit,
        allowFutureRecordsOnly,
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
        return '완료';
      case ChallengeStatus.expired:
        return '만료';
    }
  }
}
