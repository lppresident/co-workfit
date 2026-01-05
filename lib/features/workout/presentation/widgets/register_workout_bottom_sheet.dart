import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_event.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/domain/usecases/register_selected_workouts.dart';
import 'package:co_workfit/features/workout/domain/utils/strength_score_calculator.dart';
import 'package:intl/intl.dart';

/// 운동 선택 및 등록 Bottom Sheet
/// 
/// 이 위젯은 Health 데이터를 직접 로드하여 로컬 상태로 관리합니다.
/// 여러 운동을 선택하여 한번에 등록할 수 있습니다.
/// 등록 시 각 운동의 거리/점수를 확인하고 수정할 수 있습니다.
class RegisterWorkoutBottomSheet extends StatefulWidget {
  const RegisterWorkoutBottomSheet({super.key});

  @override
  State<RegisterWorkoutBottomSheet> createState() => _RegisterWorkoutBottomSheetState();
}

class _RegisterWorkoutBottomSheetState extends State<RegisterWorkoutBottomSheet> {
  Set<String> _selectedWorkoutIds = {}; // 다중 선택
  List<WorkoutEntity> _availableWorkouts = [];
  Set<String> _registeredWorkoutIds = {};
  
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRegistering = false;
  
  final TextEditingController _valueController = TextEditingController();

  late final WorkoutRepository _workoutRepository;
  late final RegisterSelectedWorkouts _registerSelectedWorkoutsUseCase;

