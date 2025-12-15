import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
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
                context.read<SocialBloc>().add(LoadFriends(authState.user.id));
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

        if (friends.isEmpty) {
          return const CommonEmptyWidget(
            icon: Icons.people_outline,
            message: '아직 친구가 없습니다\n친구 추가 탭에서 친구를 추가해보세요!',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final authState = context.read<AuthBloc>().state;
            if (authState is Authenticated) {
              context.read<SocialBloc>().add(RefreshFriends(authState.user.id));
            }
          },
          child: ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
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
                        ? Text(friend.friendName[0].toUpperCase())
                        : null,
                  ),
                  title: Text(friend.friendName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(friend.friendEmail),
                      const SizedBox(height: 4),
                      Text(
                        '점수: ${friend.friendTotalScore} | 운동: ${friend.friendWorkoutCount}회',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
