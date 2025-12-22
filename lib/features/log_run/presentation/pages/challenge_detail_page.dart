import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_bloc.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_event.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_state.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/contribution_feed_widget.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/submit_workout_bottom_sheet.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/share_challenge_bottom_sheet.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_contribution_entity.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';

class ChallengeDetailPage extends BasePage {
  final String challengeId;
  const ChallengeDetailPage({super.key, required this.challengeId});

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends BasePageState<ChallengeDetailPage> {
  @override
  void loadInitialData() {
    context.read<LogRunBloc>().add(LoadChallengeDetail(widget.challengeId));
    context.read<LogRunBloc>().add(WatchChallenge(widget.challengeId));
    context.read<LogRunBloc>().add(WatchContributions(widget.challengeId));
  }

  void _showSubmitWorkoutSheet() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubmitWorkoutBottomSheet(
        challengeId: widget.challengeId,
        onSubmit: (workoutId, distance, workoutType, workoutDate) {
          context.read<LogRunBloc>().add(
                SubmitWorkout(
                  challengeId: widget.challengeId,
                  userId: authState.user.id,
                  userNickname: authState.user.nickname,
                  workoutId: workoutId,
                  distance: distance,
                  workoutType: workoutType,
                  workoutDate: workoutDate,
                ),
              );
        },
      ),
    );
  }

  void _showShareSheet(String inviteCode, String challengeName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShareChallengeBottomSheet(
        inviteCode: inviteCode,
        challengeName: challengeName,
      ),
    );
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: '챌린지 상세',
      actions: [
        BlocBuilder<LogRunBloc, LogRunState>(
          builder: (context, state) {
            // 챌린지 정보가 있을 때만 공유 버튼 표시
            if (state is ChallengeDetailLoaded || state is ChallengeUpdated) {
              final challenge = state is ChallengeDetailLoaded
                  ? state.challenge
                  : (state as ChallengeUpdated).challenge;

              return IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _showShareSheet(
                  challenge.inviteCode,
                  '${challenge.targetWeight.toStringAsFixed(0)}kg 통나무런',
                ),
                tooltip: '초대 코드 공유',
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocConsumer<LogRunBloc, LogRunState>(
      listener: (context, state) {
        if (state is WorkoutSubmitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('운동 기록이 제출되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is LogRunError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is LogRunLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ChallengeDetailLoaded || state is ChallengeUpdated || state is ContributionsUpdated) {
          final challenge = state is ChallengeDetailLoaded ? state.challenge :
                            state is ChallengeUpdated ? state.challenge : null;
          final contributions = state is ChallengeDetailLoaded ? state.contributions :
                               state is ContributionsUpdated ? state.contributions : <LogRunContributionEntity>[];

          if (challenge == null) return const Center(child: Text('챌린지 정보를 불러올 수 없습니다'));

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Column(
                  children: [
                    Text('남은 무게', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('${challenge.remainingWeight.toStringAsFixed(1)} kg',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: challenge.progress, minHeight: 12),
                    const SizedBox(height: 8),
                    Text('${(challenge.progress * 100).toStringAsFixed(0)}% 완료'),
                  ],
                ),
              ),
              Expanded(child: ContributionFeedWidget(contributions: contributions)),
            ],
          );
        }

        return const Center(child: Text('챌린지를 불러오는 중...'));
      },
    );
  }

  @override
  Widget? buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _showSubmitWorkoutSheet,
      icon: const Icon(Icons.add),
      label: const Text('운동 기록 제출'),
    );
  }
}
