import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:co_workfit/features/log_run/domain/entities/contribution_entity.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_bloc.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_event.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';
import 'package:co_workfit/features/workout/presentation/pages/workout_detail_page.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:intl/intl.dart';

/// 기여 내역 피드 위젯
class ContributionFeedWidget extends StatelessWidget {
  final List<ContributionEntity> contributions;
  final String challengeId;

  const ContributionFeedWidget({
    super.key,
    required this.contributions,
    required this.challengeId,
  });

  @override
  Widget build(BuildContext context) {
    if (contributions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '아직 기여 내역이 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 운동 기록을 제출해보세요!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(
              contributions.length,
              (index) {
                final contribution = contributions[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index < contributions.length - 1 ? 12 : 0),
                  child: _ContributionItem(
                    contribution: contribution,
                    challengeId: challengeId,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ContributionItem extends StatelessWidget {
  final ContributionEntity contribution;
  final String challengeId;

  const _ContributionItem({
    required this.contribution,
    required this.challengeId,
  });

  /// 운동 상세 페이지로 이동
  Future<void> _navigateToWorkoutDetail(BuildContext context) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final workoutRepository = GetIt.I<WorkoutRepository>();
      final result = await workoutRepository.getWorkoutById(contribution.workoutId);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // 로딩 닫기

      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('운동 정보를 불러올 수 없습니다: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (workout) {
          if (workout == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('운동 기록을 찾을 수 없습니다'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          // 현재 사용자가 운동의 소유자인지 확인
          final authState = context.read<AuthBloc>().state;
          final isOwner = authState is Authenticated && 
              contribution.userId == authState.user.id;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkoutDetailPage(
                workout: workout,
                isOwner: isOwner,
                challengeId: challengeId,
                contributionId: contribution.id,
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // 로딩 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    // 본인 기록만 삭제 가능
    if (contribution.userId != authState.user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('본인의 기여 기록만 삭제할 수 있습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('기여 기록 삭제'),
        content: Text('${contribution.contributionValue.toStringAsFixed(2)}kg 기록을 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ChallengeBloc>().add(
                    DeleteContributionEvent(
                      challengeId: challengeId,
                      contributionId: contribution.id,
                      userId: authState.user.id,
                    ),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isOwner = authState is Authenticated && contribution.userId == authState.user.id;

    return Card(
      child: InkWell(
        onTap: () => _navigateToWorkoutDetail(context),
        onLongPress: isOwner ? () => _showDeleteConfirmation(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getWorkoutColor(contribution.workoutType ?? WorkoutType.other).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getWorkoutIcon(contribution.workoutType ?? WorkoutType.other),
                  color: _getWorkoutColor(contribution.workoutType ?? WorkoutType.other),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          contribution.userNickname,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${contribution.contributionValue.toStringAsFixed(2)} kg',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          contribution.workoutDate != null 
                              ? _formatDate(contribution.workoutDate!)
                              : '-',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(contribution.submittedAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 기여도
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(contribution.percentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // 상세 보기 힌트
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getWorkoutIcon(WorkoutType type) {
    switch (type) {
      case WorkoutType.running:
        return Icons.directions_run;
      case WorkoutType.cycling:
        return Icons.directions_bike;
      case WorkoutType.walking:
        return Icons.directions_walk;
      case WorkoutType.hiking:
        return Icons.terrain;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getWorkoutColor(WorkoutType type) {
    switch (type) {
      case WorkoutType.running:
        return Colors.orange;
      case WorkoutType.cycling:
        return Colors.blue;
      case WorkoutType.walking:
        return Colors.green;
      case WorkoutType.hiking:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return '오늘';
    } else if (dateOnly == yesterday) {
      return '어제';
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else {
      return DateFormat('HH:mm').format(dateTime);
    }
  }
}
