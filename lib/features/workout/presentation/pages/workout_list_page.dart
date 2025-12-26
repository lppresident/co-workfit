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

  final ScrollController _scrollController = ScrollController();
  int _loadedDays = 30;
  bool _isLoadingMore = false;
  List<WorkoutEntity> _allWorkouts = []; // 로컬에서 관리하는 전체 데이터

  @override
  void initState() {
    super.initState();
    // 최근 30일 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutBloc>().add(const FetchRecentWorkoutsEvent(days: 30));
    });

    // 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    // 스크롤이 끝에서 200px 이내에 도달하면 더 로드
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _loadMoreData() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final newDays = _loadedDays + 30;

    // 새로운 범위의 데이터 요청
    context.read<WorkoutBloc>().add(FetchRecentWorkoutsEvent(days: newDays));
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
            tooltip: '필터 및 정렬',
          ),
        ],
      ),
      body: BlocConsumer<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          if (state is WorkoutLoaded) {
            setState(() {
              _allWorkouts = state.workouts;
              _loadedDays = (_allWorkouts.isNotEmpty)
                  ? DateTime.now().difference(_allWorkouts.last.startTime).inDays + 1
                  : 30;
              _isLoadingMore = false;
            });
          } else if (state is WorkoutError) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        },
        builder: (context, state) {
          // 초기 로딩 중일 때만 로딩 인디케이터 표시 (데이터가 없을 때)
          if (state is WorkoutLoading && _allWorkouts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WorkoutError && _allWorkouts.isEmpty) {
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

          if (state is WorkoutEmpty && _allWorkouts.isEmpty) {
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

          // 로컬 데이터 사용
          if (_allWorkouts.isNotEmpty) {
            var workouts = _allWorkouts;

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
                setState(() {
                  _loadedDays = 30;
                  _allWorkouts = [];
                });
                context.read<WorkoutBloc>().add(
                      const FetchRecentWorkoutsEvent(days: 30),
                    );
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: groupedWorkouts.length + 1, // +1 for loading indicator
                itemBuilder: (context, index) {
                  // 마지막 아이템은 로딩 인디케이터
                  if (index == groupedWorkouts.length) {
                    return _isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : const SizedBox(height: 16);
                  }

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
                          onEditDistance: workout.distance != null
                              ? () => _showEditDistanceDialog(workout)
                              : null,
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
        sortBy: _sortBy,
        onApply: (type, source, sortBy) {
          setState(() {
            _selectedType = type;
            _selectedSource = source;
            _sortBy = sortBy;
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

  /// 거리 수정 다이얼로그 표시
  void _showEditDistanceDialog(WorkoutEntity workout) {
    final TextEditingController controller = TextEditingController(
      text: (workout.effectiveDistance ?? 0.0).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('거리 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (workout.source == WorkoutSource.garmin) ...[
              const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Garmin 데이터',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Garmin 데이터는 거리가 부정확할 수 있습니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              '원래 값: ${(workout.distance ?? 0.0).toStringAsFixed(2)} km',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '정확한 거리 (km)',
                hintText: '예: 5.63',
                suffixText: 'km',
                border: OutlineInputBorder(),
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
              final input = controller.text.trim();
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

              // BLoC에 거리 수정 이벤트 발생
              context.read<WorkoutBloc>().add(
                    UpdateWorkoutDistanceEvent(
                      workoutId: workout.id,
                      correctedDistance: distance,
                    ),
                  );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('거리가 수정되었습니다.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }
}
