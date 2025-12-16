import 'package:flutter/material.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/log_run/presentation/widgets/empty_log_run_widget.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// 통나무런 메인 페이지
class LogRunPage extends BasePage {
  const LogRunPage({super.key});

  @override
  State<LogRunPage> createState() => _LogRunPageState();
}

class _LogRunPageState extends BasePageState<LogRunPage> {
  // TODO: Phase 5에서 실제 그룹 데이터로 대체
  final List<dynamic> _groups = [];

  @override
  void loadInitialData() {
    AppLogger.info('LogRunPage', 'Loading log run groups');
    // TODO: Phase 5에서 BLoC 이벤트 발생
    // context.read<LogRunBloc>().add(LoadLogRunGroups());
  }

  void _showCreateOrJoinDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('새 그룹 생성'),
              subtitle: const Text('친구들과 함께 목표를 달성하세요'),
              onTap: () {
                Navigator.pop(context);
                _createNewGroup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('그룹 참가'),
              subtitle: const Text('초대 코드로 그룹에 참가하세요'),
              onTap: () {
                Navigator.pop(context);
                _joinExistingGroup();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewGroup() {
    AppLogger.info('LogRunPage', 'Create new group tapped');
    // TODO: Phase 5에서 그룹 생성 페이지로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('그룹 생성 기능은 Phase 5에서 구현됩니다'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _joinExistingGroup() {
    AppLogger.info('LogRunPage', 'Join existing group tapped');
    // TODO: Phase 5에서 그룹 참가 다이얼로그 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('그룹 참가 기능은 Phase 5에서 구현됩니다'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return const StandardAppBar(
      title: '통나무런',
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    // TODO: Phase 5에서 BlocBuilder로 대체
    return _groups.isEmpty
        ? EmptyLogRunWidget(
            onCreateOrJoin: _showCreateOrJoinDialog,
          )
        : _buildGroupList();
  }

  @override
  Widget? buildFloatingActionButton(BuildContext context) {
    // 그룹이 있을 때만 FloatingActionButton 표시
    if (_groups.isNotEmpty) {
      return FloatingActionButton(
        onPressed: _showCreateOrJoinDialog,
        tooltip: '그룹 생성 또는 참가',
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  Widget _buildGroupList() {
    // TODO: Phase 5에서 실제 그룹 카드 위젯으로 구현
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text('그룹 ${index + 1}'),
            subtitle: const Text('그룹 설명'),
            onTap: () {
              AppLogger.info('LogRunPage', 'Group tapped: ${index + 1}');
              // TODO: 그룹 상세 페이지로 이동
            },
          ),
        );
      },
    );
  }
}
