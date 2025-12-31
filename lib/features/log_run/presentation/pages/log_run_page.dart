import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/empty_log_run_widget.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/challenge_card_widget.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/create_challenge_bottom_sheet.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/invite_code_bottom_sheet.dart';
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

  void _showActionSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('통나무런'),
        content: const Text('새 그룹을 만들거나\n초대 코드로 참가할 수 있습니다'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCreateChallengeSheet();
            },
            child: const Text('새 그룹 만들기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showJoinByCodeSheet();
            },
            child: const Text('초대 코드로 참가'),
          ),
        ],
      ),
    );
  }

  void _showCreateChallengeSheet() {
    // BottomSheet 내부에서 Bloc에 접근하기 위해 미리 참조를 가져옴
    final authBloc = context.read<AuthBloc>();
    final logRunBloc = context.read<LogRunBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => CreateChallengeBottomSheet(
        onCreate: (targetWeight, challengeDate, maxParticipants) {
          final authState = authBloc.state;
          if (authState is Authenticated) {
            logRunBloc.add(
              CreateChallenge(
                userId: authState.user.id,
                userNickname: authState.user.nickname,
                targetWeight: targetWeight,
                challengeDate: challengeDate,
                maxParticipants: maxParticipants,
              ),
            );
          }
        },
      ),
    );
  }

  void _showJoinByCodeSheet() {
    // BottomSheet 내부에서 Bloc에 접근하기 위해 미리 참조를 가져옴
    final authBloc = context.read<AuthBloc>();
    final logRunBloc = context.read<LogRunBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => InviteCodeBottomSheet(
        onJoin: (inviteCode) {
          final authState = authBloc.state;
          if (authState is Authenticated) {
            logRunBloc.add(
              JoinChallengeByCode(
                inviteCode: inviteCode,
                userId: authState.user.id,
                userNickname: authState.user.nickname,
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
          // 에러 후 목록 복구
          refreshChallenges();
        } else if (state is ChallengeCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('챌린지가 생성되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          // 목록 새로고침
          refreshChallenges();
        } else if (state is ChallengeJoined) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('챌린지에 참가했습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          // 목록 새로고침
          refreshChallenges();
        } else if (state is ChallengeDeleted) {
          // 챌린지 삭제 후 목록 새로고침
          refreshChallenges();
        }
      },
      builder: (context, state) {
        // 초기 상태 또는 로딩 상태 - 로딩 인디케이터 표시
        if (state is LogRunInitial || state is LogRunLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Empty 상태 (데이터 로드 완료 후 챌린지가 없는 경우)
        if (state is LogRunEmpty) {
          return EmptyLogRunWidget(
            onCreateOrJoin: _showActionSelectionDialog,
          );
        }

        // ChallengesLoaded 또는 ChallengeDetailLoaded 상태 처리
        if (state is ChallengesLoaded || state is ChallengeDetailLoaded) {
          final activeChallenges = state is ChallengesLoaded
              ? state.activeChallenges
              : (state as ChallengeDetailLoaded).activeChallenges;
          final completedChallenges = state is ChallengesLoaded
              ? state.completedChallenges
              : (state as ChallengeDetailLoaded).completedChallenges;
          final expiredChallenges = state is ChallengesLoaded
              ? state.expiredChallenges
              : (state as ChallengeDetailLoaded).expiredChallenges;

          // 진행 중 → 완료 → 실패 순으로 표시
          final allChallenges = [...activeChallenges, ...completedChallenges, ...expiredChallenges];

          if (allChallenges.isEmpty) {
            return EmptyLogRunWidget(
              onCreateOrJoin: _showActionSelectionDialog,
            );
          }

          return _buildUnifiedChallengeList(allChallenges);
        }

        // WorkoutSubmitted, ChallengeCreated 등 일시적인 상태는 로딩 표시
        if (state is WorkoutSubmitted || state is ChallengeCreated || state is ChallengeJoined) {
          return const Center(child: CircularProgressIndicator());
        }

        // 기본: 로딩 표시 (알 수 없는 상태)
        return const Center(child: CircularProgressIndicator());
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
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => ChallengeDetailPage(
                    challengeId: challenge.id,
                  ),
                ),
              );
              // 상세 페이지에서 변경이 있었으면 목록 새로고침
              if (result == true && mounted) {
                refreshChallenges();
              }
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
            onPressed: _showActionSelectionDialog,
            tooltip: '챌린지 생성 또는 참가',
            child: const Icon(Icons.add),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
