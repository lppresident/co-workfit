import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_event.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_state.dart';
import 'package:co_workfit/features/workout/presentation/widgets/workout_list_item.dart';
import 'package:co_workfit/features/workout/presentation/pages/workout_detail_page.dart';
import 'package:co_workfit/features/workout/presentation/widgets/filter_bottom_sheet.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:intl/intl.dart';

/// 운동 전체목록 페이지
class WorkoutListPage extends StatefulWidget {
  const WorkoutListPage({super.key});

  @override
  State<WorkoutListPage> createState() => _WorkoutListPageState();
}

class _WorkoutListPageState extends State<WorkoutListPage> {
  WorkoutType? _selectedType;
  WorkoutSource? _selectedSource;
  String _sortBy = 'latest'; // 'latest', 'oldest', 'score_high', 'score_low'

  @override
  void initState() {
    super.initState();
    // 최근 30일 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutBloc>().add(const FetchRecentWorkoutsEvent(days: 30));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 운동 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
            tooltip: '필터',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: '정렬',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'latest',
                child: Row(
                  children: [
                    if (_sortBy == 'latest') const Icon(Icons.check, size: 20),
                    if (_sortBy == 'latest') const SizedBox(width: 8),
                    const Text('최신순'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    if (_sortBy == 'oldest') const Icon(Icons.check, size: 20),
                    if (_sortBy == 'oldest') const SizedBox(width: 8),
                    const Text('오래된순'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'score_high',
                child: Row(
                  children: [
                    if (_sortBy == 'score_high') const Icon(Icons.check, size: 20),
                    if (_sortBy == 'score_high') const SizedBox(width: 8),
                    const Text('점수 높은순'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'score_low',
                child: Row(
                  children: [
                    if (_sortBy == 'score_low') const Icon(Icons.check, size: 20),
                    if (_sortBy == 'score_low') const SizedBox(width: 8),
                    const Text('점수 낮은순'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<WorkoutBloc, WorkoutState>(
        builder: (context, state) {
          if (state is WorkoutLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WorkoutError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    '데이터를 불러올 수 없습니다',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<WorkoutBloc>().add(
                            const FetchRecentWorkoutsEvent(days: 30),
                          );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (state is WorkoutEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '운동 기록이 없습니다',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '첫 운동을 시작해보세요!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          if (state is WorkoutLoaded) {
            var workouts = state.workouts;

            // 필터 적용
            if (_selectedType != null) {
              workouts = workouts
                  .where((w) => w.type == _selectedType)
                  .toList();
            }
            if (_selectedSource != null) {
              workouts = workouts
                  .where((w) => w.source == _selectedSource)
                  .toList();
            }

            // 정렬
            workouts = List.from(workouts);
            switch (_sortBy) {
              case 'latest':
                workouts.sort((a, b) => b.startTime.compareTo(a.startTime));
                break;
              case 'oldest':
                workouts.sort((a, b) => a.startTime.compareTo(b.startTime));
                break;
              case 'score_high':
                workouts.sort((a, b) => b.calibratedScore.compareTo(a.calibratedScore));
                break;
              case 'score_low':
                workouts.sort((a, b) => a.calibratedScore.compareTo(b.calibratedScore));
                break;
            }

            if (workouts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '필터 조건에 맞는 운동이 없습니다',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedType = null;
                          _selectedSource = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('필터 초기화'),
                    ),
                  ],
                ),
              );
            }

            // 날짜별 그룹핑
            final groupedWorkouts = _groupWorkoutsByDate(workouts);

            return RefreshIndicator(
              onRefresh: () async {
                context.read<WorkoutBloc>().add(
                      const RefreshWorkoutsEvent(),
                    );
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: groupedWorkouts.length,
                itemBuilder: (context, index) {
                  final entry = groupedWorkouts[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          entry['date'] as String,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      ...((entry['workouts'] as List<WorkoutEntity>).map((workout) {
                        return WorkoutListItem(
                          workout: workout,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkoutDetailPage(workout: workout),
                              ),
                            );
                          },
                        );
                      })),
                    ],
                  );
                },
              ),
            );
          }

          // 초기 상태
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(
        selectedType: _selectedType,
        selectedSource: _selectedSource,
        onApply: (type, source) {
          setState(() {
            _selectedType = type;
            _selectedSource = source;
          });
        },
      ),
    );
  }

  List<Map<String, dynamic>> _groupWorkoutsByDate(List<WorkoutEntity> workouts) {
    final groups = <String, List<WorkoutEntity>>{};

    for (final workout in workouts) {
      final dateKey = _getDateKey(workout.startTime);
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(workout);
    }

    final result = groups.entries.map((entry) {
      return {
        'date': entry.key,
        'workouts': entry.value,
      };
    }).toList();

    return result;
  }

  String _getDateKey(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return '오늘';
    } else if (date == yesterday) {
      return '어제';
    } else if (now.difference(date).inDays < 7) {
      return '${now.difference(date).inDays}일 전';
    } else if (date.year == now.year) {
      return DateFormat('MM월 dd일').format(dateTime);
    } else {
      return DateFormat('yyyy년 MM월 dd일').format(dateTime);
    }
  }
}
