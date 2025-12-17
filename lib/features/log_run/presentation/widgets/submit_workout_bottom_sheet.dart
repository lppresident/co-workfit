import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_event.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_state.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:intl/intl.dart';

/// 운동 기록 제출 Bottom Sheet
class SubmitWorkoutBottomSheet extends StatefulWidget {
  final String challengeId;
  final Function(String workoutId, double distance, String workoutType, DateTime workoutDate) onSubmit;

  const SubmitWorkoutBottomSheet({
    super.key,
    required this.challengeId,
    required this.onSubmit,
  });

  @override
  State<SubmitWorkoutBottomSheet> createState() => _SubmitWorkoutBottomSheetState();
}

class _SubmitWorkoutBottomSheetState extends State<SubmitWorkoutBottomSheet> {
  WorkoutEntity? _selectedWorkout;

  @override
  void initState() {
    super.initState();
    // 최근 30일 운동 기록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutBloc>().add(const FetchRecentWorkoutsEvent(days: 30));
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
                      if (state.workouts.isEmpty) {
                        return const Center(
                          child: Text('제출할 운동 기록이 없습니다.'),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: state.workouts.length,
                        itemBuilder: (context, index) {
                          final workout = state.workouts[index];
                          final isSelected = _selectedWorkout?.id == workout.id;

                          return ListTile(
                            leading: Icon(
                              _getWorkoutIcon(workout.type),
                              color: isSelected ? Theme.of(context).colorScheme.primary : null,
                            ),
                            title: Text(
                              _getWorkoutTypeName(workout.type),
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Theme.of(context).colorScheme.primary : null,
                              ),
                            ),
                            subtitle: Text(
                              '${DateFormat('yyyy.MM.dd HH:mm').format(workout.startTime)} • '
                              '${(workout.distance ?? 0.0).toStringAsFixed(2)} km',
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                                : null,
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedWorkout = workout;
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
                          : () {
                              widget.onSubmit(
                                _selectedWorkout!.id,
                                _selectedWorkout!.distance ?? 0.0,
                                _selectedWorkout!.type.toString().split('.').last,
                                _selectedWorkout!.startTime,
                              );
                              Navigator.pop(context);
                            },
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
}
