import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_event.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_state.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/iron/domain/entities/iron_reward_constants.dart';
import 'package:intl/intl.dart';

/// 운동 기록 제출 Bottom Sheet
class SubmitWorkoutBottomSheet extends StatefulWidget {
  final String challengeId;
  final DateTime startDate;
  final DateTime endDate;
  final Function(WorkoutEntity workout) onSubmit;

  const SubmitWorkoutBottomSheet({
    super.key,
    required this.challengeId,
    required this.startDate,
    required this.endDate,
    required this.onSubmit,
  });

  @override
  State<SubmitWorkoutBottomSheet> createState() => _SubmitWorkoutBottomSheetState();
}

class _SubmitWorkoutBottomSheetState extends State<SubmitWorkoutBottomSheet> {
  WorkoutEntity? _selectedWorkout;
  final TextEditingController _distanceController = TextEditingController();

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 최근 30일 등록된 운동 기록만 로드 (Firestore 데이터만)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutBloc>().add(const FetchWorkoutsFromFirestoreEvent(days: 30));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '운동 기록 제출',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 운동 기록 목록
              Expanded(
                child: BlocBuilder<WorkoutBloc, WorkoutState>(
                  builder: (context, state) {
                    if (state is WorkoutLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is WorkoutLoaded) {
                      // 챌린지 기간 계산
                      final startOfStartDate = DateTime(
                        widget.startDate.year,
                        widget.startDate.month,
                        widget.startDate.day,
                      );
                      final endOfEndDate = DateTime(
                        widget.endDate.year,
                        widget.endDate.month,
                        widget.endDate.day,
                        23,
                        59,
                        59,
                      );

                      // 통합 챌린지: 모든 운동 타입 허용
                      final validWorkouts = state.workouts
                          .where((workout) {
                            // 기간 체크
                            final inPeriod = workout.startTime.isAfter(
                                    startOfStartDate.subtract(const Duration(seconds: 1))) &&
                                workout.startTime.isBefore(
                                    endOfEndDate.add(const Duration(seconds: 1)));
                            return inPeriod;
                          })
                          .toList();

                      if (validWorkouts.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '제출 가능한 운동 기록이 없습니다',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '챌린지 기간: ${DateFormat('MM/dd').format(widget.startDate)} ~ ${DateFormat('MM/dd').format(widget.endDate)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '이 기간 내의 운동 기록만 제출 가능합니다',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: validWorkouts.length,
                        itemBuilder: (context, index) {
                          final workout = validWorkouts[index];
                          final isSelected = _selectedWorkout?.id == workout.id;

                          // Garmin 데이터인지 확인
                          final isGarminData = workout.source == WorkoutSource.garmin;
                          
                          // 헬스 운동인 경우 점수 계산
                          final isStrengthWorkout = workout.type == WorkoutType.weightTraining;
                          String valueDisplay;
                          if (isStrengthWorkout) {
                            final strengthScore = StrengthScoreCalculator.calculateStrengthScore(
                              durationMinutes: workout.durationMinutes,
                              avgHeartRate: workout.averageHeartRate,
                            );
                            final intensity = WorkoutIntensityExtension.fromHeartRate(workout.averageHeartRate);
                            valueDisplay = '${strengthScore.toStringAsFixed(1)}점 (${intensity.displayName})';
                          } else {
                            valueDisplay = '${(workout.effectiveDistance ?? 0.0).toStringAsFixed(2)} km';
                          }

                          return ListTile(
                            leading: Icon(
                              _getWorkoutIcon(workout.type),
                              color: isSelected ? Theme.of(context).colorScheme.primary : null,
                            ),
                            title: Row(
                              children: [
                                Text(
                                  _getWorkoutTypeName(workout.type),
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                  ),
                                ),
                                if (isGarminData && !isStrengthWorkout) ...[
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: '거리 데이터가 부정확할 수 있습니다.\n제출 시 확인해주세요.',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.1),
                                        border: Border.all(color: Colors.orange, width: 1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.warning_amber, size: 12, color: Colors.orange),
                                          SizedBox(width: 4),
                                          Text(
                                            'Garmin',
                                            style: TextStyle(fontSize: 10, color: Colors.orange),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  '${DateFormat('yyyy.MM.dd HH:mm').format(workout.startTime)} • $valueDisplay',
                                ),
                                if (!isStrengthWorkout && workout.hasDistanceCorrection) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit, size: 12, color: Colors.blue),
                                ],
                                if (isStrengthWorkout) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '• ${workout.durationMinutes}분',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                                : null,
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedWorkout = workout;
                                if (isStrengthWorkout) {
                                  final strengthScore = StrengthScoreCalculator.calculateStrengthScore(
                                    durationMinutes: workout.durationMinutes,
                                    avgHeartRate: workout.averageHeartRate,
                                  );
                                  _distanceController.text = strengthScore.toStringAsFixed(2);
                                } else {
                                  _distanceController.text = (workout.distance ?? 0.0).toStringAsFixed(2);
                                }
                              });
                            },
                          );
                        },
                      );
                    }

                    if (state is WorkoutError) {
                      return Center(
                        child: Text('운동 기록을 불러올 수 없습니다.\n${state.message}'),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),

              // 제출 버튼
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedWorkout == null
                          ? null
                          : () => _handleSubmit(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('제출하기'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      case WorkoutType.hiking:
        return Icons.terrain;
      case WorkoutType.yoga:
        return Icons.self_improvement;
      case WorkoutType.weightTraining:
        return Icons.fitness_center;
      default:
        return Icons.fitness_center;
    }
  }

  String _getWorkoutTypeName(WorkoutType type) {
    switch (type) {
      case WorkoutType.running:
        return '러닝';
      case WorkoutType.cycling:
        return '사이클';
      case WorkoutType.walking:
        return '걷기';
      case WorkoutType.swimming:
        return '수영';
      case WorkoutType.hiking:
        return '등산';
      case WorkoutType.yoga:
        return '요가';
      case WorkoutType.weightTraining:
        return '웨이트 트레이닝';
      default:
        return '기타';
    }
  }

  /// 제출 처리
  void _handleSubmit() {
    if (_selectedWorkout == null) return;

    final workout = _selectedWorkout!;
    final isStrengthWorkout = workout.type == WorkoutType.weightTraining;

    // 헬스 운동의 경우 점수로 바로 제출
    if (isStrengthWorkout) {
      final strengthScore = StrengthScoreCalculator.calculateStrengthScore(
        durationMinutes: workout.durationMinutes,
        avgHeartRate: workout.averageHeartRate,
      );
      _submitWorkout(strengthScore);
      return;
    }

    // 달리기 운동의 경우 기존 로직
    // 이미 수정된 거리가 있으면 바로 제출
    if (workout.hasDistanceCorrection) {
      _submitWorkout(workout.effectiveDistance ?? 0.0);
      return;
    }

    // Garmin 데이터이면서 수정되지 않은 경우 거리 보정 다이얼로그 표시
    final isGarminData = workout.source == WorkoutSource.garmin;
    if (isGarminData) {
      _showDistanceCorrectionDialog();
    } else {
      // 일반 데이터는 바로 제출
      _submitWorkout(workout.effectiveDistance ?? 0.0);
    }
  }

  /// 거리 보정 다이얼로그 표시 (Garmin 데이터)
  void _showDistanceCorrectionDialog() {
    final originalDistance = _selectedWorkout!.distance ?? 0.0;
    _distanceController.text = originalDistance.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('거리 확인 필요'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Garmin 데이터는 거리가 부정확할 수 있습니다.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Garmin Connect 앱에서 실제 거리를 확인하고\n정확한 거리를 입력해주세요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: '정확한 거리 (km)',
                hintText: '예: 5.63',
                suffixText: 'km',
                border: const OutlineInputBorder(),
                helperText: '원래 값: ${originalDistance.toStringAsFixed(2)} km',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final input = _distanceController.text.trim();
              if (input.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('거리를 입력해주세요.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final distance = double.tryParse(input);
              if (distance == null || distance <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('올바른 거리를 입력해주세요. (0보다 큰 숫자)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (distance > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('거리가 너무 큽니다. (100km 이하로 입력해주세요)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context); // 다이얼로그 닫기
              _submitWorkout(distance);
            },
            child: const Text('제출'),
          ),
        ],
      ),
    );
  }

  /// 운동 기록 제출
  void _submitWorkout(double distance) {
    widget.onSubmit(_selectedWorkout!);
    Navigator.pop(context); // Bottom Sheet 닫기
  }
}
