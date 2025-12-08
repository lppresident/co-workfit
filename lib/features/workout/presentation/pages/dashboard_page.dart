import 'package:flutter/material.dart';

/// 메인 대시보드 페이지
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Co-WorkFit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: 프로필 페이지로 이동
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 오늘의 요약 카드
            _buildTodaySummaryCard(context),
            const SizedBox(height: 16),

            // 주간 통계
            _buildWeeklyStatsCard(context),
            const SizedBox(height: 16),

            // 리더보드 미리보기
            _buildLeaderboardPreview(context),
            const SizedBox(height: 16),

            // 최근 운동 기록
            _buildRecentWorkouts(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: 운동 추가 페이지로 이동
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
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildTodaySummaryCard(BuildContext context) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, '점수', '0', Icons.star),
                _buildStatItem(context, '시간', '0분', Icons.timer),
                _buildStatItem(context, '칼로리', '0', Icons.local_fire_department),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
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

  Widget _buildWeeklyStatsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이번 주 통계',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              alignment: Alignment.center,
              child: const Text('차트 영역 (추후 fl_chart 구현)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardPreview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '리더보드',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // TODO: 전체 리더보드 페이지로 이동
                  },
                  child: const Text('전체보기'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('친구 순위 표시 영역'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentWorkouts(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 운동',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('운동 기록이 없습니다.\n첫 운동을 시작해보세요!'),
            ),
          ],
        ),
      ),
    );
  }
}
