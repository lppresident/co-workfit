import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/core/constants/app_constants.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/social/domain/entities/friendship_entity.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:intl/intl.dart';

/// 친구 상세 페이지
class FriendDetailPage extends BasePage {
  final FriendshipEntity friend;

  const FriendDetailPage({
    super.key,
    required this.friend,
  });

  @override
  State<FriendDetailPage> createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends BasePageState<FriendDetailPage> {
  @override
  void loadInitialData() {
    AppLogger.info('FriendDetailPage', 'Loading friend detail: ${widget.friend.friendId}');
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text('${widget.friend.friendName ?? '이 친구'}님을 친구 목록에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _removeFriend();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _removeFriend() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      AppLogger.info('FriendDetailPage', 'Remove friend: ${widget.friend.friendId}');
      context.read<SocialBloc>().add(RemoveFriendEvent(
            userId: authState.user.id,
            friendId: widget.friend.friendId,
          ));
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy년 M월 d일').format(date);
  }

  int _getDaysSinceFriend() {
    return DateTime.now().difference(widget.friend.createdAt).inDays;
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: widget.friend.friendNickname ?? widget.friend.friendName ?? '친구 상세',
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocListener<SocialBloc, SocialState>(
      listener: (context, state) {
        if (state is SocialActionSuccess && state.message == '친구가 삭제되었습니다') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // 삭제 후 이전 페이지로 돌아가기
        } else if (state is SocialError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<SocialBloc, SocialState>(
        builder: (context, state) {
          final isLoading = state is SocialActionInProgress &&
              state.actionType == 'remove_friend';

          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    _buildFriendshipInfoSection(),
                    const SizedBox(height: 24),
                    _buildDeleteButton(),
                  ],
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard() {
    final friendNickname = widget.friend.friendNickname ?? widget.friend.friendName ?? '알 수 없음';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            // 프로필 아바타
            CircleAvatar(
              radius: 48,
              backgroundImage: widget.friend.friendPhotoUrl != null
                  ? NetworkImage(widget.friend.friendPhotoUrl!)
                  : null,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: widget.friend.friendPhotoUrl == null
                  ? Text(
                      friendNickname.isNotEmpty ? friendNickname[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // 친구 정보
            Expanded(
              child: Text(
                friendNickname,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendshipInfoSection() {
    final daysSinceFriend = _getDaysSinceFriend();
    final friendSince = _formatDate(widget.friend.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '친구 정보',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: '친구가 된 날',
                  value: friendSince,
                ),
                const Divider(),
                _buildInfoRow(
                  icon: Icons.schedule,
                  label: '함께한 기간',
                  value: daysSinceFriend == 0 ? '오늘' : '$daysSinceFriend일',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showDeleteConfirmDialog,
        icon: const Icon(Icons.person_remove, color: Colors.red),
        label: const Text('친구 삭제'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: EdgeInsets.all(AppConstants.defaultPadding),
        ),
      ),
    );
  }
}
