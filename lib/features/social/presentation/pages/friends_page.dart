import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/mixins/tabbed_mixin.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/social/presentation/widgets/friends_list_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/add_friend_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/received_requests_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/sent_requests_tab.dart';

class FriendsPage extends BasePage {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends BasePageState<FriendsPage>
    with SingleTickerProviderStateMixin, TabbedMixin {
  @override
  int get tabCount => 4;

  @override
  List<String> get tabLabels => const [
        '친구 목록',
        '친구 추가',
        '받은 요청',
        '보낸 요청',
      ];

  @override
  List<Widget> get tabViews => const [
        FriendsListTab(),
        AddFriendTab(),
        ReceivedRequestsTab(),
        SentRequestsTab(),
      ];

  @override
  void loadInitialData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final userId = authState.user.id;
      context.read<SocialBloc>().add(LoadFriends(userId));
      context.read<SocialBloc>().add(LoadReceivedFriendRequests(userId));
      context.read<SocialBloc>().add(LoadSentFriendRequests(userId));
    }
  }

  void _reloadAllData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final userId = authState.user.id;
      context.read<SocialBloc>().add(LoadFriends(userId));
      context.read<SocialBloc>().add(LoadReceivedFriendRequests(userId));
      context.read<SocialBloc>().add(LoadSentFriendRequests(userId));
    }
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: '친구',
      bottom: buildTabBar(),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocListener<SocialBloc, SocialState>(
      listener: (context, state) {
        if (state is SocialActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          _reloadAllData();
        } else if (state is SocialError && state.previousState == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: buildTabBarView(),
    );
  }
}
