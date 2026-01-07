import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_invite_entity.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_bloc.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';

/// 챌린지 초대 섹션 위젯
class ChallengeInvitesSection extends StatelessWidget {
  final List<ChallengeInviteEntity> invites;

  const ChallengeInvitesSection({
    super.key,
    required this.invites,
  });

  @override
  Widget build(BuildContext context) {
    if (invites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                '초대된 챌린지 (${invites.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...invites.map((invite) => _InviteCard(invite: invite)),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final ChallengeInviteEntity invite;

  const _InviteCard({required this.invite});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.challengeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${invite.inviterNickname}님의 초대',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.flag, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '목표: ${invite.targetWeight.toStringAsFixed(0)}kg',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${dateFormat.format(invite.startDate)} ~ ${dateFormat.format(invite.endDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptInvite(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('수락'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectInvite(context),
                    child: const Text('거절'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _acceptInvite(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    context.read<ChallengeBloc>().add(
          AcceptInviteEvent(
            inviteId: invite.id,
            userId: authState.user.id,
            userNickname: authState.user.nickname,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${invite.challengeName}에 참가했습니다!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectInvite(BuildContext context) {
    context.read<ChallengeBloc>().add(
          RejectInviteEvent(invite.id),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('초대를 거절했습니다'),
      ),
    );
  }
}
