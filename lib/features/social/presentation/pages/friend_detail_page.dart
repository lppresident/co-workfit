import 'package:flutter/material.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/core/constants/app_constants.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 친구 상세 페이지 (고스트런 진입점)
class FriendDetailPage extends BasePage {
  final String friendId;
  final String friendName;

  const FriendDetailPage({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<FriendDetailPage> createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends BasePageState<FriendDetailPage> {
  // TODO: Phase 5에서 실제 친구 데이터로 대체
  final List<Map<String, dynamic>> _recentRuns = [];

  @override
  void loadInitialData() {
    AppLogger.info('FriendDetailPage', 'Loading friend detail: ${widget.friendId}');
    // TODO: Phase 5에서 BLoC 이벤트 발생
    // context.read<FriendBloc>().add(LoadFriendDetail(widget.friendId));
    // context.read<GhostRunBloc>().add(LoadFriendRecentRuns(widget.friendId));
  }

  void _startGhostRun() {
    AppLogger.info('FriendDetailPage', 'Start ghost run with friend: ${widget.friendId}');
    // TODO: Phase 5에서 고스트 선택 페이지로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('고스트런 기능은 Phase 5에서 구현됩니다'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: widget.friendName,
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 친구 프로필 카드
          _buildProfileCard(),
          const SizedBox(height: 24),

          // 고스트런 버튼 (가장 눈에 띄게)
          _buildGhostRunButton(),
          const SizedBox(height: 24),

          // 최근 운동 기록
          _buildRecentRunsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            // 프로필 아바타
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),

            // 친구 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friendName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '함께 달린 지 30일',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  // 통계 요약
                  Row(
                    children: [
                      _buildStatChip(Icons.directions_run, '127회'),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.social_distance, '523km'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildGhostRunButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startGhostRun,
        icon: const Icon(Icons.directions_run, size: 28),
        label: const Text(
          '이 친구의 고스트로 달리기',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRunsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 러닝 기록',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // TODO: Phase 5에서 실제 데이터로 대체
        _recentRuns.isEmpty
            ? Card(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.defaultPadding * 2),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_run_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '최근 러닝 기록이 없습니다',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentRuns.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.directions_run),
                      title: Text('러닝 ${index + 1}'),
                      subtitle: const Text('5.2km • 28분 • 5:23/km'),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {
                          AppLogger.info('FriendDetailPage', 'Ghost run selected: ${index + 1}');
                          _startGhostRun();
                        },
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
