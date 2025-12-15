import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/social/presentation/widgets/friends_list_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/add_friend_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/received_requests_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/sent_requests_tab.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  void _loadInitialData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final userId = authState.user.id;
      context.read<SocialBloc>().add(LoadFriends(userId));
      context.read<SocialBloc>().add(LoadReceivedFriendRequests(userId));
      context.read<SocialBloc>().add(LoadSentFriendRequests(userId));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '친구 목록'),
            Tab(text: '친구 추가'),
            Tab(text: '받은 요청'),
            Tab(text: '보낸 요청'),
          ],
        ),
      ),
      body: BlocListener<SocialBloc, SocialState>(
        listener: (context, state) {
          if (state is SocialActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            // Reload data after successful action
            final authState = context.read<AuthBloc>().state;
            if (authState is Authenticated) {
              final userId = authState.user.id;
              context.read<SocialBloc>().add(LoadFriends(userId));
              context.read<SocialBloc>().add(LoadReceivedFriendRequests(userId));
              context.read<SocialBloc>().add(LoadSentFriendRequests(userId));
            }
          } else if (state is SocialError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: const [
            FriendsListTab(),
            AddFriendTab(),
            ReceivedRequestsTab(),
            SentRequestsTab(),
          ],
        ),
      ),
    );
  }
}
