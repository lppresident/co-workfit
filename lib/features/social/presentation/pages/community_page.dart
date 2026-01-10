import 'package:flutter/material.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/social/presentation/widgets/friends_list_tab.dart';
import 'package:co_workfit/features/social/presentation/pages/add_friend_page.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 커뮤니티 페이지 (친구 관리)
class CommunityPage extends BasePage {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();

  // DashboardPage에서 새로고침을 트리거할 수 있도록 GlobalKey 제공
  static final GlobalKey<_CommunityPageState> globalKey = GlobalKey<_CommunityPageState>();
}

class _CommunityPageState extends BasePageState<CommunityPage> {
  @override
  void loadInitialData() {
    AppLogger.info('CommunityPage', 'Loading initial data');
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final userId = authState.user.id;
      context.read<SocialBloc>().add(LoadFriendsData(userId));
    }
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return const StandardAppBar(
      title: '친구',
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return const FriendsListTab();
  }

  @override
  Widget? buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddFriendPage(),
          ),
        );
      },
      child: const Icon(Icons.person_add),
    );
  }
}
