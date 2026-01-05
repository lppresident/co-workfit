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

  /// Health + Firestore 병합 데이터 로드 및 챌린지 기여 내역 확인
  /// Firestore에 등록된 운동은 correctedDistance가 반영된 데이터를 사용
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

      // Health + Firestore 병합 데이터 가져오기
      // Firestore에 등록된 운동은 correctedDistance가 포함된 데이터 사용
      final workoutsResult = await _workoutRepository.getMergedWorkouts(
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
              final isRegisteredToFirestore = workout.syncedAt != null; // Firestore 등록 여부

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
                // effectiveDistance 사용 (correctedDistance가 있으면 우선)
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
                    ] else if (isRegisteredToFirestore) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.green, width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '등록됨',
                          style: TextStyle(fontSize: 10, color: Colors.green),
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
                            // effectiveDistance 사용 (correctedDistance가 있으면 우선)
                            _distanceController.text = (workout.effectiveDistance ?? 0.0).toStringAsFixed(2);
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
    final isAlreadyRegistered = workout.syncedAt != null; // Firestore에 등록된 운동인지 확인

    // 웨이트 트레이닝: 점수로 바로 제출
    if (isStrengthWorkout) {
      final strengthScore = StrengthScoreCalculator.calculateStrengthScore(
        durationMinutes: workout.durationMinutes,
        avgHeartRate: workout.averageHeartRate,
      );
      _submitWorkout(strengthScore);
      return;
    }

    // 이미 Firestore에 등록된 운동: 거리 수정 없이 바로 제출
    // (등록 시점에 이미 거리가 확정됨)
    if (isAlreadyRegistered) {
      _submitWorkoutDirectly();
      return;
    }

    // 기기에서 가져온 운동 (미등록): 거리 확인 다이얼로그 표시
    // (등록 시점에만 수정 가능)
    _showDistanceConfirmDialog();
  }

  /// 거리 확인 다이얼로그 표시
  /// 등록 시점에만 거리 수정이 가능하며, 이후에는 수정할 수 없습니다.
  void _showDistanceConfirmDialog() {
    final originalDistance = _selectedWorkout!.distance ?? 0.0;
    _distanceController.text = originalDistance.toStringAsFixed(2);

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
                      '등록 후에는 거리를 수정할 수 없습니다.\n정확한 거리를 입력해주세요.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: '거리 (km)',
                hintText: '예: 5.63',
                suffixText: 'km',
                border: const OutlineInputBorder(),
                helperText: '기기 기록: ${originalDistance.toStringAsFixed(2)} km',
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
              _submitWorkoutWithDistance(distance);
            },
            child: const Text('제출'),
          ),
        ],
      ),
    );
  }

  /// 운동 기록 제출 (웨이트 트레이닝용 - 점수 기반, Firestore 등록 포함)
  Future<void> _submitWorkout(double score) async {
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

  /// 이미 Firestore에 등록된 운동 직접 제출 (거리 수정 없음)
  Future<void> _submitWorkoutDirectly() async {
    if (_selectedWorkout == null) return;

    final workout = _selectedWorkout!;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 이미 Firestore에 등록된 운동이므로 바로 챌린지에 제출
      widget.onSubmit(workout);

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

  /// 운동 기록 제출 (달리기 운동용 - 거리 기반, 수정된 거리 포함)
  Future<void> _submitWorkoutWithDistance(double distance) async {
    if (_selectedWorkout == null) return;

    final workout = _selectedWorkout!;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 사용자가 입력한 거리를 correctedDistance로 저장
      // (원본 distance는 유지, correctedDistance에 수정된 값 저장)
      final workoutWithDistance = workout.copyWith(correctedDistance: distance);

      // Firestore에 운동 등록 (수정된 거리 포함)
      final result = await _registerSelectedWorkoutsUseCase([workoutWithDistance]);

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

      // 챌린지에 제출 (수정된 거리 포함)
      widget.onSubmit(workoutWithDistance);

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
