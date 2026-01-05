import 'package:flutter/material.dart';
import 'package:co_workfit/features/currency/domain/entities/currency_type.dart';
import 'package:co_workfit/features/currency/domain/entities/settlement_entity.dart';

/// 정산 결과 다이얼로그
class SettlementDialog extends StatelessWidget {
  final List<SettlementEntity> settlements;
  final VoidCallback onDismiss;

  const SettlementDialog({
    super.key,
    required this.settlements,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // 총 보상 계산
    final totalRewards = <CurrencyType, int>{};
    for (final settlement in settlements) {
      for (final type in CurrencyType.values) {
        totalRewards[type] = (totalRewards[type] ?? 0) + settlement.getReward(type);
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            const Text(
              '🎉 보상 획득!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${settlements.length}일치 정산 완료',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // 총 보상
            ...CurrencyType.values.map((type) {
              final amount = totalRewards[type] ?? 0;
              if (amount <= 0) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildRewardRow(type, amount),
              );
            }),

            const Divider(),
            const SizedBox(height: 16),

            // 상세 내역 (접을 수 있는 형태)
            if (settlements.length == 1)
              _buildSettlementDetails(settlements.first)
            else
              ExpansionTile(
                title: const Text('상세 내역'),
                children: settlements.map((s) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildSettlementDetails(s),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardRow(CurrencyType type, int amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(type.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Text(
            '+$amount',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: type.color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            type.displayName,
            style: TextStyle(
              fontSize: 16,
              color: type.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementDetails(SettlementEntity settlement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          settlement.settlementDate,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        // 챌린지 보상
        ...settlement.challengeRewards.where((r) => r.selected).map((reward) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(reward.currencyType.emoji),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reward.challengeName,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  '+${reward.total}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: reward.currencyType.color,
                  ),
                ),
              ],
            ),
          );
        }),

        // 개인 운동 보상
        ...settlement.soloWorkoutRewards.map((reward) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(reward.currencyType.emoji),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reward.displayName,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  '+${reward.total}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: reward.currencyType.color,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// 정산 다이얼로그 표시 헬퍼
Future<void> showSettlementDialog(
  BuildContext context,
  List<SettlementEntity> settlements,
  VoidCallback onDismiss,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => SettlementDialog(
      settlements: settlements,
      onDismiss: () {
        Navigator.of(context).pop();
        onDismiss();
      },
    ),
  );
}

