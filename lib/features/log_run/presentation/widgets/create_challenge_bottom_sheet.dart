import 'package:co_workfit/features/log_run/domain/entities/workout_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateChallengeBottomSheet extends StatefulWidget {
  final Function(double targetWeight, DateTime challengeDate, int? maxParticipants, ChallengeType challengeType) onCreate;

  const CreateChallengeBottomSheet({super.key, required this.onCreate});

  @override
  State<CreateChallengeBottomSheet> createState() => _CreateChallengeBottomSheetState();
}

class _CreateChallengeBottomSheetState extends State<CreateChallengeBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  double _targetWeight = 10.0;
  late DateTime _challengeDate;
  ChallengeType _challengeType = ChallengeType.running;
  final DateFormat _dateFormat = DateFormat('yyyy.MM.dd (E)', 'ko');

  @override
  void initState() {
    super.initState();
    // 기본값: 오늘
    _challengeDate = DateTime.now();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _challengeDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _challengeDate) {
      setState(() {
        _challengeDate = picked;
      });
    }
  }

  String get _targetLabel {
    return _challengeType == ChallengeType.running ? '목표 거리 (km)' : '목표 점수';
  }

  String get _targetSuffix {
    return _challengeType == ChallengeType.running ? 'km' : '점';
  }

  String get _description {
    return _challengeType == ChallengeType.running 
        ? '목표 거리를 설정하세요 (1kg = 1km)' 
        : '목표 점수를 설정하세요 (시간 × 강도)';
  }

  double get _maxTarget {
    return _challengeType == ChallengeType.running ? 100.0 : 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '새 챌린지 만들기',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 운동 타입 선택
              Text(
                '운동 타입',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildChallengeTypeSelector(),
              const SizedBox(height: 8),
              Text(
                _description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 목표 입력
              TextFormField(
                key: ValueKey(_challengeType), // 운동 타입 변경시 리빌드
                decoration: InputDecoration(
                  labelText: _targetLabel,
                  border: const OutlineInputBorder(),
                  suffixText: _targetSuffix,
                ),
                keyboardType: TextInputType.number,
                initialValue: _challengeType == ChallengeType.running ? '10' : '100',
                validator: (value) {
                  if (value == null || value.isEmpty) return '목표를 입력하세요';
                  final target = double.tryParse(value);
                  if (target == null || target <= 0) return '올바른 숫자를 입력하세요';
                  if (target > _maxTarget) {
                    return '목표는 ${_maxTarget.toStringAsFixed(0)} 이하로 설정하세요';
                  }
                  return null;
                },
                onSaved: (value) => _targetWeight = double.parse(value!),
              ),
              const SizedBox(height: 16),

              // 날짜 설정
              Text(
                '챌린지 날짜',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '날짜 선택',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_dateFormat.format(_challengeDate)),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '선택한 날짜의 운동 기록만 제출할 수 있습니다',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    widget.onCreate(_targetWeight, _challengeDate, null, _challengeType);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: _challengeType == ChallengeType.running
                      ? Colors.brown[600]
                      : Colors.blueGrey[700],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _challengeType.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_challengeType.displayName} 챌린지 만들기',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption(
              challengeType: ChallengeType.running,
              emoji: '🏃',
              label: '달리기',
              subLabel: '거리 기반',
              color: Colors.brown,
            ),
          ),
          Expanded(
            child: _buildTypeOption(
              challengeType: ChallengeType.strengthTraining,
              emoji: '🏋️',
              label: '헬스',
              subLabel: '시간×강도',
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required ChallengeType challengeType,
    required String emoji,
    required String label,
    required String subLabel,
    required Color color,
  }) {
    final isSelected = _challengeType == challengeType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _challengeType = challengeType;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white.withValues(alpha: 0.8) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
