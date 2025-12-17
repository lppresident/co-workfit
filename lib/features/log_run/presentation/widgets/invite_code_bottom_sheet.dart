import 'package:flutter/material.dart';
import 'package:co_workfit/features/log_run/domain/utils/invite_code_generator.dart';

/// 초대 코드 입력 BottomSheet
class InviteCodeBottomSheet extends StatefulWidget {
  final Function(String inviteCode) onJoin;

  const InviteCodeBottomSheet({super.key, required this.onJoin});

  @override
  State<InviteCodeBottomSheet> createState() => _InviteCodeBottomSheetState();
}

class _InviteCodeBottomSheetState extends State<InviteCodeBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final normalizedCode = InviteCodeGenerator.normalize(_codeController.text);
      Navigator.of(context).pop();
      widget.onJoin(normalizedCode);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목
            Text(
              '초대 코드로 참가하기',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // 설명
            Text(
              '친구로부터 받은 6자리 초대 코드를 입력하세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // 초대 코드 입력 필드
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: '초대 코드',
                border: const OutlineInputBorder(),
                hintText: '예: A3K9M2',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 4,
                ),
                counterText: '',
              ),
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '초대 코드를 입력하세요';
                }
                final normalizedCode = InviteCodeGenerator.normalize(value);
                if (!InviteCodeGenerator.isValid(normalizedCode)) {
                  return '올바른 초대 코드 형식이 아닙니다 (6자리 영숫자)';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
            const SizedBox(height: 24),

            // 참가 버튼
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '참가하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
