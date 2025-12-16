import 'package:flutter/material.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';

/// 챌린지 카드 위젯
class ChallengeCardWidget extends StatelessWidget {
  final LogRunChallengeEntity challenge;
  final VoidCallback? onTap;

  const ChallengeCardWidget({
    super.key,
    required this.challenge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = challenge.progress;
    final remainingWeight = challenge.remainingWeight;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 방장 이름 & 상태
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        challenge.creatorName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 12),

              // 통나무 무게 정보
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.workspaces,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '남은 무게',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        '${remainingWeight.toStringAsFixed(1)} kg',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${challenge.currentDistance.toStringAsFixed(1)} / ${challenge.targetDistance.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 진행률 바
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(context, progress),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 진행률 퍼센트 & 참가자 수
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% 완료',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.group,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${challenge.participants.length}명 참여',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (challenge.status) {
      case ChallengeStatus.active:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = '진행 중';
        break;
      case ChallengeStatus.completed:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = '완료';
        break;
      case ChallengeStatus.expired:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = '만료';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Color _getProgressColor(BuildContext context, double progress) {
    if (progress >= 1.0) {
      return Colors.green;
    } else if (progress >= 0.7) {
      return Theme.of(context).colorScheme.primary;
    } else if (progress >= 0.3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
