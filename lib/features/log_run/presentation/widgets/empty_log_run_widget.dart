import 'package:flutter/material.dart';
import 'package:co_workfit/core/constants/app_constants.dart';

/// 통나무런 그룹이 없을 때 표시하는 빈 상태 위젯
class EmptyLogRunWidget extends StatelessWidget {
  final VoidCallback onCreateOrJoin;

  const EmptyLogRunWidget({
    super.key,
    required this.onCreateOrJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.defaultPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 큰 아이콘
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspaces_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),

            // 제목
            Text(
              '아직 참여 중인 그룹이 없습니다',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // 설명
            Text(
              '친구들과 함께 목표 거리를 달성하고\n기여도에 따라 보상을 받아보세요!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // 액션 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCreateOrJoin,
                icon: const Icon(Icons.add_circle, size: 28),
                label: const Text(
                  '그룹 생성 또는 참가하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(AppConstants.defaultPadding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 안내 카드
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
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
                          '통나무런이란?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      context,
                      Icons.groups,
                      '팀으로 목표 달성',
                      '여러 명이 하나의 목표 거리를 나눠서 완주',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      context,
                      Icons.emoji_events,
                      '기여도 기반 보상',
                      '각 참가자의 기여도에 따라 보상 차등 지급',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      context,
                      Icons.lock_outline,
                      '프라이버시 보호',
                      '세션 정보만 공유, 전체 운동량 노출 방지',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
