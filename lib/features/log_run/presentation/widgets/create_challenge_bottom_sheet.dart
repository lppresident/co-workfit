import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateChallengeBottomSheet extends StatefulWidget {
  final Function(double targetWeight, DateTime startDate, DateTime endDate, int? maxParticipants) onCreate;

  const CreateChallengeBottomSheet({super.key, required this.onCreate});

  @override
  State<CreateChallengeBottomSheet> createState() => _CreateChallengeBottomSheetState();
}

class _CreateChallengeBottomSheetState extends State<CreateChallengeBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  double _targetWeight = 10.0;
  late DateTime _startDate;
  late DateTime _endDate;
  final DateFormat _dateFormat = DateFormat('yyyy.MM.dd');

  @override
  void initState() {
    super.initState();
    // 기본값: 오늘부터 7일 후까지
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // 종료일이 시작일보다 이전이면 시작일과 동일하게 조정
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 90)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = _endDate.difference(_startDate).inDays;

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
              Text('새 통나무런 만들기', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('목표 통나무 무게를 설정하세요 (1kg = 1km)', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 24),

              // 목표 무게 입력
              TextFormField(
                decoration: const InputDecoration(labelText: '목표 무게 (kg)', border: OutlineInputBorder(), suffixText: 'kg'),
                keyboardType: TextInputType.number,
                initialValue: '10',
                validator: (value) {
                  if (value == null || value.isEmpty) return '목표 무게를 입력하세요';
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) return '올바른 숫자를 입력하세요';
                  if (weight > 100) return '목표 무게는 100kg 이하로 설정하세요';
                  return null;
                },
                onSaved: (value) => _targetWeight = double.parse(value!),
              ),
              const SizedBox(height: 16),

              // 기간 설정
              Text('챌린지 기간', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '시작일',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_dateFormat.format(_startDate)),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('~'),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _selectEndDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '종료일',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_dateFormat.format(_endDate)),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '총 $duration일 동안 진행됩니다',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // 종료일은 해당 날짜의 23:59:59로 설정
                    final endDateTime = DateTime(
                      _endDate.year,
                      _endDate.month,
                      _endDate.day,
                      23,
                      59,
                      59,
                    );
                    widget.onCreate(_targetWeight, _startDate, endDateTime, null);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('만들기', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