  @override
  void initState() {
    super.initState();
    _workoutRepository = GetIt.I<WorkoutRepository>();
    _registerSelectedWorkoutsUseCase = GetIt.I<RegisterSelectedWorkouts>();
    _loadHealthWorkouts();
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthWorkouts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 권한 요청
      final permissionResult = await _workoutRepository.requestHealthAuthorization();
      if (permissionResult.isLeft()) {
        setState(() {
          _isLoading = false;
          _errorMessage = permissionResult.fold((l) => l, (r) => '권한 요청 실패');
        });
        return;
      }

      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));

      // Health에서 운동 데이터 가져오기
      final workoutsResult = await _workoutRepository.getWorkouts(
        startDate: startDate,
        endDate: now,
      );

      // Firestore에서 등록된 운동 ID 가져오기
      final registeredIdsResult = await _workoutRepository.getRegisteredWorkoutIds(
        startDate: startDate,
        endDate: now,
      );

      workoutsResult.fold(
        (error) {
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        },
        (workouts) {
          final registeredIds = registeredIdsResult.fold(
            (l) => <String>{},
            (r) => r,
          );

          setState(() {
            _isLoading = false;
            _availableWorkouts = workouts;
            _registeredWorkoutIds = registeredIds;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '운동 데이터를 불러오는 중 오류가 발생했습니다: $e';
      });
    }
  }

  /// 운동 선택 토글 (다중 선택)
  void _toggleWorkoutSelection(WorkoutEntity workout) {
    // 이미 등록된 운동은 선택 불가
    if (_registeredWorkoutIds.contains(workout.id)) return;

    setState(() {
      if (_selectedWorkoutIds.contains(workout.id)) {
        _selectedWorkoutIds.remove(workout.id);
      } else {
        _selectedWorkoutIds.add(workout.id);
      }
    });
  }
  
  /// 전체 선택/해제
  void _toggleSelectAll() {
    final unregisteredWorkouts = _availableWorkouts
        .where((w) => !_registeredWorkoutIds.contains(w.id))
        .toList();
    
    setState(() {
      if (_selectedWorkoutIds.length == unregisteredWorkouts.length) {
        // 모두 선택된 상태 -> 전체 해제
        _selectedWorkoutIds.clear();
      } else {
        // 일부만 선택 또는 미선택 -> 전체 선택
        _selectedWorkoutIds = unregisteredWorkouts.map((w) => w.id).toSet();
      }
    });
  }
  
  /// 선택된 운동 목록 가져오기
  List<WorkoutEntity> get _selectedWorkouts {
    return _availableWorkouts
        .where((w) => _selectedWorkoutIds.contains(w.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                    const Text(
                      '운동 등록',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 운동 목록
              Expanded(
                child: _buildContent(scrollController),
              ),

              // 등록 버튼
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
                    child: ElevatedButton.icon(
                      onPressed: _selectedWorkoutIds.isEmpty || _isRegistering
                          ? null
                          : () => _showRegisterConfirmDialog(),
                      icon: _isRegistering
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(
                        _isRegistering
                            ? '등록 중...'
                            : _selectedWorkoutIds.isEmpty
                                ? '운동을 선택해주세요'
                                : '${_selectedWorkoutIds.length}개 운동 등록',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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

  Widget _buildContent(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text(
                '운동 기록을 불러올 수 없습니다',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadHealthWorkouts,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_availableWorkouts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                '최근 30일간 운동 기록이 없습니다',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '운동을 완료한 후 다시 시도해주세요',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final unregisteredCount = _availableWorkouts
        .where((w) => !_registeredWorkoutIds.contains(w.id))
        .length;

    final isAllSelected = _selectedWorkoutIds.length == unregisteredCount && unregisteredCount > 0;
    
    return Column(
      children: [
        // 상태 표시 바
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              // 전체 선택 체크박스
              if (unregisteredCount > 0)
                InkWell(
                  onTap: _toggleSelectAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAllSelected
                            ? Icons.check_box
                            : _selectedWorkoutIds.isNotEmpty
                                ? Icons.indeterminate_check_box
                                : Icons.check_box_outline_blank,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '전체',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedWorkoutIds.isEmpty
                      ? '미등록: $unregisteredCount개'
                      : '${_selectedWorkoutIds.length}개 선택됨',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (_registeredWorkoutIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '등록됨: ${_registeredWorkoutIds.length}개',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 운동 목록
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: _availableWorkouts.length,
            itemBuilder: (context, index) {
              final workout = _availableWorkouts[index];
              final isRegistered = _registeredWorkoutIds.contains(workout.id);
              final isSelected = _selectedWorkoutIds.contains(workout.id);

              return Opacity(
                opacity: isRegistered ? 0.5 : 1.0,
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: isRegistered ? null : (_) => _toggleWorkoutSelection(workout),
                  title: Row(
                    children: [
                      Icon(
                        _getWorkoutIcon(workout.type),
                        size: 20,
                        color: isRegistered
                            ? Colors.grey
                            : isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getWorkoutTypeName(workout.type),
                          style: TextStyle(
                            fontWeight:
                                isSelected && !isRegistered ? FontWeight.bold : FontWeight.normal,
                            color: isRegistered ? Colors.grey : null,
                          ),
                        ),
                      ),
                      if (isRegistered)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '등록됨',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('yyyy.MM.dd HH:mm').format(workout.startTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: isRegistered ? Colors.grey : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getWorkoutDetails(workout),
                        style: TextStyle(
                          fontSize: 12,
                          color: isRegistered
                              ? Colors.grey
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isRegistered
                          ? Colors.grey[200]
                          : isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${workout.durationMinutes}분',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isRegistered
                            ? Colors.grey
                            : isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 등록 확인 다이얼로그 표시
  void _showRegisterConfirmDialog() {
    if (_selectedWorkoutIds.isEmpty) return;

    final selectedWorkouts = _selectedWorkouts;
    
    // 단일 선택인 경우 기존 로직 (거리/점수 확인)
    if (selectedWorkouts.length == 1) {
      final workout = selectedWorkouts.first;
      final isStrengthWorkout = workout.type == WorkoutType.weightTraining;

      if (isStrengthWorkout) {
        // 웨이트 트레이닝: 점수 확인
        final strengthScore = StrengthScoreCalculator.calculateStrengthScore(
          durationMinutes: workout.durationMinutes,
          avgHeartRate: workout.averageHeartRate,
        );
        _showStrengthConfirmDialog(strengthScore, workout);
      } else {
        // 유산소 운동: 거리 확인
        _showDistanceConfirmDialog(workout);
      }
    } else {
      // 다중 선택인 경우 일괄 등록 확인
      _showBatchRegisterConfirmDialog(selectedWorkouts);
    }
  }
  
  /// 다중 운동 일괄 등록 확인 다이얼로그
  void _showBatchRegisterConfirmDialog(List<WorkoutEntity> workouts) {
    final cardioCount = workouts.where((w) => 
      w.type != WorkoutType.weightTraining && 
      w.type != WorkoutType.yoga
    ).length;
    final strengthCount = workouts.where((w) => 
      w.type == WorkoutType.weightTraining || 
      w.type == WorkoutType.yoga
    ).length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.blue),
            SizedBox(width: 8),
            Text('운동 일괄 등록'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${workouts.length}개의 운동을 등록합니다.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (cardioCount > 0)
              Text('• 유산소 운동: $cardioCount개'),
            if (strengthCount > 0)
              Text('• 근력 운동: $strengthCount개'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '일괄 등록 시 거리는 원본 데이터로 등록됩니다.\n'
                      '거리 수정이 필요하면 등록 후 운동 상세에서 수정하세요.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
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
              Navigator.pop(context);
              _registerWorkouts(workouts);
            },
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }

  /// 웨이트 트레이닝 점수 확인 다이얼로그
  void _showStrengthConfirmDialog(double score, WorkoutEntity workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fitness_center, color: Colors.orange),
            SizedBox(width: 8),
            Text('운동 점수 확인'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getWorkoutTypeName(workout.type)} - ${workout.durationMinutes}분',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '${score.toStringAsFixed(1)} 점',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '운동 시간과 심박수를 기반으로 계산된 점수입니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              Navigator.pop(context);
              _registerWorkouts([workout]);
            },
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }

  /// 거리 확인/수정 다이얼로그
  void _showDistanceConfirmDialog(WorkoutEntity workout) {
    final originalDistance = workout.distance ?? 0.0;
    _valueController.text = originalDistance.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.straighten, color: Colors.blue),
            SizedBox(width: 8),
            Text('거리 확인'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getWorkoutTypeName(workout.type)} - ${workout.durationMinutes}분',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '거리를 확인하고 필요 시 수정해주세요.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '등록 후에도 운동 상세에서 수정할 수 있습니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: '거리 (km)',
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
              final input = _valueController.text.trim();
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

              Navigator.pop(context);
              _registerWorkoutWithDistance(workout, distance);
            },
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }

  /// 운동 일괄 등록
  Future<void> _registerWorkouts(List<WorkoutEntity> workouts) async {
    if (workouts.isEmpty) return;

    setState(() {
      _isRegistering = true;
    });

    final result = await _registerSelectedWorkoutsUseCase(workouts);

    result.fold(
      (failure) {
        setState(() {
          _isRegistering = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('등록 실패: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (count) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count개의 운동이 등록되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          context.read<WorkoutBloc>().add(const FetchWorkoutsFromFirestoreEvent(days: 30));
        }
      },
    );
  }

  /// 운동 등록 (거리 수정 포함 - 단일 운동)
  Future<void> _registerWorkoutWithDistance(WorkoutEntity workout, double distance) async {
    setState(() {
      _isRegistering = true;
    });

    try {
      // 수정된 거리를 포함한 운동 엔티티 생성
      // correctedDistance 필드에 수정된 거리를 저장
      final workoutToRegister = workout.copyWith(
        correctedDistance: distance,
      );

      // 수정된 거리가 포함된 운동을 바로 등록
      final result = await _registerSelectedWorkoutsUseCase([workoutToRegister]);

      final failed = result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('등록 실패: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return true;
        },
        (count) => false,
      );

      if (failed) {
        setState(() {
          _isRegistering = false;
        });
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('운동이 등록되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        context.read<WorkoutBloc>().add(const FetchWorkoutsFromFirestoreEvent(days: 30));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('등록 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isRegistering = false;
        });
      }
    }
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

  String _getWorkoutDetails(WorkoutEntity workout) {
    final parts = <String>[];

    if (workout.distance != null && workout.distance! > 0) {
      parts.add('${workout.effectiveDistance?.toStringAsFixed(2) ?? '0.00'} km');
    }

    if (workout.durationMinutes > 0) {
      parts.add('${workout.durationMinutes}분');
    }

    if (workout.calories != null && workout.calories! > 0) {
      parts.add('${workout.calories} kcal');
    }

    return parts.join(' • ');
  }
}

