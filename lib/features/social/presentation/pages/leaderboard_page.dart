import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_event.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_state.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/social/presentation/widgets/leaderboard/global_leaderboard_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/leaderboard/friends_leaderboard_tab.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardType _selectedType = LeaderboardType.allTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadDataForTab(_tabController.index);
      }
    });
  }

  void _loadInitialData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<LeaderboardBloc>().add(
        LoadGlobalLeaderboard(type: _selectedType),
      );
      context.read<LeaderboardBloc>().add(
        LoadFriendsLeaderboard(
          userId: authState.user.id,
          type: _selectedType,
        ),
      );
    }
  }

  void _loadDataForTab(int index) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      if (index == 0) {
        context.read<LeaderboardBloc>().add(
          RefreshGlobalLeaderboard(type: _selectedType),
        );
      } else {
        context.read<LeaderboardBloc>().add(
          RefreshFriendsLeaderboard(
            userId: authState.user.id,
            type: _selectedType,
          ),
        );
      }
    }
  }

  void _changeLeaderboardType(LeaderboardType newType) {
    setState(() {
      _selectedType = newType;
    });

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<LeaderboardBloc>().add(ChangeLeaderboardType(newType));

      if (_tabController.index == 0) {
        context.read<LeaderboardBloc>().add(
          LoadGlobalLeaderboard(type: newType),
        );
      } else {
        context.read<LeaderboardBloc>().add(
          LoadFriendsLeaderboard(
            userId: authState.user.id,
            type: newType,
          ),
        );
      }
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
        title: const Text('리더보드'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '친구'),
          ],
        ),
        actions: [
          PopupMenuButton<LeaderboardType>(
            icon: const Icon(Icons.filter_list),
            tooltip: '기간 선택',
            onSelected: _changeLeaderboardType,
            itemBuilder: (context) => [
              ...LeaderboardType.values.map((type) => PopupMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      _selectedType == type
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(type.getDisplayName()),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
      body: BlocListener<LeaderboardBloc, LeaderboardState>(
        listener: (context, state) {
          if (state is LeaderboardError) {
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
            GlobalLeaderboardTab(),
            FriendsLeaderboardTab(),
          ],
        ),
      ),
    );
  }
}
