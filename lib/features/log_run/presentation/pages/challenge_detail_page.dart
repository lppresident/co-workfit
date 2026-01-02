import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_bloc.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_event.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/log_run_state.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/contribution_feed_widget.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/submit_workout_bottom_sheet.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/share_challenge_bottom_sheet.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/podium_widget.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_contribution_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/workout_type.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/craft/domain/entities/equipped_items_entity.dart';
import 'package:co_workfit/features/craft/domain/usecases/get_equipped_items.dart';

class ChallengeDetailPage extends BasePage {
  final String challengeId;
  const ChallengeDetailPage({super.key, required this.challengeId});

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends BasePageState<ChallengeDetailPage> {
  // 상세 페이지에서 변경 사항이 있었는지 추적
  bool _hasChanges = false;
  
  // 참가자별 장착 아이템 캐시
  final Map<String, EquippedItemsEntity> _equippedItemsCache = {};

  @override
  void loadInitialData() {
    context.read<LogRunBloc>().add(LoadChallengeDetail(widget.challengeId));
    context.read<LogRunBloc>().add(WatchChallenge(widget.challengeId));
    context.read<LogRunBloc>().add(WatchContributions(widget.challengeId));
  }

  /// 참가자들의 장착 아이템 로드
  Future<void> _loadParticipantsEquippedItems(List<String> participantIds) async {
    final getEquippedItems = GetIt.instance<GetEquippedItems>();
    
    for (final odium in participantIds) {
      if (!_equippedItemsCache.containsKey(odium)) {
        try {
          final equipped = await getEquippedItems(odium);
          if (mounted) {
            setState(() {
              _equippedItemsCache[odium] = equipped;
            });
          }
        } catch (e) {
          // 장착 아이템 로드 실패 시 무시
        }
      }
    }
  }

  /// 참가자별 총 거리 계산 및 순위 생성
  List<ParticipantRank> _calculateRankings(List<LogRunContributionEntity> contributions) {
    // 사용자별 총 거리 집계
    final Map<String, double> userDistances = {};
    final Map<String, String> userNicknames = {};

    for (final contribution in contributions) {
      userDistances[contribution.userId] = 
          (userDistances[contribution.userId] ?? 0) + contribution.distance;
      userNicknames[contribution.userId] = contribution.userNickname;
    }

    // 거리 순으로 정렬
    final sortedUsers = userDistances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // ParticipantRank 리스트 생성
    return sortedUsers.map((entry) {
      return ParticipantRank(
        odium: entry.key,
        nickname: userNicknames[entry.key] ?? '알 수 없음',
        totalDistance: entry.value,
        equippedItems: _equippedItemsCache[entry.key],
      );
    }).toList();
  }

  void _showSubmitWorkoutSheet(DateTime startDate, DateTime endDate, ChallengeType challengeType) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubmitWorkoutBottomSheet(
        challengeId: widget.challengeId,
        startDate: startDate,
        endDate: endDate,
        challengeType: challengeType,
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

  Widget _buildScoreSection(
    BuildContext context,
    Map<String, int> awardedScores,
    List<LogRunContributionEntity> contributions,
  ) {
    // 사용자별 닉네임 매핑 (contributions에서 추출)
    final Map<String, String> userNicknames = {};
    for (final contribution in contributions) {
      userNicknames[contribution.userId] = contribution.userNickname;
    }

    // 점수 높은 순으로 정렬
    final sortedEntries = awardedScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                '획득 점수',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sortedEntries.map((entry) {
            final nickname = userNicknames[entry.key] ?? '알 수 없음';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      nickname,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '+${entry.value}점',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('챌린지 삭제'),
        content: const Text(
          '이 챌린지를 삭제하시겠습니까?\n\n모든 참가자의 기여 기록도 함께 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<LogRunBloc>().add(
                    DeleteChallenge(
                      challengeId: widget.challengeId,
                      userId: authState.user.id,
                    ),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: '챌린지 상세',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context, _hasChanges),
      ),
      actions: [
        BlocBuilder<LogRunBloc, LogRunState>(
          builder: (context, state) {
            // 챌린지 정보가 있을 때만 버튼 표시
            if (state is ChallengeDetailLoaded || state is ChallengeUpdated) {
              final challenge = state is ChallengeDetailLoaded
                  ? state.challenge
                  : (state as ChallengeUpdated).challenge;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _showShareSheet(
                      challenge.inviteCode,
                      challenge.isRunning 
                          ? '${challenge.targetDistance.toStringAsFixed(0)}km 달리기 챌린지'
                          : '${challenge.targetDistance.toStringAsFixed(0)}점 헬스 챌린지',
                    ),
                    tooltip: '초대 코드 공유',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _showDeleteConfirmation,
                    tooltip: '챌린지 삭제',
                  ),
                ],
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanges);
      },
      child: BlocConsumer<LogRunBloc, LogRunState>(
      listener: (context, state) {
        if (state is WorkoutSubmitted) {
          _hasChanges = true; // 변경 사항 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('운동 기록이 제출되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ContributionDeleted) {
          _hasChanges = true; // 변경 사항 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('기여 기록이 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          // 상세 페이지 새로고침
          context.read<LogRunBloc>().add(LoadChallengeDetail(widget.challengeId));
        } else if (state is ChallengeDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('챌린지가 삭제되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          // 이전 페이지로 돌아가기 (삭제됨을 알림)
          Navigator.pop(context, true);
          return;
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

          // 참가자들의 장착 아이템 로드
          if (contributions.isNotEmpty) {
            final participantIds = contributions.map((c) => c.userId).toSet().toList();
            _loadParticipantsEquippedItems(participantIds);
          }

          // 순위 계산
          final rankings = _calculateRankings(contributions);

          final themeColor = challenge.isRunning ? Colors.brown : Colors.blueGrey;
          final unitName = challenge.challengeType.unitName;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        themeColor.withValues(alpha: 0.2),
                        themeColor.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // 챌린지 타입 표시
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            challenge.challengeType.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${challenge.challengeType.displayName} 챌린지',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: themeColor,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (challenge.isCompleted) ...[
                        const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
                        const SizedBox(height: 8),
                        Text('챌린지 완료!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ] else ...[
                        Text(
                          challenge.isRunning ? '남은 거리' : '남은 점수',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${challenge.remainingWeight.toStringAsFixed(1)} $unitName',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: challenge.progress.clamp(0.0, 1.0),
                        minHeight: 12,
                        backgroundColor: themeColor.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                      ),
                      const SizedBox(height: 8),
                      Text('${(challenge.progress * 100).clamp(0, 100).toStringAsFixed(0)}% 완료'),
                    ],
                  ),
                ),
              ),
              // 시상대 (참가자가 있을 때만 표시)
              if (rankings.isNotEmpty)
                SliverToBoxAdapter(
                  child: PodiumWidget(rankings: rankings),
                ),
              // 완료된 챌린지면 점수 표시
              if (challenge.isCompleted && challenge.awardedScores.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildScoreSection(context, challenge.awardedScores, contributions),
                ),
              SliverToBoxAdapter(
                child: ContributionFeedWidget(
                  contributions: contributions,
                  challengeId: widget.challengeId,
                ),
              ),
            ],
          );
        }

        return const Center(child: Text('챌린지를 불러오는 중...'));
      },
    ),
    );
  }

  @override
  Widget? buildFloatingActionButton(BuildContext context) {
    return BlocBuilder<LogRunBloc, LogRunState>(
      builder: (context, state) {
        // 챌린지 정보가 있을 때만 FAB 표시
        if (state is ChallengeDetailLoaded || state is ChallengeUpdated) {
          final challenge = state is ChallengeDetailLoaded
              ? state.challenge
              : (state as ChallengeUpdated).challenge;

          // 완료된 챌린지면 FAB 숨김
          if (challenge.isCompleted) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _showSubmitWorkoutSheet(
              challenge.startDate,
              challenge.endDate,
              challenge.challengeType,
            ),
            icon: Icon(challenge.isRunning ? Icons.directions_run : Icons.fitness_center),
            label: Text(challenge.isRunning ? '운동 기록 제출' : '헬스 기록 제출'),
            backgroundColor: challenge.isRunning ? Colors.brown : Colors.blueGrey,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
