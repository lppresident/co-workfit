import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_event.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';
import 'package:intl/intl.dart';

/// 운동 상세보기 페이지
/// 
/// 운동 데이터는 Firestore 등록 시점에만 수정 가능하며,
/// 등록 이후에는 읽기 전용으로 표시됩니다.
/// 본인의 운동만 삭제 가능합니다.
/// 
/// 챌린지에서 진입한 경우:
/// - 삭제 버튼 대신 "기여 취소" 버튼 표시
/// - 본인 운동인 경우에만 기여 취소 가능
class WorkoutDetailPage extends StatefulWidget {
  final WorkoutEntity workout;
  final bool isOwner;
  
  /// 챌린지에서 진입한 경우 챌린지 ID
  final String? challengeId;
  
  /// 챌린지에서 진입한 경우 contribution ID
  final String? contributionId;

  const WorkoutDetailPage({
    super.key,
    required this.workout,
    this.isOwner = false,
    this.challengeId,
    this.contributionId,
  });
  
  /// 챌린지에서 진입했는지 여부
  bool get isFromChallenge => challengeId != null && contributionId != null;

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late final WorkoutRepository _workoutRepository;
  late final ChallengeRepository _challengeRepository;
  bool _isDeleting = false;
  bool _isCheckingChallenges = false;
  bool _isCancellingContribution = false;
  bool _isCheckingForEdit = false;
  
  /// 현재 표시 중인 운동 (수정 시 업데이트됨)
  late WorkoutEntity _currentWorkout;
  
  final TextEditingController _distanceController = TextEditingController();

  /// 삭제 버튼 표시 여부
  /// - 본인 운동이고
  /// - 챌린지에서 진입하지 않은 경우에만 표시
  bool get _showDeleteButton => widget.isOwner && !widget.isFromChallenge;
  
  /// 기여 취소 버튼 표시 여부
  /// - 본인 운동이고
  /// - 챌린지에서 진입한 경우에만 표시
  bool get _showCancelContributionButton => widget.isOwner && widget.isFromChallenge;
  
  /// 수정 버튼 표시 여부
  /// - 본인 운동이고
  /// - 챌린지에서 진입하지 않은 경우
  /// - 거리 데이터가 있는 운동 (러닝, 걷기, 등산, 사이클링)
  bool get _showEditButton {
    if (!widget.isOwner || widget.isFromChallenge) return false;
    return _currentWorkout.type == WorkoutType.running ||
        _currentWorkout.type == WorkoutType.walking ||
        _currentWorkout.type == WorkoutType.hiking ||
        _currentWorkout.type == WorkoutType.cycling;
  }

  @override
  void initState() {
    super.initState();
    _workoutRepository = GetIt.I<WorkoutRepository>();
    _challengeRepository = GetIt.I<ChallengeRepository>();
    _currentWorkout = widget.workout;
  }
  
  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  WorkoutEntity get workout => _currentWorkout;

  /// 페이스 표시 대상 운동 타입인지 확인
  bool get _shouldShowPace {
    return workout.type == WorkoutType.running ||
        workout.type == WorkoutType.walking ||
        workout.type == WorkoutType.hiking;
  }

  /// 페이스 계산 (분'초"/km 형식)
  /// 초 단위로 정확하게 계산
  /// correctedDistance가 있으면 우선 사용
  String? get _pace {
    final distance = workout.effectiveDistance;
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
          if (_showEditButton)
            IconButton(
              icon: _isCheckingForEdit
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.edit_outlined),
              onPressed: _isCheckingForEdit ? null : _onEditPressed,
              tooltip: '거리 수정',
            ),
          if (_showDeleteButton)
            IconButton(
              icon: (_isDeleting || _isCheckingChallenges)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: (_isDeleting || _isCheckingChallenges) ? null : _onDeletePressed,
              tooltip: '삭제',
            ),
          if (_showCancelContributionButton)
            IconButton(
              icon: _isCancellingContribution
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.remove_circle_outline),
              onPressed: _isCancellingContribution ? null : _onCancelContributionPressed,
              tooltip: '기여 취소',
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

