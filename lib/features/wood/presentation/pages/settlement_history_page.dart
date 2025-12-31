import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/wood/domain/entities/wood_settlement_entity.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_bloc.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_event.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_state.dart';

/// 정산 내역 페이지
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
          if (state.isLoading && state.settlements.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.settlements.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<WoodBloc>().add(const LoadSettlementHistory());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.settlements.length,
              itemBuilder: (context, index) {
                return _buildSettlementCard(state.settlements[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🪵',
            style: TextStyle(fontSize: 64),
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
            '챌린지를 완료하면 통나무를 획득할 수 있어요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(WoodSettlementEntity settlement) {
    final selected = settlement.selectedChallenge;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSettlementDetail(settlement),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B4513),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      settlement.settlementDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Text('🪵', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        '+${settlement.totalWoodAwarded}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 선택된 챌린지
              if (selected != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selected.challengeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (selected.isSuccess)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected.isMvp) ...[
                              const Text('👑', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                            ],
                            const Text(
                              '성공',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ] else ...[
                Text(
                  '정산할 챌린지 없음',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],

              // 포기된 챌린지 수
              if (settlement.forsakenChallenges.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '+ ${settlement.forsakenChallenges.length}개 챌린지 포기',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],

              // 만료된 챌린지 경고
              if (settlement.expiredChallenges.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange[700], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${settlement.expiredChallenges.length}개 기한 만료',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
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
            const SizedBox(height: 24),
          ],

          // 만료된 챌린지
          if (settlement.expiredChallenges.isNotEmpty) ...[
            _buildSectionTitle('기한 만료'),
            ...settlement.expiredChallenges.map(_buildExpiredChallenge),
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

  Widget _buildChallengeDetail(ChallengeRewardDetail detail, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.challengeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (detail.isMvp)
                const Text('👑 MVP', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          _buildRewardRow('개인 운동', detail.personalReward),
          _buildRewardRow('챌린지 기여', detail.contributionReward),
          if (detail.successBonus > 0)
            _buildRewardRow('성공 보너스', detail.successBonus),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('총계', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Text('🪵'),
                  const SizedBox(width: 4),
                  Text(
                    '${detail.total}개',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  Widget _buildExpiredChallenge(ExpiredChallengeInfo info) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.challengeName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '종료: ${_formatDate(info.endDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '~${info.estimatedReward}개',
            style: TextStyle(
              color: Colors.orange[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }
}

