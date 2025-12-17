import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 챌린지 초대 코드 공유 BottomSheet
class ShareChallengeBottomSheet extends StatelessWidget {
  final String inviteCode;
  final String challengeName;

  const ShareChallengeBottomSheet({
    super.key,
    required this.inviteCode,
    required this.challengeName,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('초대 코드가 클립보드에 복사되었습니다'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 제목
          Text(
            '친구 초대하기',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // 설명
          Text(
            challengeName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 초대 코드 표시 카드
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '초대 코드',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    inviteCode,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 복사 버튼
          ElevatedButton.icon(
            onPressed: () => _copyToClipboard(context),
            icon: const Icon(Icons.copy),
            label: const Text(
              '코드 복사하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),

          // 안내 텍스트
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '이 코드를 친구에게 공유하여\n통나무런에 초대하세요',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
