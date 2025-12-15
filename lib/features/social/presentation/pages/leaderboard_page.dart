import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/mixins/tabbed_mixin.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_event.dart';
import 'package:co_workfit/features/social/presentation/bloc/leaderboard/leaderboard_state.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/social/presentation/widgets/leaderboard/global_leaderboard_tab.dart';
import 'package:co_workfit/features/social/presentation/widgets/leaderboard/friends_leaderboard_tab.dart';

class LeaderboardPage extends BasePage {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends BasePageState<LeaderboardPage>
    with SingleTickerProviderStateMixin, TabbedMixin {
  LeaderboardType _selectedType = LeaderboardType.allTime;

  @override
  int get tabCount => 2;

  @override
  List<String> get tabLabels => const ['전체', '친구'];

  @override
  List<Widget> get tabViews => const [
        GlobalLeaderboardTab(),
        FriendsLeaderboardTab(),
      ];

  @override
  void loadInitialData() {
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

  @override
  void onTabChanged(int index) {
    _loadDataForTab(index);
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
    setState(() => _selectedType = newType);

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<LeaderboardBloc>().add(ChangeLeaderboardType(newType));

      if (tabController.index == 0) {
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
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: '리더보드',
      bottom: buildTabBar(),
      actions: [
        PopupMenuButton<LeaderboardType>(
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
                        _selectedType == type
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
        ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocListener<LeaderboardBloc, LeaderboardState>(
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
      child: buildTabBarView(),
    );
  }
}
