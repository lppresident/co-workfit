import 'package:flutter/material.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:intl/intl.dart';

/// 운동 상세보기 페이지
/// 
/// 운동 데이터는 Firestore 등록 시점에만 수정 가능하며,
/// 등록 이후에는 읽기 전용으로 표시됩니다.
class WorkoutDetailPage extends StatelessWidget {
  final WorkoutEntity workout;

  const WorkoutDetailPage({
    super.key,
    required this.workout,
  });

  /// 페이스 표시 대상 운동 타입인지 확인
  bool get _shouldShowPace {
    return workout.type == WorkoutType.running ||
        workout.type == WorkoutType.walking ||
        workout.type == WorkoutType.hiking;
  }

  /// 페이스 계산 (분'초"/km 형식)
  /// 초 단위로 정확하게 계산
  String? get _pace {
    final distance = workout.distance;
    if (distance == null || distance <= 0) return null;
    if (workout.durationSeconds <= 0) return null;

    // 초 단위로 페이스 계산: (총 초 / 거리 km) = 초/km
    final paceSecondsPerKm = workout.durationSeconds / distance;
    final minutes = (paceSecondsPerKm / 60).floor();
    final seconds = (paceSecondsPerKm % 60).round();

    // 비정상적인 페이스 필터링
    if (minutes < 1 || minutes > 30) return null;

    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: 공유 기능 (향후 소셜 기능 연동)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('공유 기능 준비 중')),
              );
            },
            tooltip: '공유',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상단 헤더 (운동 타입 및 아이콘)
            _buildHeader(context),

            // 운동 상세 정보
            _buildWorkoutInfo(context),

            // 데이터 소스
            _buildSourceInfo(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _getWorkoutColor(workout.type).withValues(alpha: 0.1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getWorkoutColor(workout.type),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getWorkoutIcon(workout.type),
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getWorkoutTypeName(workout.type),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDateTime(workout.startTime),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutInfo(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '운동 정보',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.access_time,
              '시작 시간',
              DateFormat('yyyy년 MM월 dd일 HH:mm').format(workout.startTime),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              Icons.timer,
              '종료 시간',
              DateFormat('yyyy년 MM월 dd일 HH:mm').format(workout.endTime),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              Icons.timelapse,
              '총 시간',
              '${workout.durationMinutes}분',
            ),
            if (workout.calories != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                Icons.local_fire_department,
                '칼로리',
                '${workout.calories} kcal',
              ),
            ],
            if (workout.distance != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                Icons.straighten,
                '거리',
                '${workout.distance!.toStringAsFixed(2)} km',
              ),
            ],
            // 페이스 표시 (러닝, 걷기, 등산)
            if (_shouldShowPace && _pace != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                Icons.speed,
                '페이스',
                '$_pace /km',
              ),
            ],
            if (workout.averageHeartRate != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                Icons.favorite,
                '평균 심박수',
                '${workout.averageHeartRate} BPM',
              ),
            ],
            if (workout.maxHeartRate != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                Icons.favorite_border,
                '최대 심박수',
                '${workout.maxHeartRate} BPM',
              ),
            ],
            if (workout.elevationGain != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                Icons.terrain,
                '고도 상승',
                '${workout.elevationGain!.toStringAsFixed(1)} m',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceInfo(BuildContext context) {
    final sourceInfo = _getSourceInfo(workout.source);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.source_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '데이터 소스',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    sourceInfo['icon'] as IconData,
                    size: 32,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sourceInfo['name'] as String,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sourceInfo['description'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (workout.syncedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                '동기화: ${DateFormat('yyyy-MM-dd HH:mm').format(workout.syncedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
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
        return {
          'name': 'Apple Health',
          'icon': Icons.apple,
          'description': 'Apple HealthKit에서 가져온 데이터',
        };
      case WorkoutSource.googleFit:
        return {
          'name': 'Google Fit',
          'icon': Icons.android,
          'description': 'Google Fit에서 가져온 데이터',
        };
      case WorkoutSource.garmin:
        return {
          'name': 'Garmin',
          'icon': Icons.watch,
          'description': 'Garmin Connect에서 가져온 데이터',
        };
      case WorkoutSource.samsungHealth:
        return {
          'name': 'Samsung Health',
          'icon': Icons.smartphone,
          'description': 'Samsung Health에서 가져온 데이터',
        };
      case WorkoutSource.manual:
        return {
          'name': '수동 입력',
          'icon': Icons.edit,
          'description': '사용자가 직접 입력한 데이터',
        };
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy년 MM월 dd일 HH:mm').format(dateTime);
  }
}
