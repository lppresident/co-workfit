import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_event.dart';
import 'package:co_workfit/features/workout/presentation/bloc/workout_state.dart';
import 'package:co_workfit/features/workout/presentation/widgets/workout_list_item.dart';
import 'package:co_workfit/features/workout/presentation/pages/health_debug_page.dart';
import 'package:co_workfit/core/di/injection.dart' as di;
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';

/// 메인 대시보드 페이지
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // 앱 첫 진입 시 자동으로 데이터 로드 시도
    // - 권한 있으면: 데이터 표시
    // - 권한 없으면: 권한 요청 UI 표시
    // 새로고침과 동일한 로직을 타도록 구현
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutBloc>().add(const FetchRecentWorkoutsEvent(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Co-WorkFit'),
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
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: 프로필 페이지로 이동
            },
          ),
        ],
      ),
      body: BlocConsumer<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          if (state is WorkoutPermissionDenied) {
            // Health Connect 설치가 필요한 경우 다이얼로그 표시
            if (state.message == 'HEALTH_CONNECT_NOT_INSTALLED') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showHealthConnectInstallDialog(context);
              });
            } else if (state.message == 'HEALTH_PERMISSION_DENIED') {
              // 권한 거부는 카드로만 표시 (다이얼로그 표시 안함)
              print('[DashboardPage] Health Connect 권한이 거부됨');
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
              // Wait for the refresh to complete
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 권한 상태 표시
                  if (state is WorkoutPermissionRequesting)
                    _buildPermissionRequestingCard(context),

                  if (state is WorkoutPermissionDenied)
                    _buildPermissionDeniedCard(context),

                  // 초기 상태일 때도 권한 요청 안내 카드 표시
                  if (state is WorkoutInitial)
                    _buildInitialPermissionCard(context),

                  // 오늘의 요약 카드
                  _buildTodaySummaryCard(context, state),
                  const SizedBox(height: 16),

                  // 최근 운동 기록
                  _buildRecentWorkouts(context, state),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: 운동 추가 페이지로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('수동 운동 추가 기능 준비 중')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('운동 추가'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
            icon: Icon(Icons.people),
            label: '친구',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: '리더보드',
          ),
        ],
        onTap: (index) {
          // TODO: 네비게이션 구현
          if (index != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('해당 기능 준비 중')),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
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
                          print('[DashboardPage] 설정 열기 실패: $e');
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
                  // TODO: 전체 운동 목록 페이지로 이동
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('전체 운동 목록 페이지 준비 중')),
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
                .map((workout) => WorkoutListItem(workout: workout))
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

  /// Health Connect 설치 안내 다이얼로그
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
              // Health Connect 설치 유도
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
                print('[DashboardPage] Health Connect 설치 유도 실패: $e');
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
}
