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
    final hasWood = summary.hasWoodRewards;
    final hasIron = summary.hasIronRewards;
    
    return Column(
      children: [
        // 통나무 보상
        if (hasWood)
          Container(
            padding: const EdgeInsets.all(16),
            margin: EdgeInsets.only(bottom: hasIron ? 8 : 0),
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
                  style: TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 12),
                Text(
                  '+${summary.totalWoodAwarded}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '개',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
          ),
        
        // 쇠 보상
        if (hasIron)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF607D8B).withValues(alpha: 0.2),
                  const Color(0xFF455A64).withValues(alpha: 0.2),
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
                  '🔩',
                  style: TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 12),
                Text(
                  '+${summary.totalIronAwarded}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF455A64),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '개',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF455A64),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSettlementCard(WoodSettlementEntity settlement) {
    final selectedWoodChallenge = settlement.selectedChallenge;
    final selectedIronChallenge = settlement.selectedIronChallenge;

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
                  if (settlement.totalWoodAwarded > 0) ...[
                    const Text('🪵', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 2),
                    Text(
                      '+${settlement.totalWoodAwarded}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                  ],
                  if (settlement.totalWoodAwarded > 0 && settlement.totalIronAwarded > 0)
                    const SizedBox(width: 8),
                  if (settlement.totalIronAwarded > 0) ...[
                    const Text('🔩', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 2),
                    Text(
                      '+${settlement.totalIronAwarded}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF455A64),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // 통나무 챌린지 정보
          if (selectedWoodChallenge != null) ...[
            const Divider(height: 16),
            _buildChallengeInfo(selectedWoodChallenge, isIron: false),
          ],
          
          // 쇠 챌린지 정보
          if (selectedIronChallenge != null) ...[
            const Divider(height: 16),
            _buildChallengeInfo(selectedIronChallenge, isIron: true),
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
  
  Widget _buildChallengeInfo(ChallengeRewardDetail challenge, {required bool isIron}) {
    final accentColor = isIron ? const Color(0xFF455A64) : const Color(0xFF8B4513);
    final icon = isIron ? '🔩' : '🪵';
    final typeLabel = isIron ? '헬스' : '달리기';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 챌린지 정보
        Row(
          children: [
            Icon(
              challenge.isSuccess ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: challenge.isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                challenge.challengeName,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 보상 상세
        _buildRewardRow('개인 운동', challenge.personalReward, accentColor: accentColor),
        _buildRewardRow('기여도', challenge.contributionReward, accentColor: accentColor),
        if (challenge.successBonus > 0)
          _buildRewardRow('성공 보너스', challenge.successBonus, highlight: true, accentColor: accentColor),

        // 배지
        if (challenge.isMvp || challenge.milestoneType != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (challenge.isMvp) _buildBadge('MVP', Colors.amber),
              if (challenge.milestoneType != null)
                _buildBadge(_getMilestoneName(challenge.milestoneType!), Colors.purple),
            ],
          ),
        ],
      ],
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

  Widget _buildRewardRow(String label, int amount, {bool highlight = false, Color? accentColor}) {
    final color = accentColor ?? const Color(0xFF8B4513);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? color : Colors.grey[700],
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '+$amount개',
            style: TextStyle(
              fontSize: 12,
              color: highlight ? color : Colors.grey[700],
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
