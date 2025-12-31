import 'package:flutter/material.dart';
import 'package:co_workfit/core/constants/app_constants.dart';

/// 챌린지가 없을 때 표시하는 빈 상태 위젯
class EmptyLogRunWidget extends StatelessWidget {
  final VoidCallback onCreateOrJoin;
  final String? message;

  const EmptyLogRunWidget({
    super.key,
    required this.onCreateOrJoin,
    this.message,
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
              message ?? '아직 참여 중인 그룹이 없습니다',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // 설명
            Text(
              '친구들과 함께 목표를 달성하고\n달리기는 🪵통나무, 헬스는 🔩쇠를 획득하세요!',
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
                          '챌린지란?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      context,
                      Icons.directions_run,
                      '달리기 챌린지',
                      '함께 목표 거리를 달성하고 🪵통나무 획득',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      context,
                      Icons.fitness_center,
                      '헬스 챌린지',
                      '함께 목표 점수를 달성하고 🔩쇠 획득',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      context,
                      Icons.emoji_events,
                      '기여도 보상',
                      '기여도에 따라 보상 차등 지급 + MVP 보너스',
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
