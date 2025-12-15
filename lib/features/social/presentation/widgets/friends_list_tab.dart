import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';

class FriendsListTab extends StatelessWidget {
  const FriendsListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        if (state is SocialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SocialError && state.previousState == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('오류: ${state.message}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is Authenticated) {
                      context.read<SocialBloc>().add(LoadFriends(authState.user.id));
                    }
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  '아직 친구가 없습니다',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  '친구 추가 탭에서 친구를 추가해보세요!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
