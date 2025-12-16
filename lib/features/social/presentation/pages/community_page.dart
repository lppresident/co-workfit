import 'package:flutter/material.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/mixins/tabbed_mixin.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/social/presentation/widgets/friends_list_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/add_friend_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/received_requests_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/sent_requests_tab.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_event.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_event.dart';
import 'package:co_workfit/features/profile/presentation/screens/profile_screen.dart';
import 'package:co_workfit/core/di/injection.dart' as di;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 커뮤니티 페이지 (친구 관리)
class CommunityPage extends BasePage {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends BasePageState<CommunityPage>
    with SingleTickerProviderStateMixin, TabbedMixin {
  @override
  int get tabCount => 4; // 친구 목록, 친구 추가, 받은 요청, 보낸 요청

  @override
  List<String> get tabLabels => const ['친구', '추가', '받은 요청', '보낸 요청'];

  @override
  List<Widget> get tabViews => const [
        FriendsListTab(),
        AddFriendTab(),
        ReceivedRequestsTab(),
        SentRequestsTab(),
      ];

  @override
  void loadInitialData() {
    AppLogger.info('CommunityPage', 'Loading initial data');
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final userId = authState.user.id;
      context.read<SocialBloc>().add(LoadFriends(userId));
      context.read<SocialBloc>().add(LoadReceivedFriendRequests(userId));
      context.read<SocialBloc>().add(LoadSentFriendRequests(userId));
    }
  }

  @override
  void onTabChanged(int index) {
    AppLogger.info('CommunityPage', 'Tab changed to: $index');
  }

  @override
  PreferredSizeWidget buildTabBar() {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      tabs: tabLabels.map((label) => Tab(text: label)).toList(),
    );
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: '친구',
      bottom: buildTabBar(),
      actions: [
        // 프로필/로그아웃 메뉴
        PopupMenuButton<String>(
          icon: const Icon(Icons.person),
          onSelected: (value) {
            if (value == 'profile') {
              _showProfile(context);
            } else if (value == 'logout') {
              _showLogoutDialog(context);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text('프로필'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('로그아웃'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return buildTabBarView();
  }

  void _showProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<ProfileBloc>(
          create: (context) => di.sl<ProfileBloc>()..add(FetchProfileData()),
          child: const ProfileScreen(),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const SignOutRequested());
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
