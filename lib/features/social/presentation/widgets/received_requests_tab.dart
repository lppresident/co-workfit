import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';

class ReceivedRequestsTab extends StatelessWidget {
  const ReceivedRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        if (state is SocialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = state is SocialLoaded
            ? state.receivedRequests
            : state is SocialActionSuccess
                ? state.newState.receivedRequests
                : state is SocialActionInProgress
                    ? state.currentState.receivedRequests
                    : state is SocialError && state.previousState != null
                        ? state.previousState!.receivedRequests
                        : <dynamic>[];

        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '받은 친구 요청이 없습니다',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: request.senderPhotoUrl != null
                      ? NetworkImage(request.senderPhotoUrl!)
                      : null,
                  child: request.senderPhotoUrl == null
                      ? Text(request.senderName[0].toUpperCase())
                      : null,
                ),
                title: Text(request.senderName),
                subtitle: Text(
                  '${_formatDate(request.createdAt)}에 요청',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        context.read<SocialBloc>().add(
                          AcceptFriendRequestEvent(request.id),
                        );
                      },
                      tooltip: '수락',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        context.read<SocialBloc>().add(
                          RejectFriendRequestEvent(request.id),
                        );
                      },
                      tooltip: '거절',
                    ),
                  ],
                ),
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
}
