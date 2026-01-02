import 'package:co_workfit/features/social/presentation/pages/community_page.dart';
import 'package:co_workfit/features/log_run/presentation/pages/log_run_page.dart';
import 'package:co_workfit/features/workout/presentation/pages/workout_list_page.dart';
import 'package:co_workfit/features/profile/presentation/screens/profile_screen.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_event.dart';
import 'package:co_workfit/core/di/injection.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 메인 대시보드 페이지 (네비게이션 허브)
/// 
/// 4탭 구조: 운동, 챌린지, 친구, 프로필
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  // 페이지들을 미리 생성해서 상태 유지
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
    _pages = [
      const WorkoutListPage(),
      LogRunPage(key: LogRunPage.globalKey),
      const CommunityPage(),
      BlocProvider<ProfileBloc>(
        create: (context) => di.sl<ProfileBloc>()..add(FetchProfileData()),
        child: const ProfileScreen(),
      ),
    ];
  }

  void _onPageChanged() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page?.round();
    if (page == null) return;

    // 프로필 탭(index 3)으로 전환될 때 AuthBloc 새로고침
    if (page == 3 && _selectedIndex != 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AuthBloc>().add(const AuthRefreshUserRequested());
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // 같은 탭을 다시 클릭한 경우 - 페이지 새로고침
      _refreshCurrentPage(index);
    } else {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  void _refreshCurrentPage(int index) {
    // 각 페이지별 새로고침 로직
    switch (index) {
      case 1:
        // 챌린지 페이지 새로고침
        LogRunPage.globalKey.currentState?.refreshChallenges();
        break;
      case 3:
        // 프로필 페이지 새로고침
        // ProfileBloc은 별도 Provider로 관리되므로 여기서는 처리하지 않음
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // 스와이프로 페이지 전환 방지
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: '운동',
          ),
          NavigationDestination(
            icon: Icon(Icons.forest_outlined),
            selectedIcon: Icon(Icons.forest),
            label: '챌린지',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '친구',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}
