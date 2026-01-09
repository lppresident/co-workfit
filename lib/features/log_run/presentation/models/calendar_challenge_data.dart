import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_archive_entity.dart';

/// 캘린더에 표시할 챌린지 데이터
class CalendarChallengeData {
  final DateTime date;
  final List<ChallengeEntity> activeChallenges;
  final List<ChallengeEntity> completedChallenges;
  final List<ChallengeArchiveEntity> archivedChallenges;

  const CalendarChallengeData({
    required this.date,
    this.activeChallenges = const [],
    this.completedChallenges = const [],
    this.archivedChallenges = const [],
  });

  /// 해당 날짜에 챌린지가 있는지
  bool get hasChallenges =>
      activeChallenges.isNotEmpty ||
      completedChallenges.isNotEmpty ||
      archivedChallenges.isNotEmpty;

  /// 성공한 챌린지 개수
  int get successCount =>
      completedChallenges.length +
      archivedChallenges.where((a) => a.isSuccess).length;

  /// 실패한 챌린지 개수
  int get failureCount =>
      archivedChallenges.where((a) => !a.isSuccess).length;

  /// 진행 중인 챌린지 개수
  int get activeCount => activeChallenges.length;

  /// 전체 챌린지 개수
  int get totalCount =>
      activeChallenges.length +
      completedChallenges.length +
      archivedChallenges.length;
}
