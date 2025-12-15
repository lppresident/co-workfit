import 'package:flutter/material.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/mixins/tabbed_mixin.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/social/presentation/widgets/leaderboard/global_leaderboard_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/leaderboard/friends_leaderboard_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/friends_list_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/add_friend_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/received_requests_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/sent_requests_tab.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_event.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 커뮤니티 페이지 (리더보드 + 친구 + 활동 피드)
class CommunityPage extends BasePage {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends BasePageState<CommunityPage>
    with SingleTickerProviderStateMixin, TabbedMixin {
  LeaderboardType _selectedLeaderboardType = LeaderboardType.allTime;

  @override
  int get tabCount => 2; // 리더보드, 친구 (활동 피드는 Phase 6)

  @override
  List<String> get tabLabels => const ['리더보드', '친구'];

  @override
  List<Widget> get tabViews => [
    _buildLeaderboardTab(),
    _buildFriendsTab(),
  ];

  @override
  void loadInitialData() {
    AppLogger.info('CommunityPage', 'Loading initial data');
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      // 리더보드 데이터 로드
      context.read<LeaderboardBloc>().add(
            LoadGlobalLeaderboard(type: _selectedLeaderboardType),
          );
      context.read<LeaderboardBloc>().add(
            LoadFriendsLeaderboard(
              userId: authState.user.id,
              type: _selectedLeaderboardType,
            ),
          );

      // 친구 데이터 로드
      final userId = authState.user.id;
      context.read<SocialBloc>().add(LoadFriends(userId));
      context.read<SocialBloc>().add(LoadReceivedFriendRequests(userId));
      context.read<SocialBloc>().add(LoadSentFriendRequests(userId));
    }
  }

  @override
  void onTabChanged(int index) {
    AppLogger.info('CommunityPage', 'Tab changed to: $index');
    // 탭 변경 시 필요한 추가 로직
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: '커뮤니티',
      bottom: buildTabBar(),
      actions: tabController.index == 0
          ? [_buildLeaderboardFilterButton()]
          : null,
    );
  }

  Widget _buildLeaderboardFilterButton() {
    return PopupMenuButton<LeaderboardType>(
      icon: const Icon(Icons.filter_list),
      tooltip: '기간 선택',
      onSelected: _changeLeaderboardType,
      itemBuilder: (context) => LeaderboardType.values
          .map(
            (type) => PopupMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(
                    _selectedLeaderboardType == type
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(type.getDisplayName()),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  void _changeLeaderboardType(LeaderboardType newType) {
    setState(() => _selectedLeaderboardType = newType);

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<LeaderboardBloc>().add(ChangeLeaderboardType(newType));
      context.read<LeaderboardBloc>().add(
            LoadGlobalLeaderboard(type: newType),
          );
      context.read<LeaderboardBloc>().add(
            LoadFriendsLeaderboard(
              userId: authState.user.id,
              type: newType,
            ),
          );
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return buildTabBarView();
  }

  Widget _buildLeaderboardTab() {
    return Column(
      children: [
        // 리더보드 내부 탭 (전체/친구)
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _leaderboardTabController,
            tabs: const [
              Tab(text: '전체'),
              Tab(text: '친구'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _leaderboardTabController,
            children: const [
              GlobalLeaderboardTab(),
              FriendsLeaderboardTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsTab() {
    return Column(
      children: [
        // 친구 내부 탭 (목록/추가/받은요청/보낸요청)
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _friendsTabController,
            isScrollable: true,
            tabs: const [
              Tab(text: '친구 목록'),
              Tab(text: '친구 추가'),
              Tab(text: '받은 요청'),
              Tab(text: '보낸 요청'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _friendsTabController,
            children: const [
              FriendsListTab(),
              AddFriendTab(),
              ReceivedRequestsTab(),
              SentRequestsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // 리더보드용 내부 TabController
  late TabController _leaderboardTabController;
  late TabController _friendsTabController;

  @override
  void initState() {
    super.initState();
    _leaderboardTabController = TabController(length: 2, vsync: this);
    _friendsTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _leaderboardTabController.dispose();
    _friendsTabController.dispose();
    super.dispose();
  }
}
