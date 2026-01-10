import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_event.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_state.dart';
import 'package:co_workfit/features/workout/presentation/widgets/workout_list_item.dart';
import 'package:co_workfit/features/workout/presentation/widgets/register_workout_bottom_sheet.dart';
import 'package:co_workfit/features/workout/presentation/pages/workout_detail_page.dart';
import 'package:co_workfit/features/workout/presentation/widgets/filter_bottom_sheet.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:intl/intl.dart';

/// 운동 전체목록 페이지
class WorkoutListPage extends StatefulWidget {
  const WorkoutListPage({super.key});

  @override
  State<WorkoutListPage> createState() => _WorkoutListPageState();

  // DashboardPage에서 새로고침을 트리거할 수 있도록 GlobalKey 제공
  static final GlobalKey<_WorkoutListPageState> globalKey = GlobalKey<_WorkoutListPageState>();
}

class _WorkoutListPageState extends State<WorkoutListPage>
    with AutomaticKeepAliveClientMixin {
  WorkoutType? _selectedType;
  WorkoutSource? _selectedSource;
  String _sortBy = 'latest'; // 'latest', 'oldest', 'duration_high', 'duration_low'

  final ScrollController _scrollController = ScrollController();
  int _loadedDays = 30;
  bool _isLoadingMore = false;
  bool _isAutoLoadingForFilter = false; // 필터용 자동 로드 중인지
  bool _hasReachedEnd = false; // 더 이상 로드할 데이터가 없는지
  List<WorkoutEntity> _allWorkouts = []; // 로컬에서 관리하는 전체 데이터
  int _previousWorkoutCount = 0; // 이전 로드 시 운동 개수 (더 로드할 데이터 있는지 확인용)
  bool _hasLoadedInitialData = false;

  // 필터 결과 최소 개수 (이보다 적으면 자동으로 더 로드)
  static const int _minFilteredResults = 3;
  // 최소 화면 채움 개수 (필터 없이도 이보다 적으면 자동 로드)
  static const int _minScreenFillCount = 5;
  // 최대 로드 일수 (무한 로드 방지)
  static const int _maxLoadDays = 365;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Firestore에 등록된 데이터만 로드 (로컬 Health 데이터는 등록 버튼 클릭 시에만)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoadedInitialData) {
        _hasLoadedInitialData = true;
        _loadInitialData();
      }
    });

    // 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    context.read<WorkoutBloc>().add(const FetchWorkoutsFromFirestoreEvent(days: 30));
  }

  /// 같은 탭을 다시 클릭하거나 pull-to-refresh 시 호출
  void reloadData() {
    _hasReachedEnd = false;
    _loadedDays = 30;
    _loadInitialData();
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
    // 이미 로딩 중이거나, 최대치 도달, 또는 더 이상 데이터 없음
    if (_isLoadingMore || _loadedDays >= _maxLoadDays || _hasReachedEnd) return;

    setState(() {
      _isLoadingMore = true;
      _previousWorkoutCount = _allWorkouts.length;
    });

    final newDays = (_loadedDays + 30).clamp(0, _maxLoadDays);

    // 새로운 범위의 데이터 요청 (Firestore + Health 병합 데이터)
    context.read<WorkoutBloc>().add(FetchWorkoutsFromFirestoreEvent(days: newDays));
  }

  /// 데이터가 적으면 자동으로 더 로드 (필터 유무 관계없이)
  void _checkAndLoadMoreIfNeeded() {
    // 이미 최대치까지 로드했거나 끝에 도달했으면 스킵
    if (_loadedDays >= _maxLoadDays || _hasReachedEnd) {
      _isAutoLoadingForFilter = false;
      return;
    }

    // 필터링된 결과 개수 확인
    var filteredWorkouts = _allWorkouts;
    if (_selectedType != null) {
      filteredWorkouts = filteredWorkouts.where((w) => w.type == _selectedType).toList();
    }
    if (_selectedSource != null) {
      filteredWorkouts = filteredWorkouts.where((w) => w.source == _selectedSource).toList();
    }

    // 필터가 적용된 경우: 최소 필터 결과 개수 확인
    // 필터가 없는 경우: 화면 채움 최소 개수 확인
    final hasFilter = _selectedType != null || _selectedSource != null;
    final minCount = hasFilter ? _minFilteredResults : _minScreenFillCount;

    // 결과가 최소 개수보다 적으면 더 로드
    if (filteredWorkouts.length < minCount && !_isLoadingMore) {
      _isAutoLoadingForFilter = true;
      _loadMoreData();
    } else {
      _isAutoLoadingForFilter = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
      floatingActionButton: _allWorkouts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showSyncConfirmation,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('운동 등록'),
            )
          : null,
      body: BlocConsumer<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          // 운동 등록 상태 처리
          if (state is WorkoutSyncing) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text('운동 데이터를 등록하는 중...'),
                  ],
                ),
                duration: Duration(seconds: 30),
              ),
            );
          } else if (state is WorkoutSyncSuccess) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${state.uploadedCount}개의 운동 기록이 등록되었습니다'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is WorkoutSyncFailure) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('운동 등록 실패: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: '재시도',
                  textColor: Colors.white,
                  onPressed: () {
                    _showSyncConfirmation();
                  },
                ),
              ),
            );
          }

          // 기존 로직
          if (state is WorkoutLoaded) {
            final newWorkouts = state.workouts;
            
            // 더 이상 새 데이터가 없는지 확인 (로드 후 개수가 같으면 끝)
            final noNewData = _isLoadingMore && newWorkouts.length == _previousWorkoutCount;
            
            setState(() {
              _allWorkouts = newWorkouts;
              // 가장 오래된 운동 기준으로 로드된 일수 계산 (정렬과 무관하게)
              if (_allWorkouts.isNotEmpty) {
                final oldestWorkout = _allWorkouts.reduce(
                  (a, b) => a.startTime.isBefore(b.startTime) ? a : b,
                );
                _loadedDays = DateTime.now().difference(oldestWorkout.startTime).inDays + 1;
              } else {
                _loadedDays = 30;
              }
              _isLoadingMore = false;
              
              // 더 이상 데이터가 없거나 최대치 도달
              if (noNewData || _loadedDays >= _maxLoadDays) {
                _hasReachedEnd = true;
              }
            });

            // 데이터가 적으면 자동으로 더 로드 (필터 유무 관계없이)
            _checkAndLoadMoreIfNeeded();
          } else if (state is WorkoutError) {
            setState(() {
              _isLoadingMore = false;
              _isAutoLoadingForFilter = false;
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
                            const FetchWorkoutsFromFirestoreEvent(days: 30),
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
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '등록된 운동 기록이 없습니다',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '기기에 있는 운동 데이터를 등록하고\n챌린지에 참여해보세요!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: _showSyncConfirmation,
                      icon: const Icon(Icons.cloud_upload, size: 24),
                      label: const Text('운동 등록하기', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
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
              case 'duration_high':
                workouts.sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));
                break;
              case 'duration_low':
                workouts.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
                break;
            }

            if (workouts.isEmpty) {
              // 자동 로드 중이면 로딩 표시
              if (_isAutoLoadingForFilter || _isLoadingMore) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        '${_getFilterTypeName()} 기록을 찾는 중...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '최근 $_loadedDays일 검색 중',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
                  ),
                );
              }

              // 최대치까지 로드했는데도 없으면 안내
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '${_getFilterTypeName()} 기록이 없습니다',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    if (_loadedDays >= _maxLoadDays) ...[
                      const SizedBox(height: 8),
                      Text(
                        '(최근 1년간 검색)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
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
                  _hasReachedEnd = false; // 리셋
                  _previousWorkoutCount = 0;
                  // 필터는 유지 (사용자가 필터 상태에서 새로고침할 수 있음)
                });
                context.read<WorkoutBloc>().add(
                      const FetchWorkoutsFromFirestoreEvent(days: 30),
                    );
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: groupedWorkouts.length + 1, // +1 for loading indicator
                itemBuilder: (context, index) {
                  // 마지막 아이템은 로딩 인디케이터 또는 끝 표시
                  if (index == groupedWorkouts.length) {
                    if (_isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (_hasReachedEnd || _loadedDays >= _maxLoadDays) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            '모든 운동 기록을 불러왔습니다',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox(height: 16);
                    }
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
                          onTap: () async {
                            final deleted = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkoutDetailPage(
                                  workout: workout,
                                  isOwner: true, // 본인의 운동 목록
                                ),
                              ),
                            );
                            // 삭제된 경우 목록 새로고침
                            if (deleted == true && context.mounted) {
                              context.read<WorkoutBloc>().add(
                                const FetchWorkoutsFromFirestoreEvent(days: 30),
                              );
                            }
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

  void _showSyncConfirmation() {
    // 운동 등록 Bottom Sheet 표시
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const RegisterWorkoutBottomSheet(),
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
          // 필터 변경 시 자동 로드 체크
          _checkAndLoadMoreIfNeeded();
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

  /// 현재 필터 타입 이름 가져오기
  String _getFilterTypeName() {
    if (_selectedType != null) {
      switch (_selectedType!) {
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
    if (_selectedSource != null) {
      switch (_selectedSource!) {
        case WorkoutSource.appleHealth:
          return 'Apple Health';
        case WorkoutSource.googleFit:
          return 'Google Fit';
        case WorkoutSource.garmin:
          return 'Garmin';
        case WorkoutSource.samsungHealth:
          return 'Samsung Health';
        case WorkoutSource.manual:
          return '수동 입력';
      }
    }
    return '필터 조건에 맞는 운동';
  }
}
