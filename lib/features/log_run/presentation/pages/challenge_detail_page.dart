import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_bloc.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_event.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_state.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/contribution_feed_widget.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_contribution_entity.dart';

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

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return const StandardAppBar(title: '챌린지 상세');
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<LogRunBloc, LogRunState>(
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
}
