import 'package:flutter/material.dart';

class CreateChallengeBottomSheet extends StatefulWidget {
  final Function(double targetWeight) onCreate;

  const CreateChallengeBottomSheet({super.key, required this.onCreate});

  @override
  State<CreateChallengeBottomSheet> createState() => _CreateChallengeBottomSheetState();
}

class _CreateChallengeBottomSheetState extends State<CreateChallengeBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  double _targetWeight = 10.0;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('새 통나무런 만들기', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('목표 통나무 무게를 설정하세요 (1kg = 1km)', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  widget.onCreate(_targetWeight);
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
    );
  }
}
