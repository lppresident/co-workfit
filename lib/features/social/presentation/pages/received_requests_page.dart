import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/core/widgets/common_loading_widget.dart';
import 'package:co_workfit/core/widgets/common_empty_widget.dart';
import 'package:co_workfit/core/constants/app_constants.dart';

class ReceivedRequestsPage extends BasePage {
  const ReceivedRequestsPage({super.key});

  @override
  State<ReceivedRequestsPage> createState() => _ReceivedRequestsPageState();
}

class _ReceivedRequestsPageState extends BasePageState<ReceivedRequestsPage> {
  @override
  void loadInitialData() {
    // 데이터는 이미 로드되어 있음
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return const StandardAppBar(
      title: '받은 친구 요청',
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        if (state is SocialLoading) {
          return const CommonLoadingWidget(message: '받은 요청 불러오는 중...');
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
          return const CommonEmptyWidget(
            icon: Icons.inbox_outlined,
            message: '받은 친구 요청이 없습니다',
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: 8,
              ),
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