  /// 수정 버튼 클릭 시 처리
  /// 챌린지 제출 여부 확인 후 수정 다이얼로그 표시
  Future<void> _onEditPressed() async {
    setState(() {
      _isCheckingForEdit = true;
    });

    try {
      // 이 운동이 제출된 챌린지가 있는지 확인
      final result = await _challengeRepository.getChallengesByWorkoutId(workout.id);

      if (!mounted) return;

      setState(() {
        _isCheckingForEdit = false;
      });

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('챌린지 확인 실패: ${failure.message}'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        (challengeIds) {
          if (challengeIds.isNotEmpty) {
            // 챌린지에 제출된 운동 - 수정 불가 안내
            _showCannotEditDialog(challengeIds.length);
          } else {
            // 챌린지에 제출되지 않은 운동 - 수정 가능
            _showEditDistanceDialog();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingForEdit = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 챌린지에 제출된 운동은 수정할 수 없음을 안내
  void _showCannotEditDialog(int challengeCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.orange),
            SizedBox(width: 8),
            Text('수정 불가'),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이 운동은 $challengeCount개의 챌린지에 제출되어 있습니다.\n\n'
                      '수정하려면 먼저 해당 챌린지에서 이 운동 기록을 제거해주세요.',
                      style: const TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 거리 수정 다이얼로그 표시
  void _showEditDistanceDialog() {
    final currentDistance = workout.effectiveDistance ?? 0.0;
    _distanceController.text = currentDistance.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 8),
            Text('거리 수정'),
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
            Text(
              DateFormat('yyyy년 MM월 dd일 HH:mm').format(workout.startTime),
              style: TextStyle(color: Colors.grey[600]),
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
                helperText: workout.distance != null
                    ? '원본 거리: ${workout.distance!.toStringAsFixed(2)} km'
                    : null,
              ),
              autofocus: true,
            ),
            if (workout.hasDistanceCorrection) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '현재 수정된 거리가 적용되어 있습니다.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          if (workout.hasDistanceCorrection)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _resetDistance();
              },
              child: const Text('원본으로 복원'),
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

              Navigator.pop(dialogContext);
              _updateDistance(distance);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  /// 거리 업데이트 실행
  Future<void> _updateDistance(double newDistance) async {
    final result = await _workoutRepository.updateWorkoutDistance(
      workoutId: workout.id,
      correctedDistance: newDistance,
    );

    if (!mounted) return;

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정 실패: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        // 로컬 상태 업데이트
        setState(() {
          _currentWorkout = _currentWorkout.copyWith(correctedDistance: newDistance);
        });
        
        // 운동 목록 새로고침
        context.read<WorkoutBloc>().add(const FetchWorkoutsFromFirestoreEvent(days: 30));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('거리가 수정되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  /// 거리 원본으로 복원
  Future<void> _resetDistance() async {
    final result = await _workoutRepository.resetWorkoutDistance(workoutId: workout.id);

    if (!mounted) return;

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('복원 실패: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        // 로컬 상태 업데이트 - correctedDistance를 null로
        setState(() {
          _currentWorkout = _currentWorkout.copyWith(clearCorrectedDistance: true);
        });
        
        // 운동 목록 새로고침
        context.read<WorkoutBloc>().add(const FetchWorkoutsFromFirestoreEvent(days: 30));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('원본 거리로 복원되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  /// 삭제 버튼 클릭 시 처리
  /// 운동탭에서 진입한 경우에만 호출됨 (챌린지에서는 삭제 버튼 숨김)
  Future<void> _onDeletePressed() async {
    // 다른 챌린지 제출 여부 확인
    setState(() {
      _isCheckingChallenges = true;
    });

    try {
      // 이 운동이 제출된 챌린지가 있는지 확인
      final result = await _challengeRepository.getChallengesByWorkoutId(workout.id);

      if (!mounted) return;

      setState(() {
        _isCheckingChallenges = false;
      });

      result.fold(
        (failure) {
          // 확인 실패 시에도 삭제 다이얼로그 표시 (안전하게)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('챌린지 확인 실패: ${failure.message}'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        (challengeIds) {
          if (challengeIds.isNotEmpty) {
            // 챌린지에 제출된 운동 - 삭제 불가 안내
            _showCannotDeleteDialog(challengeIds.length);
          } else {
            // 챌린지에 제출되지 않은 운동 - 삭제 가능
            _showDeleteConfirmDialog();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingChallenges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 기여 취소 버튼 클릭 시 처리
  void _onCancelContributionPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.remove_circle_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('기여 취소'),
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
            Text(
              DateFormat('yyyy년 MM월 dd일 HH:mm').format(workout.startTime),
              style: TextStyle(color: Colors.grey[600]),
            ),
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
                      '이 챌린지에서 해당 운동 기여를 취소합니다.\n운동 기록 자체는 삭제되지 않습니다.',
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
              _cancelContribution();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('기여 취소'),
          ),
        ],
      ),
    );
  }

  /// 기여 취소 실행
  Future<void> _cancelContribution() async {
    if (widget.challengeId == null || widget.contributionId == null) return;

    setState(() {
      _isCancellingContribution = true;
    });

    try {
      final result = await _challengeRepository.deleteContribution(
        challengeId: widget.challengeId!,
        contributionId: widget.contributionId!,
        userId: workout.userId,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('기여 취소 실패: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isCancellingContribution = false;
          });
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('기여가 취소되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // true를 반환하여 변경되었음을 알림
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCancellingContribution = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 챌린지에 제출된 운동은 삭제할 수 없음을 안내
  void _showCannotDeleteDialog(int challengeCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.orange),
            SizedBox(width: 8),
            Text('삭제 불가'),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이 운동은 $challengeCount개의 챌린지에 제출되어 있습니다.\n\n'
                      '삭제하려면 먼저 해당 챌린지에서 이 운동 기록을 제거해주세요.',
                      style: const TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 삭제 확인 다이얼로그 표시
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('운동 기록 삭제'),
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
            Text(
              DateFormat('yyyy년 MM월 dd일 HH:mm').format(workout.startTime),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '삭제된 운동 기록은 복구할 수 없습니다.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
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
              _deleteWorkout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 운동 삭제 실행
  Future<void> _deleteWorkout() async {
    setState(() {
      _isDeleting = true;
    });

    final result = await _workoutRepository.deleteWorkout(workout.id);

    result.fold(
      (error) {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (success) {
        if (mounted) {
          // 운동 목록 새로고침
          context.read<WorkoutBloc>().add(const FetchWorkoutsFromFirestoreEvent(days: 30));
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('운동 기록이 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // true를 반환하여 삭제되었음을 알림
        }
      },
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
            if (workout.effectiveDistance != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                context,
                Icons.straighten,
                '거리',
                '${workout.effectiveDistance!.toStringAsFixed(2)} km${workout.hasDistanceCorrection ? ' (수정됨)' : ''}',
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
