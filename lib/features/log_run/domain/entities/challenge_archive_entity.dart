import 'package:equatable/equatable.dart';

/// 간소화된 챌린지 기록 (보관용)
///
/// 7일 이상 지난 챌린지는 상세 정보를 삭제하고
/// 이 간소화된 형태로 보관하여 사용자가 과거 기록을 확인할 수 있도록 함
///
/// Note: 달성량, 참가자 수, 기여도 등은 workout 기록을 통해 조회 가능하므로 저장하지 않음
class ChallengeArchiveEntity extends Equatable {
  /// 챌린지 ID
  final String challengeId;

  /// 성공 여부
  final bool isSuccess;

  /// 목표 무게 (kg)
  final double targetWeight;

  /// 종료 날짜
  final DateTime endDate;

  /// 아카이브 생성 시간
  final DateTime archivedAt;

  const ChallengeArchiveEntity({
    required this.challengeId,
    required this.isSuccess,
    required this.targetWeight,
    required this.endDate,
    required this.archivedAt,
  });

  @override
  List<Object?> get props => [
        challengeId,
        isSuccess,
        targetWeight,
        endDate,
        archivedAt,
      ];
}
