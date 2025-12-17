import 'dart:io' show Platform;
import 'package:co_workfit/features/social/presentation/pages/community_page.dart';
import 'package:co_workfit/features/log_run/presentation/pages/log_run_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_event.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_state.dart';
import 'package:co_workfit/features/workout/presentation/widgets/workout_list_item.dart';
import 'package:co_workfit/features/workout/presentation/pages/health_debug_page.dart';
import 'package:co_workfit/features/workout/presentation/pages/workout_list_page.dart';
import 'package:co_workfit/features/workout/presentation/pages/workout_detail_page.dart';
import 'package:co_workfit/core/di/injection.dart' as di;
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 메인 대시보드 페이지 (네비게이션 허브)
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
    _pages = [
      const _DashboardHome(),
      const WorkoutListPage(),
      LogRunPage(key: LogRunPage.globalKey),
      const CommunityPage(),
    ];
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
      case 0:
        // 홈 페이지 새로고침
        context.read<WorkoutBloc>().add(const RefreshWorkoutsEvent());
        break;
      case 2:
        // 통나무런 페이지 새로고침
        LogRunPage.globalKey.currentState?.refreshChallenges();
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: '운동',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.workspaces),
            label: '통나무런',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '친구',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

}


/// 홈 탭의 내용을 표시하는 위젯
class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutBloc>().add(const FetchRecentWorkoutsEvent(days: 7));
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          // Android용 디버그 버튼
          if (Platform.isAndroid)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HealthDebugPage(),
                  ),
                );
              },
              tooltip: 'Health Connect Debug',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WorkoutBloc>().add(const RefreshWorkoutsEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          if (state is WorkoutPermissionDenied) {
            if (state.message == 'HEALTH_CONNECT_NOT_INSTALLED') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showHealthConnectInstallDialog(context);
              });
            } else if (state.message == 'HEALTH_PERMISSION_DENIED') {
              AppLogger.warning('DashboardPage', 'Health Connect 권한이 거부됨');
            }
          } else if (state is WorkoutError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<WorkoutBloc>().add(const RefreshWorkoutsEvent());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state is WorkoutPermissionRequesting)
                    _buildPermissionRequestingCard(context),

                  if (state is WorkoutPermissionDenied)
                    _buildPermissionDeniedCard(context),

                  if (state is WorkoutInitial)
                    _buildInitialPermissionCard(context),

                  _buildTodaySummaryCard(context, state),
                  const SizedBox(height: 16),

                  _buildRecentWorkouts(context, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  void _showHealthConnectInstallDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Health Connect 앱 필요'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Co-WorkFit은 Health Connect를 통해 여러 피트니스 앱의 운동 데이터를 통합합니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 지원되는 앱:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Samsung Health'),
                  const Text('• Google Fit'),
                  const Text('• Garmin Connect'),
                  const Text('• 기타 피트니스 앱'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Play Store에서 Health Connect를 설치하시겠습니까?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('나중에'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final repository = di.sl<WorkoutRepository>();
                await repository.installHealthConnect();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Health Connect 설치 후 다시 돌아와서 권한을 허용해주세요.',
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                AppLogger.error('DashboardPage', 'Health Connect 설치 유도 실패', e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Play Store로 이동할 수 없습니다: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('설치하러 가기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequestingCard(BuildContext context) {
    final healthServiceName = Platform.isIOS ? 'HealthKit' : 'Health Connect';

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '$healthServiceName 권한을 요청하는 중...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildPermissionDeniedCard(BuildContext context) {
    final healthServiceName = Platform.isIOS ? 'HealthKit' : 'Health Connect';

    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  '$healthServiceName 권한 필요',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '운동 데이터를 가져오려면 $healthServiceName 접근 권한이 필요합니다.',
            ),
            const SizedBox(height: 8),
            if (!Platform.isIOS)
              Text(
                '권한 다이얼로그가 표시되지 않는 경우, 아래 "설정 열기" 버튼을 눌러 수동으로 권한을 설정해주세요.',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<WorkoutBloc>()
                          .add(const RequestHealthPermissionEvent());
                    },
                    icon: const Icon(Icons.health_and_safety),
                    label: const Text('권한 허용하기'),
                  ),
                ),
                if (!Platform.isIOS) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final repository = di.sl<WorkoutRepository>();
                          await repository.openHealthConnectSettings();
                        } catch (e) {
                          AppLogger.error('DashboardPage', '설정 열기 실패', e);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('설정을 열 수 없습니다: $e'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('설정 열기'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialPermissionCard(BuildContext context) {
    final isIOS = Platform.isIOS;
    final healthServiceName = isIOS ? 'HealthKit' : 'Health Connect';
    final healthServiceDescription = isIOS
        ? 'Apple 건강 앱의 운동 데이터를 불러오려면 $healthServiceName 연결이 필요합니다.'
        : 'Google Fit, Samsung Health 등 여러 피트니스 앱의 운동 데이터를 불러오려면 $healthServiceName 연결이 필요합니다.';

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  '건강 데이터 연결',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(healthServiceDescription),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<WorkoutBloc>()
                    .add(const RequestHealthPermissionEvent());
              },
              icon: const Icon(Icons.link),
              label: Text('$healthServiceName 연결하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummaryCard(BuildContext context, WorkoutState state) {
    final isLoading =
        state is WorkoutLoading || state is WorkoutPermissionRequesting;
    final hasData = state is WorkoutLoaded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘의 성과',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    '점수',
                    hasData ? '${state.totalScore}' : '0',
                    Icons.star,
                  ),
                  _buildStatItem(
                    context,
                    '시간',
                    hasData ? '${state.totalDuration}분' : '0분',
                    Icons.timer,
                  ),
                  _buildStatItem(
                    context,
                    '칼로리',
                    hasData ? '${state.totalCalories}' : '0',
                    Icons.local_fire_department,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildRecentWorkouts(BuildContext context, WorkoutState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '최근 운동',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (state is WorkoutLoaded && state.workouts.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutListPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('전체보기'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (state is WorkoutLoading || state is WorkoutPermissionRequesting)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (state is WorkoutEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '운동 기록이 없습니다',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '첫 운동을 시작해보세요!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (state is WorkoutLoaded)
          Column(
            children: state.workouts
                .take(5) // 최근 5개만 표시
                .map((workout) => WorkoutListItem(
                      workout: workout,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutDetailPage(workout: workout),
                          ),
                        );
                      },
                    ))
                .toList(),
          )
        else if (state is WorkoutPermissionDenied)
          const SizedBox.shrink()
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  '운동 데이터를 불러오려면\n위에서 권한을 허용해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
