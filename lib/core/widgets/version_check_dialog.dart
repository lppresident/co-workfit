import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 버전 업데이트 필수 다이얼로그
class VersionCheckDialog extends StatelessWidget {
  final String currentVersion;
  final String minimumVersion;

  const VersionCheckDialog({
    super.key,
    required this.currentVersion,
    required this.minimumVersion,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 뒤로가기 버튼 비활성화
      child: AlertDialog(
        title: const Text(
          '업데이트 필요',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '새로운 버전이 출시되었습니다.\n최신 버전으로 업데이트해주세요.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              '현재 버전: $currentVersion',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '최소 버전: $minimumVersion',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 스토어로 이동
              if (Platform.isAndroid) {
                // Google Play Store
                final url = Uri.parse('https://play.google.com/store/apps/details?id=com.hansol.coworkfit');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                SystemNavigator.pop();
              } else if (Platform.isIOS) {
                // App Store
                final url = Uri.parse('https://apps.apple.com/app/id YOUR_APP_ID');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                // iOS는 앱을 종료하지 않음 (Apple 가이드라인 준수)
              }
            },
            child: const Text(
              '업데이트',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 다이얼로그 표시
  static Future<void> show(
    BuildContext context, {
    required String currentVersion,
    required String minimumVersion,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VersionCheckDialog(
        currentVersion: currentVersion,
        minimumVersion: minimumVersion,
      ),
    );
  }
}
