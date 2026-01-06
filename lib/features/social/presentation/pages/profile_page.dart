import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/core/constants/app_constants.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/craft/domain/entities/equipped_items_entity.dart';
import 'package:co_workfit/features/craft/domain/entities/item_category.dart';
import 'package:co_workfit/features/craft/domain/entities/item_entity.dart';
import 'package:co_workfit/features/craft/domain/entities/item_recipes.dart';
import 'package:co_workfit/features/craft/presentation/widgets/character_widget.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:intl/intl.dart';

/// 유저 프로필 페이지
/// 
/// userId로 접근하여 유저 정보를 표시합니다.
/// 친구 여부에 따라 다른 UI를 제공합니다:
/// - 친구인 경우: 친구 정보 섹션 + 친구 삭제 버튼
/// - 친구가 아닌 경우: 친구 추가 버튼
/// - 본인인 경우: 액션 버튼 없음
class ProfilePage extends BasePage {
  final String userId;
  final String? nickname;

  const ProfilePage({
    super.key,
    required this.userId,
    this.nickname,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends BasePageState<ProfilePage> {
  bool _isLoading = true;
  String? _errorMessage;
  
  // 유저 정보
  String _nickname = '';
  String? _photoUrl;
  EquippedItemsEntity _equippedItems = const EquippedItemsEntity();
  
  // 친구 상태
  bool _isFriend = false;
  bool _isPendingRequest = false;
  bool _isCurrentUser = false;
  DateTime? _friendSince;

  @override
  void loadInitialData() {
    AppLogger.info('ProfilePage', 'Loading user profile: ${widget.userId}');
    _loadUserProfile();
    _checkFriendshipStatus();
  }

  Future<void> _loadUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!doc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = '유저를 찾을 수 없습니다';
        });
        return;
      }

      final data = doc.data()!;
      setState(() {
        _nickname = data['nickname'] as String? ?? 
                    data['displayName'] as String? ?? 
                    widget.nickname ?? 
                    '알 수 없음';
        _photoUrl = data['photoUrl'] as String?;
        
        if (data['equippedItems'] != null) {
          final equippedData = data['equippedItems'] as Map<String, dynamic>;
          _equippedItems = EquippedItemsEntity(
            headItemId: equippedData['headItemId'] as String?,
            bodyItemId: equippedData['bodyItemId'] as String?,
            legsItemId: equippedData['legsItemId'] as String?,
          );
        }
        
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('ProfilePage', '유저 프로필 조회 실패', e);
      setState(() {
        _isLoading = false;
        _errorMessage = '프로필을 불러올 수 없습니다';
      });
    }
  }

  Future<void> _checkFriendshipStatus() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final currentUserId = authState.user.id;

    // 본인인지 확인
    if (currentUserId == widget.userId) {
      setState(() {
        _isCurrentUser = true;
      });
      return;
    }

