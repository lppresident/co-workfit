import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/empty_challenge_widget.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/challenge_card_widget.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/create_challenge_bottom_sheet.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/invite_code_bottom_sheet.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/challenge_invites_section.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/challenge_view_toggle.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/monthly_calendar_widget.dart';
import 'package:co_workfit/features/log_run/presentation/models/calendar_challenge_data.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_bloc.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_event.dart';
import 'package:co_workfit/features/log_run/presentation/bloc/challenge_state.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_invite_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_archive_entity.dart';
import 'package:co_workfit/features/log_run/presentation/pages/challenge_detail_page.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 챌린지 메인 페이지
class ChallengePage extends BasePage {
  const ChallengePage({super.key});

  @override
  int? get pageIndex => 1; // Dashboard의 챌린지 탭 인덱스

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends BasePageState<ChallengePage> {
  ChallengeViewType _viewType = ChallengeViewType.list;
  DateTime _selectedDate = DateTime.now();
  List<ChallengeEntity> _currentChallenges = [];
  List<ChallengeInviteEntity> _currentInvites = [];
  List<ChallengeArchiveEntity> _archives = [];
  bool _isInitialLoading = true;
  bool _isLoadingViewType = true; // 뷰 타입 로딩 중

  @override
  void initState() {
    super.initState();
    _loadSavedViewType();
  }

  Future<void> _loadSavedViewType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedViewType = prefs.getString('challenge_view_type');
      if (savedViewType != null) {
        setState(() {
          _viewType = savedViewType == 'calendar'
              ? ChallengeViewType.calendar
              : ChallengeViewType.list;
          _isLoadingViewType = false;
        });
      } else {
        setState(() {
          _isLoadingViewType = false;
        });
      }
    } catch (e) {
      AppLogger.error('ChallengePage', 'Failed to load saved view type', e);
      setState(() {
        _isLoadingViewType = false;
      });
    }
  }

  Future<void> _saveViewType(ChallengeViewType viewType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'challenge_view_type',
        viewType == ChallengeViewType.calendar ? 'calendar' : 'list',
      );
    } catch (e) {
      AppLogger.error('ChallengePage', 'Failed to save view type', e);
    }
  }

  @override
  void loadInitialData() {
    refreshChallenges();
    loadInvites();
    loadArchives();
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

  /// 아카이브 로드
  void loadArchives() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ChallengeBloc>().add(LoadChallengeArchives(authState.user.id));
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
        // 챌린지 및 초대 상태 저장
        if (state is ChallengesLoaded ||
            state is ChallengeDetailLoaded ||
            state is WorkoutSubmitted ||
            state is MyInvitesUpdated) {
          _currentChallenges = _getChallenges(state);
          _currentInvites = _getInvites(state);
          _isInitialLoading = false;
        }

        // 아카이브 상태 처리
        if (state is ChallengeArchivesLoaded) {
          _archives = state.archives;
          // 챌린지가 이미 로드되어 있으면 현재 상태 유지, 아니면 state의 챌린지 사용
          if (_currentChallenges.isEmpty && state.challenges.isNotEmpty) {
            _currentChallenges = state.challenges;
          }
          _isInitialLoading = false;
        }

        // 챌린지 로드 완료 시에도 초기 로딩 해제
        if (state is ChallengeEmpty) {
          _currentChallenges = [];
          _currentInvites = _getInvites(state);
          _isInitialLoading = false;
        }

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
        // 뷰 타입 로딩 중이거나 초기 데이터 로딩 중일 때 로딩 표시
        if (_isLoadingViewType || _isInitialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Empty 상태
        if (state is ChallengeEmpty) {
          // Empty 상태에서도 초대가 있을 수 있음
          if (_currentInvites.isNotEmpty || _archives.isNotEmpty) {
            return _buildMainView(_currentChallenges, _currentInvites);
          }
          return EmptyChallengeWidget(
            onCreateOrJoin: _showActionSelectionDialog,
          );
        }

        // 챌린지 목록이 있는 상태들
        if (state is ChallengesLoaded || state is ChallengeDetailLoaded || state is WorkoutSubmitted || state is MyInvitesLoaded || state is MyInvitesUpdated || state is ChallengeArchivesLoaded) {
          if (_currentChallenges.isEmpty && _currentInvites.isEmpty && _archives.isEmpty) {
            return EmptyChallengeWidget(
              onCreateOrJoin: _showActionSelectionDialog,
            );
          }

          return _buildMainView(_currentChallenges, _currentInvites);
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

  Widget _buildMainView(
    List<ChallengeEntity> challenges,
    List<ChallengeInviteEntity> invites,
  ) {
    return Column(
      children: [
        ChallengeViewToggle(
          viewType: _viewType,
          onChanged: (type) {
            setState(() {
              _viewType = type;
            });
            _saveViewType(type);
          },
        ),
        Expanded(
          child: _viewType == ChallengeViewType.calendar
              ? _buildCalendarView(challenges, invites)
              : _buildChallengeListWithInvites(challenges, invites),
        ),
      ],
    );
  }

  Widget _buildCalendarView(
    List<ChallengeEntity> challenges,
    List<ChallengeInviteEntity> invites,
  ) {
    final challengeDataMap = _buildChallengeDataMap(challenges);

    return SingleChildScrollView(
      child: Column(
        children: [
          // 월간 캘린더
          MonthlyCalendarWidget(
            selectedDate: _selectedDate,
            challengeDataMap: challengeDataMap,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          const Divider(),
          // 선택된 날짜의 챌린지 목록
          _buildSelectedDateChallenges(challenges, invites),
        ],
      ),
    );
  }

  Widget _buildSelectedDateChallenges(
    List<ChallengeEntity> challenges,
    List<ChallengeInviteEntity> invites,
  ) {
    final selectedChallenges = challenges.where((c) {
      final startDate = DateTime(c.startDate.year, c.startDate.month, c.startDate.day);
      final endDate = DateTime(c.endDate.year, c.endDate.month, c.endDate.day);
      final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      return !selected.isBefore(startDate) && !selected.isAfter(endDate);
    }).toList();

    final selectedArchives = _archives.where((a) {
      final endDate = DateTime(a.endDate.year, a.endDate.month, a.endDate.day);
      final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      return endDate.isAtSameMomentAs(selected);
    }).toList();

    // 성공한 아카이브와 실패한 아카이브 분리
    final successArchives = selectedArchives.where((a) => a.isSuccess).toList();
    final failureArchives = selectedArchives.where((a) => !a.isSuccess).toList();

    if (selectedChallenges.isEmpty && selectedArchives.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            '${_selectedDate.month}월 ${_selectedDate.day}일\n챌린지가 없습니다',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 성공한 챌린지 (우선 표시)
          if (successArchives.isNotEmpty) ...[
            const Text(
              '성공한 챌린지',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...successArchives.map((archive) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text('목표: ${archive.targetWeight}kg'),
                    subtitle: const Text('성공'),
                    trailing: Text(
                      '${archive.endDate.month}/${archive.endDate.day}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )),
          ],
          // 실패한 챌린지
          if (failureArchives.isNotEmpty) ...[
            if (successArchives.isNotEmpty) const SizedBox(height: 16),
            const Text(
              '실패한 챌린지',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...failureArchives.map((archive) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.cancel,
                      color: Colors.red,
                    ),
                    title: Text('목표: ${archive.targetWeight}kg'),
                    subtitle: const Text('실패'),
                    trailing: Text(
                      '${archive.endDate.month}/${archive.endDate.day}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )),
          ],
          // 진행 중인 챌린지
          if (selectedChallenges.isNotEmpty) ...[
            if (selectedArchives.isNotEmpty) const SizedBox(height: 16),
            const Text(
              '진행 중인 챌린지',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...selectedChallenges.map((challenge) => ChallengeCardWidget(
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
                    if (mounted) {
                      refreshChallenges();
                    }
                  },
                )),
          ],
        ],
      ),
    );
  }

  Map<DateTime, CalendarChallengeData> _buildChallengeDataMap(
    List<ChallengeEntity> challenges,
  ) {
    final Map<DateTime, CalendarChallengeData> dataMap = {};

    // 현재 챌린지 데이터 추가
    for (final challenge in challenges) {
      final endDate = DateTime(
        challenge.endDate.year,
        challenge.endDate.month,
        challenge.endDate.day,
      );

      final existing = dataMap[endDate];
      if (existing == null) {
        dataMap[endDate] = CalendarChallengeData(
          date: endDate,
          activeChallenges: challenge.status == ChallengeStatus.active ? [challenge] : [],
          completedChallenges: challenge.status == ChallengeStatus.completed ? [challenge] : [],
        );
      } else {
        final updated = CalendarChallengeData(
          date: endDate,
          activeChallenges: challenge.status == ChallengeStatus.active
              ? [...existing.activeChallenges, challenge]
              : existing.activeChallenges,
          completedChallenges: challenge.status == ChallengeStatus.completed
              ? [...existing.completedChallenges, challenge]
              : existing.completedChallenges,
          archivedChallenges: existing.archivedChallenges,
        );
        dataMap[endDate] = updated;
      }
    }

    // 아카이브 데이터 추가
    for (final archive in _archives) {
      final endDate = DateTime(
        archive.endDate.year,
        archive.endDate.month,
        archive.endDate.day,
      );

      final existing = dataMap[endDate];
      if (existing == null) {
        dataMap[endDate] = CalendarChallengeData(
          date: endDate,
          archivedChallenges: [archive],
        );
      } else {
        final updated = CalendarChallengeData(
          date: endDate,
          activeChallenges: existing.activeChallenges,
          completedChallenges: existing.completedChallenges,
          archivedChallenges: [...existing.archivedChallenges, archive],
        );
        dataMap[endDate] = updated;
      }
    }

    return dataMap;
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
        if (_currentChallenges.isNotEmpty || _currentInvites.isNotEmpty || _archives.isNotEmpty) {
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
