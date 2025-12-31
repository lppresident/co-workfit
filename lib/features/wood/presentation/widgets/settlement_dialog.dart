import 'package:flutter/material.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';
import 'package:co_workfit/features/wood/domain/usecases/check_pending_settlements.dart';

/// 정산 결과 다이얼로그
class SettlementDialog extends StatelessWidget {
  final SettlementSummary summary;
  final VoidCallback onDismiss;

  const SettlementDialog({
    super.key,
    required this.summary,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            _buildHeader(context),
            const SizedBox(height: 24),

            // 총 획득 통나무
            _buildTotalReward(),
            const SizedBox(height: 24),

            // 정산 상세 목록
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...summary.settlements.map((s) => _buildSettlementCard(s)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '받기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const Text(
          '🎉',
          style: TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 8),
        Text(
          '${summary.settledDays}일치 챌린지 정산!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildTotalReward() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B4513).withValues(alpha: 0.2),
            const Color(0xFFD2691E).withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🪵',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(width: 12),
          Text(
            '+${summary.totalWoodAwarded}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '개',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(WoodSettlementEntity settlement) {
    final selectedChallenge = settlement.selectedChallenge;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                settlement.settlementDate,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Text('🪵', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '+${settlement.totalWoodAwarded}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (selectedChallenge != null) ...[
            const Divider(height: 16),

            // 챌린지 정보
            Row(
              children: [
                Icon(
                  selectedChallenge.isSuccess
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 16,
                  color: selectedChallenge.isSuccess
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    selectedChallenge.challengeName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 보상 상세
            _buildRewardRow('개인 운동', selectedChallenge.personalReward),
            _buildRewardRow('기여도', selectedChallenge.contributionReward),
            if (selectedChallenge.successBonus > 0)
              _buildRewardRow('성공 보너스', selectedChallenge.successBonus, highlight: true),

            // 배지
            if (selectedChallenge.isMvp || selectedChallenge.milestoneType != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (selectedChallenge.isMvp)
                    _buildBadge('MVP', Colors.amber),
                  if (selectedChallenge.milestoneType != null)
                    _buildBadge(
                      _getMilestoneName(selectedChallenge.milestoneType!),
                      Colors.purple,
                    ),
                ],
              ),
            ],
          ],

          // 포기된 챌린지 수
          if (settlement.forsakenChallenges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '+ ${settlement.forsakenChallenges.length}개 챌린지 포기',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _getMilestoneName(String type) {
    switch (type) {
      case 'full':
        return '풀마라톤';
      case 'half':
        return '하프마라톤';
      case 'km10':
        return '10km';
      default:
        return type;
    }
  }

  Widget _buildRewardRow(String label, int amount, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? const Color(0xFF8B4513) : Colors.grey[700],
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '+$amount개',
            style: TextStyle(
              fontSize: 12,
              color: highlight ? const Color(0xFF8B4513) : Colors.grey[700],
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