    try {
      // 친구 관계 확인 (Composite ID 방식)
      final ids = [currentUserId, widget.userId]..sort();
      final friendshipDocId = '${ids[0]}_${ids[1]}';

      final friendshipDoc = await FirebaseFirestore.instance
          .collection('friendships')
          .doc(friendshipDocId)
          .get();

      if (friendshipDoc.exists) {
        final friendshipData = friendshipDoc.data()!;
        final createdAt = friendshipData['createdAt'];
        setState(() {
          _isFriend = true;
          _friendSince = createdAt is Timestamp ? createdAt.toDate() : DateTime.now();
        });
        return;
      }

      // 보낸 친구 요청 확인
      final sentRequestQuery = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: currentUserId)
          .where('toUserId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (sentRequestQuery.docs.isNotEmpty) {
        setState(() {
          _isPendingRequest = true;
        });
      }
    } catch (e) {
      AppLogger.error('ProfilePage', '친구 상태 확인 실패', e);
    }
  }

  void _sendFriendRequest() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    context.read<SocialBloc>().add(
      SendFriendRequestEvent(
        senderId: authState.user.id,
        receiverId: widget.userId,
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text('$_nickname님을 친구 목록에서 삭제하시겠습니까?'),
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
      AppLogger.info('ProfilePage', 'Remove friend: ${widget.userId}');
      context.read<SocialBloc>().add(RemoveFriendEvent(
            userId: authState.user.id,
            friendId: widget.userId,
          ));
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy년 M월 d일').format(date);
  }

  int _getDaysSinceFriend() {
    if (_friendSince == null) return 0;
    return DateTime.now().difference(_friendSince!).inDays;
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return StandardAppBar(
      title: _nickname.isNotEmpty ? _nickname : '프로필',
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocListener<SocialBloc, SocialState>(
      listener: (context, state) {
        if (state is SocialActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          
          if (state.message.contains('친구 요청')) {
            setState(() {
              _isPendingRequest = true;
            });
          } else if (state.message == '친구가 삭제되었습니다') {
            setState(() {
              _isFriend = false;
              _friendSince = null;
            });
            // 친구 목록에서 진입한 경우 이전 페이지로 돌아가기
            Navigator.pop(context);
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
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        final isLoading = state is SocialActionInProgress;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildCharacterSection(),
                  if (_isFriend) ...[
                    const SizedBox(height: 24),
                    _buildFriendshipInfoSection(),
                  ],
                  if (!_isCurrentUser) ...[
                    const SizedBox(height: 24),
                    _buildActionButton(),
                  ],
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
              radius: 48,
              backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: _photoUrl == null
                  ? Text(
                      _nickname.isNotEmpty ? _nickname[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // 유저 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nickname,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_isFriend) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            '친구',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_isCurrentUser) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '나',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_nickname의 캐릭터',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: _buildCharacterView(),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterView() {
    final headItem = _equippedItems.headItemId != null
        ? ItemRecipes.getItemById(_equippedItems.headItemId!)
        : null;
    final bodyItem = _equippedItems.bodyItemId != null
        ? ItemRecipes.getItemById(_equippedItems.bodyItemId!)
        : null;
    final legsItem = _equippedItems.legsItemId != null
        ? ItemRecipes.getItemById(_equippedItems.legsItemId!)
        : null;

    return Column(
      children: [
        // 도트 스타일 캐릭터
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green[50]!,
                Colors.brown[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              CharacterWidget(
                size: 150,
                equippedItems: _equippedItems,
                backgroundColor: Colors.white.withValues(alpha: 0.5),
                borderColor: Colors.brown[400]!,
                showShadow: true,
              ),
              const SizedBox(height: 12),
              // 장착 아이템 표시
              if (_equippedItems.equippedCount > 0)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (headItem != null) _buildEquippedBadge(headItem),
                    if (bodyItem != null) _buildEquippedBadge(bodyItem),
                    if (legsItem != null) _buildEquippedBadge(legsItem),
                  ],
                )
              else
                Text(
                  '장착된 아이템이 없습니다',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 장착 슬롯 목록
        _buildEquipmentSlotRow(ClothingSlot.head, headItem),
        const Divider(height: 1),
        _buildEquipmentSlotRow(ClothingSlot.body, bodyItem),
        const Divider(height: 1),
        _buildEquipmentSlotRow(ClothingSlot.legs, legsItem),
      ],
    );
  }

  Widget _buildEquippedBadge(ItemEntity item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Color(item.themeColorValue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(item.themeColorValue)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.iconEmoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            item.name,
            style: TextStyle(
              fontSize: 11,
              color: Color(item.themeColorValue),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSlotRow(ClothingSlot slot, ItemEntity? item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // 슬롯 아이콘
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                slot.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 슬롯 이름 & 아이템
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                if (item != null)
                  Row(
                    children: [
                      Text(
                        item.iconEmoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '비어있음',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendshipInfoSection() {
    final daysSinceFriend = _getDaysSinceFriend();
    final friendSince = _friendSince != null ? _formatDate(_friendSince!) : '-';

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

  Widget _buildActionButton() {
    if (_isFriend) {
      // 친구인 경우: 친구 삭제 버튼
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

    if (_isPendingRequest) {
      // 친구 요청 대기 중
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_empty),
          label: const Text('친구 요청 대기 중'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    }

    // 친구가 아닌 경우: 친구 추가 버튼
    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        final isLoading = state is SocialActionInProgress &&
            state.actionType == 'send_friend_request';

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _sendFriendRequest,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add),
            label: Text(isLoading ? '요청 중...' : '친구 추가'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      },
    );
  }
}


