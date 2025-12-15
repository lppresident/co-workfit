import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/core/widgets/common_loading_widget.dart';
import 'package:co_workfit/core/widgets/common_empty_widget.dart';
import 'package:co_workfit/core/constants/app_constants.dart';

class SentRequestsTab extends StatelessWidget {
  const SentRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        if (state is SocialLoading) {
          return const CommonLoadingWidget(message: '보낸 요청 불러오는 중...');
        }

        final requests = state is SocialLoaded
            ? state.sentRequests
            : state is SocialActionSuccess
                ? state.newState.sentRequests
                : state is SocialActionInProgress
                    ? state.currentState.sentRequests
                    : state is SocialError && state.previousState != null
                        ? state.previousState!.sentRequests
                        : <dynamic>[];

        if (requests.isEmpty) {
          return const CommonEmptyWidget(
            icon: Icons.send_outlined,
            message: '보낸 친구 요청이 없습니다',
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person_outline),
                ),
                title: Text('사용자 ${request.receiverId.substring(0, 8)}...'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatDate(request.createdAt)}에 전송',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(
                        _getStatusText(request.status.name),
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: _getStatusColor(request.status.name),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: request.status.name == 'pending'
                    ? IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        onPressed: () {
                          context.read<SocialBloc>().add(
                            CancelFriendRequestEvent(request.id),
                          );
                        },
                        tooltip: '취소',
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.year}.${date.month}.${date.day}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '대기 중';
      case 'accepted':
        return '수락됨';
      case 'rejected':
        return '거절됨';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade100;
      case 'accepted':
        return Colors.green.shade100;
      case 'rejected':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
