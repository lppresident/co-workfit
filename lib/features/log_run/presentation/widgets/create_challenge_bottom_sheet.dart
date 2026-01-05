import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateChallengeBottomSheet extends StatefulWidget {
  final Function(double targetWeight, DateTime challengeDate, int? maxParticipants) onCreate;

  const CreateChallengeBottomSheet({super.key, required this.onCreate});

  @override
  State<CreateChallengeBottomSheet> createState() => _CreateChallengeBottomSheetState();
}

class _CreateChallengeBottomSheetState extends State<CreateChallengeBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  double _targetWeight = 10.0;
  late DateTime _challengeDate;
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
              Row(
                children: [
                  const Text(
                    '🏋️',
                    style: TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '새 챌린지 만들기',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '친구들과 함께 목표를 달성하세요!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // 목표 무게 입력
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '목표 무게 (kg)',
                  border: OutlineInputBorder(),
                  suffixText: 'kg',
                  helperText: '달리기: 1km = 1kg, 기타: 100kcal = 1kg',
                ),
                keyboardType: TextInputType.number,
                initialValue: '10',
                validator: (value) {
                  if (value == null || value.isEmpty) return '목표를 입력하세요';
                  final target = double.tryParse(value);
                  if (target == null || target <= 0) return '올바른 숫자를 입력하세요';
                  if (target > 100) return '목표는 100kg 이하로 설정하세요';
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
                    widget.onCreate(_targetWeight, _challengeDate, null);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green[700],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🏋️',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '챌린지 만들기',
                      style: TextStyle(fontSize: 16, color: Colors.white),
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
}
