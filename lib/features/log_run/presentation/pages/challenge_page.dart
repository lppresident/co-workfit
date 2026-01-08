import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/empty_challenge_widget.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/challenge_card_widget.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/create_challenge_bottom_sheet.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/invite_code_bottom_sheet.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/challenge_invites_section.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_bloc.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_event.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_state.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_invite_entity.dart';
import 'package:co_workfit/features/log_run/presentation/pages/challenge_detail_page.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';

/// 챌린지 메인 페이지
class ChallengePage extends BasePage {
  const ChallengePage({super.key});

  @override
  State<ChallengePage> createState() => _ChallengePageState();

  // DashboardPage에서 새로고침을 트리거할 수 있도록 GlobalKey 제공
  static final GlobalKey<_ChallengePageState> globalKey = GlobalKey<_ChallengePageState>();
}

class _ChallengePageState extends BasePageState<ChallengePage> {
  @override
  void loadInitialData() {
    refreshChallenges();
    loadInvites();
  }

  /// 챌린지 목록 새로고침
  void refreshChallenges() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ChallengeBloc>().add(LoadChallenges(authState.user.id));
    }
  }

  /// 초대 목록 로드
  void loadInvites() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ChallengeBloc>().add(WatchMyInvites(authState.user.id));
    }
  }

  void _showActionSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('챌린지'),
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
    final authBloc = context.read<AuthBloc>();
    final logRunBloc = context.read<ChallengeBloc>();

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
              CreateChallengeEvent(
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
    final authBloc = context.read<AuthBloc>();
    final logRunBloc = context.read<ChallengeBloc>();

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
      title: '챌린지',
    );
  }

  /// 현재 상태에서 챌린지 목록 추출
  List<ChallengeEntity> _getChallenges(ChallengeState state) {
    if (state is ChallengesLoaded) return state.challenges;
    if (state is ChallengeDetailLoaded) return state.challenges;
    if (state is WorkoutSubmitted) return state.challenges;
    if (state is MyInvitesUpdated) return state.challenges;
    return [];
  }

  /// 현재 상태에서 초대 목록 추출
  List<ChallengeInviteEntity> _getInvites(ChallengeState state) {
    if (state is ChallengesLoaded) return state.invites;
    if (state is MyInvitesLoaded) return state.invites;
    if (state is MyInvitesUpdated) return state.invites;
    return [];
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocConsumer<ChallengeBloc, ChallengeState>(
      listener: (context, state) {
        if (state is ChallengeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
          refreshChallenges();
        } else if (state is ChallengeCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('챌린지가 생성되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          refreshChallenges();
        } else if (state is ChallengeJoined) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('챌린지에 참가했습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          refreshChallenges();
        } else if (state is ChallengeDeleted) {
          refreshChallenges();
        } else if (state is InviteAccepted) {
          refreshChallenges();
        } else if (state is InviteRejected) {
          // 초대 목록은 자동으로 업데이트됨 (WatchMyInvites 스트림)
        }
      },
      builder: (context, state) {
        // 초기 상태 또는 로딩 상태
        if (state is ChallengeInitial || state is ChallengeLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Empty 상태
        if (state is ChallengeEmpty) {
          // Empty 상태에서도 초대가 있을 수 있음
          final invites = _getInvites(state);
          if (invites.isNotEmpty) {
            return _buildChallengeListWithInvites([], invites);
          }
          return EmptyChallengeWidget(
            onCreateOrJoin: _showActionSelectionDialog,
          );
        }

        // 챌린지 목록이 있는 상태들
        if (state is ChallengesLoaded || state is ChallengeDetailLoaded || state is WorkoutSubmitted || state is MyInvitesLoaded || state is MyInvitesUpdated) {
          final challenges = _getChallenges(state);
          final invites = _getInvites(state);

          if (challenges.isEmpty && invites.isEmpty) {
            return EmptyChallengeWidget(
              onCreateOrJoin: _showActionSelectionDialog,
            );
          }

          return _buildChallengeListWithInvites(challenges, invites);
        }

        // 일시적인 상태
        if (state is ChallengeCreated || state is ChallengeJoined) {
          return const Center(child: CircularProgressIndicator());
        }

        // 기본
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildChallengeListWithInvites(
    List<ChallengeEntity> challenges,
    List<ChallengeInviteEntity> invites,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        refreshChallenges();
        loadInvites();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: (invites.isNotEmpty ? 1 : 0) + challenges.length,
        itemBuilder: (context, index) {
          // 첫 번째 아이템: 초대 섹션
          if (invites.isNotEmpty && index == 0) {
            return ChallengeInvitesSection(invites: invites);
          }

          // 나머지 아이템: 챌린지 카드
          final challengeIndex = invites.isNotEmpty ? index - 1 : index;

          // 챌린지가 없으면 빈 위젯 반환
          if (challengeIndex >= challenges.length) {
            return const SizedBox.shrink();
          }

          final challenge = challenges[challengeIndex];
          return ChallengeCardWidget(
            challenge: challenge,
            onTap: () async {
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => ChallengeDetailPage(
                    challengeId: challenge.id,
                  ),
                ),
              );
              // 상세 페이지에서 돌아오면 목록 새로고침
              if (mounted) {
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
    return BlocBuilder<ChallengeBloc, ChallengeState>(
      builder: (context, state) {
        // 챌린지 목록이 있을 때 FloatingActionButton 표시
        // (Empty 상태에서는 EmptyChallengeWidget에 버튼이 있음)
        final challenges = _getChallenges(state);

        if (challenges.isNotEmpty) {
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
