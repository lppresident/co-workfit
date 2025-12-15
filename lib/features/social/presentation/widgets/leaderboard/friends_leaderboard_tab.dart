import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_state.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_event.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/social/presentation/widgets/leaderboard/leaderboard_entry_widget.dart';

class FriendsLeaderboardTab extends StatelessWidget {
  const FriendsLeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaderboardBloc, LeaderboardState>(
      builder: (context, state) {
        if (state is LeaderboardLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is LeaderboardError && state.previousState == null) {
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
                      context.read<LeaderboardBloc>().add(
                        LoadFriendsLeaderboard(
                          userId: authState.user.id,
                          type: state.previousState?.currentType ?? LeaderboardType.allTime,
                        ),
                      );
                    }
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        final leaderboard = state is LeaderboardLoaded
            ? state.friendsLeaderboard
            : state is LeaderboardError && state.previousState != null
                ? state.previousState!.friendsLeaderboard
                : <LeaderboardEntryEntity>[];

        final currentType = state is LeaderboardLoaded
            ? state.currentType
            : LeaderboardType.allTime;

        if (leaderboard.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '친구가 없거나 데이터가 없습니다',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  '친구 탭에서 친구를 추가해보세요!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final authState = context.read<AuthBloc>().state;
        final currentUserId = authState is Authenticated ? authState.user.id : null;

        return RefreshIndicator(
          onRefresh: () async {
            final authState = context.read<AuthBloc>().state;
            if (authState is Authenticated) {
              context.read<LeaderboardBloc>().add(
                RefreshFriendsLeaderboard(
                  userId: authState.user.id,
                  type: currentType,
                ),
              );
            }
          },
          child: ListView.builder(
            itemCount: leaderboard.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              final isCurrentUser = currentUserId != null && entry.userId == currentUserId;

              return LeaderboardEntryWidget(
                entry: entry,
                isCurrentUser: isCurrentUser,
              );
            },
          ),
        );
      },
    );
  }
}
