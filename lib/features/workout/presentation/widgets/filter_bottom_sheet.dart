import 'package:flutter/material.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

/// 운동 필터 바텀시트
class FilterBottomSheet extends StatefulWidget {
  final WorkoutType? selectedType;
  final WorkoutSource? selectedSource;
  final Function(WorkoutType?, WorkoutSource?) onApply;

  const FilterBottomSheet({
    super.key,
    this.selectedType,
    this.selectedSource,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  WorkoutType? _selectedType;
  WorkoutSource? _selectedSource;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedSource = widget.selectedSource;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '필터',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 운동 타입 필터
          Text(
            '운동 타입',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTypeChip(null, '전체', Icons.all_inclusive),
              ...WorkoutType.values.map((type) {
                return _buildTypeChip(
                  type,
                  _getWorkoutTypeName(type),
                  _getWorkoutIcon(type),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),

          // 데이터 소스 필터
          Text(
            '데이터 소스',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSourceChip(null, '전체', Icons.all_inclusive),
              ...WorkoutSource.values.map((source) {
                return _buildSourceChip(
                  source,
                  _getSourceName(source),
                  _getSourceIcon(source),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),

          // 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedType = null;
                      _selectedSource = null;
                    });
                  },
                  child: const Text('초기화'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedType, _selectedSource);
                    Navigator.pop(context);
                  },
                  child: const Text('적용'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTypeChip(WorkoutType? type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
    );
  }

  Widget _buildSourceChip(WorkoutSource? source, String label, IconData icon) {
    final isSelected = _selectedSource == source;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedSource = selected ? source : null;
        });
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
        return '웨이트';
      case WorkoutType.yoga:
        return '요가';
      case WorkoutType.hiking:
        return '등산';
      case WorkoutType.other:
        return '기타';
    }
  }

  IconData _getSourceIcon(WorkoutSource source) {
    switch (source) {
      case WorkoutSource.appleHealth:
        return Icons.apple;
      case WorkoutSource.googleFit:
        return Icons.android;
      case WorkoutSource.garmin:
        return Icons.watch;
      case WorkoutSource.samsungHealth:
        return Icons.smartphone;
      case WorkoutSource.manual:
        return Icons.edit;
    }
  }

  String _getSourceName(WorkoutSource source) {
    switch (source) {
      case WorkoutSource.appleHealth:
        return 'Apple';
      case WorkoutSource.googleFit:
        return 'Google Fit';
      case WorkoutSource.garmin:
        return 'Garmin';
      case WorkoutSource.samsungHealth:
        return 'Samsung';
      case WorkoutSource.manual:
        return '수동';
    }
  }
}
