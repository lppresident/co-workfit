import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/empty_log_run_widget.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/challenge_card_widget.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/create_challenge_bottom_sheet.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_bloc.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_event.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_state.dart';
import 'package:co_workfit/features/log_run/presentation/pages/challenge_detail_page.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 통나무런 메인 페이지
class LogRunPage extends BasePage {
  const LogRunPage({super.key});

  @override
  State<LogRunPage> createState() => _LogRunPageState();

  // DashboardPage에서 새로고침을 트리거할 수 있도록 GlobalKey 제공
  static final GlobalKey<_LogRunPageState> globalKey = GlobalKey<_LogRunPageState>();
}

class _LogRunPageState extends BasePageState<LogRunPage> {
  @override
  void loadInitialData() {
    refreshChallenges();
  }

  /// 챌린지 목록 새로고침 (탭 재클릭, 당겨서 새로고침에서 사용)
  void refreshChallenges() {
    AppLogger.info('LogRunPage', 'Loading log run challenges');
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<LogRunBloc>().add(LoadActiveChallenges(authState.user.id));
      context.read<LogRunBloc>().add(LoadCompletedChallenges(authState.user.id));
    }
  }

  void _showCreateChallengeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CreateChallengeBottomSheet(
        onCreate: (targetWeight) {
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            context.read<LogRunBloc>().add(
                  CreateChallenge(
                    userId: authState.user.id,
                    userName: authState.user.displayName,
                    targetWeight: targetWeight,
                  ),
                );
          }
        },
      ),
    );
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return const StandardAppBar(
      title: '통나무런',
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocConsumer<LogRunBloc, LogRunState>(
      listener: (context, state) {
        if (state is LogRunError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is ChallengeCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('챌린지가 생성되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          // 목록 새로고침
          refreshChallenges();
        }
      },
      builder: (context, state) {
        if (state is LogRunLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is LogRunEmpty) {
          return EmptyLogRunWidget(
            onCreateOrJoin: _showCreateChallengeSheet,
          );
        }

        // ChallengesLoaded 또는 ChallengeDetailLoaded 상태 모두 처리
        if (state is ChallengesLoaded || state is ChallengeDetailLoaded) {
          final activeChallenges = state is ChallengesLoaded
              ? state.activeChallenges
              : (state as ChallengeDetailLoaded).activeChallenges;
          final completedChallenges = state is ChallengesLoaded
              ? state.completedChallenges
              : (state as ChallengeDetailLoaded).completedChallenges;

          // 진행 중 챌린지를 먼저, 완료된 챌린지를 뒤에 표시
          final allChallenges = [...activeChallenges, ...completedChallenges];

          if (allChallenges.isEmpty) {
            return EmptyLogRunWidget(
              onCreateOrJoin: _showCreateChallengeSheet,
            );
          }

          return _buildUnifiedChallengeList(allChallenges);
        }

        // 기본 Empty 상태
        return EmptyLogRunWidget(
          onCreateOrJoin: _showCreateChallengeSheet,
        );
      },
    );
  }

  Widget _buildUnifiedChallengeList(List<dynamic> challenges) {
    return RefreshIndicator(
      onRefresh: () async {
        refreshChallenges();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return ChallengeCardWidget(
            challenge: challenge,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChallengeDetailPage(
                    challengeId: challenge.id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget? buildFloatingActionButton(BuildContext context) {
    return BlocBuilder<LogRunBloc, LogRunState>(
      builder: (context, state) {
        // 챌린지가 있을 때만 FloatingActionButton 표시
        final hasActiveChallenges = (state is ChallengesLoaded && state.activeChallenges.isNotEmpty) ||
            (state is ChallengeDetailLoaded && state.activeChallenges.isNotEmpty);

        if (hasActiveChallenges) {
          return FloatingActionButton(
            onPressed: _showCreateChallengeSheet,
            tooltip: '새 챌린지 생성',
            child: const Icon(Icons.add),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
