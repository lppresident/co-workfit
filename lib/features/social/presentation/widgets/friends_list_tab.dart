import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/social/presentation/pages/friend_detail_page.dart';
import 'package:co_workfit/features/social/presentation/pages/received_requests_page.dart';
import 'package:co_workfit/core/widgets/common_loading_widget.dart';
import 'package:co_workfit/core/widgets/common_error_widget.dart';
import 'package:co_workfit/core/widgets/common_empty_widget.dart';
import 'package:co_workfit/core/constants/app_constants.dart';

class FriendsListTab extends StatelessWidget {
  const FriendsListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        if (state is SocialLoading) {
          return const CommonLoadingWidget(message: '친구 목록 불러오는 중...');
        }

        if (state is SocialError && state.previousState == null) {
          return CommonErrorWidget(
            message: state.message,
            onRetry: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                context
                    .read<SocialBloc>()
                    .add(LoadFriendsData(authState.user.id));
              }
            },
          );
        }

        final friends = state is SocialLoaded
            ? state.friends
            : state is SocialActionSuccess
                ? state.newState.friends
                : state is SocialActionInProgress
                    ? state.currentState.friends
                    : state is SocialError && state.previousState != null
                        ? state.previousState!.friends
                        : <dynamic>[];

        final requestCount = state is SocialLoaded
            ? state.requestCount
            : state is SocialActionSuccess
                ? state.newState.requestCount
                : state is SocialActionInProgress
                    ? state.currentState.requestCount
                    : state is SocialError && state.previousState != null
                        ? state.previousState!.requestCount
                        : 0;

        if (friends.isEmpty && requestCount == 0) {
          return const CommonEmptyWidget(
            icon: Icons.people_outline,
            message: '아직 친구가 없습니다\n우하단 버튼으로 친구를 추가해보세요!',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final authState = context.read<AuthBloc>().state;
            if (authState is Authenticated) {
              context
                  .read<SocialBloc>()
                  .add(LoadFriendsData(authState.user.id));
            }
          },
          child: ListView.builder(
            itemCount: friends.length + (requestCount > 0 ? 1 : 0),
            itemBuilder: (context, index) {
              // 받은 요청 알림 셀
              if (requestCount > 0 && index == 0) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: 8,
                  ),
                  color: Colors.blue.shade50,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      '새로운 친구 요청 $requestCount개',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('탭하여 확인하기'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReceivedRequestsPage(),
                        ),
                      );
                    },
                  ),
                );
              }

              // 친구 목록 셀
              final friendIndex = requestCount > 0 ? index - 1 : index;
              final friend = friends[friendIndex];
              // nickname 우선, 없으면 displayName 사용
              final displayName = friend.friendNickname ?? friend.friendName ?? '알 수 없음';
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: friend.friendPhotoUrl != null
                        ? NetworkImage(friend.friendPhotoUrl!)
                        : null,
                    child: friend.friendPhotoUrl == null
                        ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?')
                        : null,
                  ),
                  title: Text(displayName),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FriendDetailPage(
                          friend: friend,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
