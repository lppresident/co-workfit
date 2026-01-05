import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/domain/usecases/register_selected_workouts.dart';
import 'package:co_workfit/features/workout/domain/utils/strength_score_calculator.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_event.dart';
import 'package:intl/intl.dart';

/// 운동 기록 제출 Bottom Sheet
///
/// Health 데이터에서 직접 선택하여 Firestore 등록 + 챌린지 제출을 한 번에 처리합니다.
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

  // Health 데이터 로딩을 위한 로컬 상태
  bool _isLoading = true;
  String? _errorMessage;
  List<WorkoutEntity> _healthWorkouts = [];
  Set<String> _submittedWorkoutIds = {}; // 이 챌린지에 이미 제출된 운동 ID
  bool _isSubmitting = false;

  late final WorkoutRepository _workoutRepository;
  late final ChallengeRepository _challengeRepository;
  late final RegisterSelectedWorkouts _registerSelectedWorkoutsUseCase;

  @override
  void initState() {
    super.initState();
    _workoutRepository = GetIt.I<WorkoutRepository>();
    _challengeRepository = GetIt.I<ChallengeRepository>();
    _registerSelectedWorkoutsUseCase = GetIt.I<RegisterSelectedWorkouts>();
    _loadHealthWorkouts();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  /// Health에서 운동 데이터 로드 및 챌린지 기여 내역 확인
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

      // 챌린지 기간에 맞춰 데이터 조회 (여유있게 앞뒤로 1일 추가)
      final startDate = widget.startDate.subtract(const Duration(days: 1));
      final endDate = widget.endDate.add(const Duration(days: 1));

      // Health에서 운동 데이터 가져오기
      final workoutsResult = await _workoutRepository.getWorkouts(
        startDate: startDate,
        endDate: endDate,
      );

      // 이 챌린지에 이미 제출된 운동 ID 가져오기
      final contributionsResult = await _challengeRepository.getChallengeContributions(
        widget.challengeId,
      );

      workoutsResult.fold(
        (error) {
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        },
        (workouts) {
          // 이 챌린지에 제출된 workoutId 추출
          final submittedIds = contributionsResult.fold(
            (l) => <String>{},
            (contributions) => contributions.map((c) => c.workoutId).toSet(),
          );

          setState(() {
            _isLoading = false;
            _healthWorkouts = workouts;
            _submittedWorkoutIds = submittedIds;
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
                child: _buildContent(scrollController),
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
                      onPressed: _selectedWorkout == null || _isSubmitting
                          ? null
                          : () => _handleSubmit(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('제출하기'),
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

    // 챌린지 기간 필터링
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

    final validWorkouts = _healthWorkouts.where((workout) {
      final inPeriod = workout.startTime.isAfter(
              startOfStartDate.subtract(const Duration(seconds: 1))) &&
          workout.startTime.isBefore(endOfEndDate.add(const Duration(seconds: 1)));
      return inPeriod;
    }).toList();

    if (validWorkouts.isEmpty) {
      return _buildNoValidWorkoutsView(context);
    }

    return Column(
      children: [
        // 안내 메시지
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '기기의 운동 기록을 선택하면 자동으로 등록 후 제출됩니다',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
        // 운동 목록
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: validWorkouts.length,
            itemBuilder: (context, index) {
              final workout = validWorkouts[index];
              final isSelected = _selectedWorkout?.id == workout.id;
              final isAlreadySubmitted = _submittedWorkoutIds.contains(workout.id);

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
                final intensity =
                    WorkoutIntensityExtension.fromHeartRate(workout.averageHeartRate);
                valueDisplay = '${strengthScore.toStringAsFixed(1)}점 (${intensity.displayName})';
              } else {
                valueDisplay = '${(workout.effectiveDistance ?? 0.0).toStringAsFixed(2)} km';
              }

              return ListTile(
                enabled: !isAlreadySubmitted, // 이미 제출된 운동은 선택 불가
                leading: Icon(
                  _getWorkoutIcon(workout.type),
                  color: isAlreadySubmitted
                      ? Colors.grey
                      : isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                ),
                title: Row(
                  children: [
                    Text(
                      _getWorkoutTypeName(workout.type),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isAlreadySubmitted
                            ? Colors.grey
                            : isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                      ),
                    ),
                    if (isAlreadySubmitted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.blue, width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '제출됨',
                          style: TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      ),
                    ],
                    if (!isAlreadySubmitted && isGarminData && !isStrengthWorkout) ...[
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
                      style: TextStyle(
                        color: isAlreadySubmitted ? Colors.grey : null,
                      ),
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
                trailing: isAlreadySubmitted
                    ? const Icon(Icons.check_circle, color: Colors.grey)
                    : isSelected
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                        : null,
                selected: isSelected,
                onTap: isAlreadySubmitted
                    ? null
                    : () {
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

  /// 운동 기록 제출 (Firestore 등록 + 챌린지 제출)
  Future<void> _submitWorkout(double distance) async {
    if (_selectedWorkout == null) return;

    final workout = _selectedWorkout!;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Firestore에 운동 등록 (이미 등록되어 있으면 use case에서 스킵됨)
      final result = await _registerSelectedWorkoutsUseCase([workout]);

      final failed = result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('운동 등록 실패: ${failure.message}'),
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
          _isSubmitting = false;
        });
        return;
      }

      // 챌린지에 제출
      widget.onSubmit(workout);

      // 운동 탭 새로고침을 위해 이벤트 발생
      if (mounted) {
        context.read<WorkoutBloc>().add(const FetchWorkoutsFromFirestoreEvent(days: 30));
      }

      if (mounted) {
        Navigator.pop(context); // Bottom Sheet 닫기
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('제출 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// 챌린지 기간 내 운동이 없을 때 표시하는 뷰
  Widget _buildNoValidWorkoutsView(BuildContext context) {
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
              '이 기간 내에 운동을 완료한 후 다시 시도해주세요',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadHealthWorkouts,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('새로고침'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
