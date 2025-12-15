import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_state.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_event.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/social/presentation/widgets/leaderboard/leaderboard_entry_widget.dart';

class GlobalLeaderboardTab extends StatelessWidget {
  const GlobalLeaderboardTab({super.key});

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
                    context.read<LeaderboardBloc>().add(
                      LoadGlobalLeaderboard(
                        type: state.previousState?.currentType ?? LeaderboardType.allTime,
                      ),
                    );
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        final leaderboard = state is LeaderboardLoaded
            ? state.globalLeaderboard
            : state is LeaderboardError && state.previousState != null
                ? state.previousState!.globalLeaderboard
                : <LeaderboardEntryEntity>[];

        final currentType = state is LeaderboardLoaded
            ? state.currentType
            : LeaderboardType.allTime;

        if (leaderboard.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '리더보드 데이터가 없습니다',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final authState = context.read<AuthBloc>().state;
        final currentUserId = authState is Authenticated ? authState.user.id : null;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<LeaderboardBloc>().add(
              RefreshGlobalLeaderboard(type: currentType),
            );
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
