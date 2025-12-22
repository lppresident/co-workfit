import 'package:flutter/material.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_contribution_entity.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:intl/intl.dart';

/// 기여 내역 피드 위젯
class ContributionFeedWidget extends StatelessWidget {
  final List<LogRunContributionEntity> contributions;

  const ContributionFeedWidget({
    super.key,
    required this.contributions,
  });

  @override
  Widget build(BuildContext context) {
    if (contributions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: contributions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final contribution = contributions[index];
        return _ContributionItem(contribution: contribution);
      },
    );
  }
}

class _ContributionItem extends StatelessWidget {
  final LogRunContributionEntity contribution;

  const _ContributionItem({required this.contribution});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getWorkoutColor(contribution.workoutType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getWorkoutIcon(contribution.workoutType),
                color: _getWorkoutColor(contribution.workoutType),
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
                        '${contribution.distance.toStringAsFixed(1)} km',
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
                        _formatDate(contribution.workoutDate),
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
          ],
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
