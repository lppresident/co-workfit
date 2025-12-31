import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_bloc.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_event.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_state.dart';

/// 정산 내역 페이지 (최근 7일치만 표시)
class SettlementHistoryPage extends StatefulWidget {
  const SettlementHistoryPage({super.key});

  @override
  State<SettlementHistoryPage> createState() => _SettlementHistoryPageState();
}

class _SettlementHistoryPageState extends State<SettlementHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<WoodBloc>().add(const LoadSettlementHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정산 내역'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<WoodBloc, WoodState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settlements = state.settlements;

          if (settlements.isEmpty) {
            return _buildEmptyState();
          }

          return _buildSettlementList(settlements);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '정산 내역이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '챌린지를 완료하면 통나무를 받을 수 있어요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementList(List<WoodSettlementEntity> settlements) {
    // 총 획득량 계산
    final totalEarned = settlements.fold<int>(
      0,
      (sum, s) => sum + s.totalWoodAwarded,
    );

    return Column(
      children: [
        // 요약 헤더
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF8B4513).withValues(alpha: 0.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최근 7일 획득량',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('🪵', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        '$totalEarned개',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${settlements.length}건',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // 정산 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: settlements.length,
            itemBuilder: (context, index) {
              return _buildSettlementCard(settlements[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementCard(WoodSettlementEntity settlement) {
    final selectedChallenge = settlement.selectedChallenge;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSettlementDetail(settlement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 및 획득량
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    settlement.settlementDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Text('🪵', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        '+${settlement.totalWoodAwarded}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 선택된 챌린지 정보
              if (selectedChallenge != null) ...[
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
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // 포기된 챌린지 수
              if (settlement.forsakenChallenges.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '+ ${settlement.forsakenChallenges.length}개 챌린지 포기',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSettlementDetail(WoodSettlementEntity settlement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _SettlementDetailSheet(
            settlement: settlement,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class _SettlementDetailSheet extends StatelessWidget {
  final WoodSettlementEntity settlement;
  final ScrollController scrollController;

  const _SettlementDetailSheet({
    required this.settlement,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 헤더
          Text(
            '${settlement.settlementDate} 정산',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          // 선택된 챌린지 상세
          if (settlement.selectedChallenge != null) ...[
            _buildSectionTitle('선택된 보상'),
            _buildChallengeDetail(settlement.selectedChallenge!, true),
            const SizedBox(height: 24),
          ],

          // 포기된 챌린지
          if (settlement.forsakenChallenges.isNotEmpty) ...[
            _buildSectionTitle('포기된 챌린지'),
            ...settlement.forsakenChallenges
                .map((c) => _buildChallengeDetail(c, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildChallengeDetail(ChallengeRewardDetail challenge, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF8B4513).withValues(alpha: 0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: selected
            ? Border.all(color: const Color(0xFF8B4513), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 챌린지 이름
          Row(
            children: [
              Icon(
                challenge.isSuccess ? Icons.check_circle : Icons.cancel,
                size: 20,
                color: challenge.isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge.challengeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '선택됨',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 보상 상세
          _buildRewardRow('개인 운동', challenge.personalReward),
          _buildRewardRow('기여도', challenge.contributionReward),
          if (challenge.successBonus > 0)
            _buildRewardRow('성공 보너스', challenge.successBonus),

          const Divider(height: 16),

          // 총 보상
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '총 보상',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Text('🪵', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    selected ? '+${challenge.total}' : '(${challenge.total})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selected ? const Color(0xFF8B4513) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // MVP/마일스톤 배지
          if (challenge.isMvp || challenge.milestoneType != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (challenge.isMvp)
                  _buildBadge('MVP', Colors.amber),
                if (challenge.milestoneType != null)
                  _buildBadge(
                    _getMilestoneName(challenge.milestoneType!),
                    Colors.purple,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardRow(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text('+$amount', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
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
}
