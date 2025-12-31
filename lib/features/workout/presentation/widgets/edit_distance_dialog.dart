import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_event.dart';

/// 거리 수정 다이얼로그
/// 
/// 운동 목록 페이지와 상세 페이지에서 공통으로 사용됩니다.
class EditDistanceDialog extends StatelessWidget {
  final WorkoutEntity workout;
  final VoidCallback? onDistanceUpdated;
  final VoidCallback? onDistanceReset;

  // 페이스 검증 상수 (초/km)
  // 세계 기록: 마라톤 2'52"/km, 하프 2'44"/km, 10km 2'37"/km
  // 안전 마진을 두고 2'30"/km (150초) 미만이면 비현실적으로 판단
  static const double _minPaceSecondsPerKm = 150.0; // 2분 30초/km

  const EditDistanceDialog({
    super.key,
    required this.workout,
    this.onDistanceUpdated,
    this.onDistanceReset,
  });

  /// 페이스 계산 (초/km)
  double? _calculatePaceSeconds(double distanceKm) {
    if (distanceKm <= 0 || workout.durationSeconds <= 0) return null;
    return workout.durationSeconds / distanceKm;
  }

  /// 페이스를 "분'초"" 형식으로 변환
  String _formatPace(double paceSeconds) {
    final minutes = (paceSeconds / 60).floor();
    final seconds = (paceSeconds % 60).round();
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }

  /// 다이얼로그를 표시하는 편의 메서드
  static Future<void> show({
    required BuildContext context,
    required WorkoutEntity workout,
    VoidCallback? onDistanceUpdated,
    VoidCallback? onDistanceReset,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => EditDistanceDialog(
        workout: workout,
        onDistanceUpdated: onDistanceUpdated,
        onDistanceReset: onDistanceReset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: (workout.effectiveDistance ?? 0.0).toStringAsFixed(2),
    );

    return AlertDialog(
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
              'Garmin 데이터는 거리가 부정확할 수 있습니다.\nGarmin Connect 앱에서 실제 거리를 확인해주세요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            '원래 값: ${(workout.distance ?? 0.0).toStringAsFixed(2)} km',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (workout.hasDistanceCorrection) ...[
            const SizedBox(height: 4),
            Text(
              '현재 수정 값: ${workout.correctedDistance!.toStringAsFixed(2)} km',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
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
        // 수정된 경우에만 초기화 버튼 표시
        if (workout.hasDistanceCorrection)
          TextButton(
            onPressed: () {
              // BLoC에 거리 초기화 이벤트 발생
              context.read<WorkoutBloc>().add(
                    ResetWorkoutDistanceEvent(workoutId: workout.id),
                  );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('원래 거리로 복원되었습니다.'),
                  backgroundColor: Colors.blue,
                ),
              );
              onDistanceReset?.call();
            },
            child: const Text('초기화', style: TextStyle(color: Colors.orange)),
          ),
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

            // 페이스 기반 검증 (세계 기록 수준보다 빠르면 비현실적)
            // 단, 3km 이하는 단거리/중거리일 수 있으므로 검증 스킵
            if (distance > 3.0) {
              final paceSeconds = _calculatePaceSeconds(distance);
              if (paceSeconds != null && paceSeconds < _minPaceSecondsPerKm) {
                final inputPace = _formatPace(paceSeconds);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '입력한 거리가 비현실적입니다.\n'
                      '페이스: $inputPace/km (세계 기록 수준: 2\'30\"/km 이상)',
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
                return;
              }
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
            onDistanceUpdated?.call();
          },
          child: const Text('수정'),
        ),
      ],
    );
  }
}

