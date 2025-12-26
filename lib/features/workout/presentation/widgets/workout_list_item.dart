import 'package:flutter/material.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:intl/intl.dart';

/// 운동 리스트 아이템 위젯
class WorkoutListItem extends StatelessWidget {
  final WorkoutEntity workout;
  final VoidCallback? onTap;
  final VoidCallback? onEditDistance;

  const WorkoutListItem({
    super.key,
    required this.workout,
    this.onTap,
    this.onEditDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 운동 아이콘
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getWorkoutColor(workout.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getWorkoutIcon(workout.type),
                      color: _getWorkoutColor(workout.type),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 운동 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getWorkoutTypeName(workout.type),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(workout.startTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  // 점수
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${workout.calibratedScore}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 상세 정보
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    Icons.timer_outlined,
                    '${workout.durationMinutes}분',
                    '시간',
                  ),
                  if (workout.calories != null)
                    _buildStatItem(
                      context,
                      Icons.local_fire_department_outlined,
                      '${workout.calories}',
                      '칼로리',
                    ),
                  if (workout.effectiveDistance != null)
                    _buildDistanceStatItem(context),
                  if (workout.averageHeartRate != null)
                    _buildStatItem(
                      context,
                      Icons.favorite_outline,
                      '${workout.averageHeartRate}',
                      'BPM',
                    ),
                ],
              ),
              // 소스 배지
              const SizedBox(height: 12),
              _buildSourceBadge(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceStatItem(BuildContext context) {
    return InkWell(
      onTap: onEditDistance,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.straighten_outlined, size: 20, color: Colors.grey[600]),
                if (workout.hasDistanceCorrection) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.edit, size: 12, color: Colors.blue),
                ],
                if (onEditDistance != null) ...[
                  const SizedBox(width: 2),
                  Icon(Icons.touch_app, size: 12, color: Colors.grey[400]),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${workout.effectiveDistance!.toStringAsFixed(1)}km',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: workout.hasDistanceCorrection ? Colors.blue : null,
                  ),
            ),
            Text(
              '거리',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _buildSourceBadge(BuildContext context) {
    final sourceInfo = _getSourceInfo(workout.source);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sourceInfo['icon'] as IconData, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            sourceInfo['name'] as String,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
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
      case WorkoutType.swimming:
        return Icons.pool;
      case WorkoutType.weightTraining:
        return Icons.fitness_center;
      case WorkoutType.yoga:
        return Icons.self_improvement;
      case WorkoutType.hiking:
        return Icons.terrain;
      case WorkoutType.other:
        return Icons.sports;
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
      case WorkoutType.swimming:
        return Colors.cyan;
      case WorkoutType.weightTraining:
        return Colors.red;
      case WorkoutType.yoga:
        return Colors.purple;
      case WorkoutType.hiking:
        return Colors.brown;
      case WorkoutType.other:
        return Colors.grey;
    }
  }

  String _getWorkoutTypeName(WorkoutType type) {
    switch (type) {
      case WorkoutType.running:
        return '러닝';
      case WorkoutType.cycling:
        return '사이클링';
      case WorkoutType.walking:
        return '걷기';
      case WorkoutType.swimming:
        return '수영';
      case WorkoutType.weightTraining:
        return '웨이트 트레이닝';
      case WorkoutType.yoga:
        return '요가';
      case WorkoutType.hiking:
        return '등산';
      case WorkoutType.other:
        return '기타 운동';
    }
  }

  Map<String, dynamic> _getSourceInfo(WorkoutSource source) {
    switch (source) {
      case WorkoutSource.appleHealth:
        return {'name': 'Apple Health', 'icon': Icons.apple};
      case WorkoutSource.googleFit:
        return {'name': 'Google Fit', 'icon': Icons.android};
      case WorkoutSource.garmin:
        return {'name': 'Garmin', 'icon': Icons.watch};
      case WorkoutSource.samsungHealth:
        return {'name': 'Samsung Health', 'icon': Icons.smartphone};
      case WorkoutSource.manual:
        return {'name': '수동 입력', 'icon': Icons.edit};
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '오늘 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return '어제 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM월 dd일 HH:mm').format(dateTime);
    }
  }
}
