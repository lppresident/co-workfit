import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_state.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_event.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/social/presentation/widgets/leaderboard/leaderboard_entry_widget.dart';
import 'package:co_workfit/core/widgets/common_loading_widget.dart';
import 'package:co_workfit/core/widgets/common_error_widget.dart';
import 'package:co_workfit/core/widgets/common_empty_widget.dart';

class FriendsLeaderboardTab extends StatelessWidget {
  const FriendsLeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaderboardBloc, LeaderboardState>(
      builder: (context, state) {
        if (state is LeaderboardLoading) {
          return const CommonLoadingWidget(message: '친구 리더보드 불러오는 중...');
        }

        if (state is LeaderboardError && state.previousState == null) {
          return CommonErrorWidget(
            message: state.message,
            onRetry: () {
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
          return const CommonEmptyWidget(
            icon: Icons.people_outline,
            message: '친구가 없거나 데이터가 없습니다\n친구 탭에서 친구를 추가해보세요!',
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
