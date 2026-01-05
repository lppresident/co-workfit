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
import 'package:co_workfit/features/craft/domain/entities/item_recipes.dart';
import 'package:co_workfit/features/craft/presentation/widgets/character_widget.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';

/// 유저 프로필 페이지
/// 
/// userId로 접근하여 유저 정보를 표시합니다.
/// 친구가 아닌 유저도 볼 수 있으며, 친구 추가 기능을 제공합니다.
class UserProfilePage extends BasePage {
  final String userId;
  final String? nickname;

  const UserProfilePage({
    super.key,
    required this.userId,
    this.nickname,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends BasePageState<UserProfilePage> {
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

  @override
  void loadInitialData() {
    AppLogger.info('UserProfilePage', 'Loading user profile: ${widget.userId}');
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
      AppLogger.error('UserProfilePage', '유저 프로필 조회 실패', e);
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
      // 친구 관계 확인
      final friendshipQuery = await FirebaseFirestore.instance
          .collection('friendships')
          .where('userId', isEqualTo: currentUserId)
          .where('friendId', isEqualTo: widget.userId)
          .limit(1)
          .get();

      if (friendshipQuery.docs.isNotEmpty) {
        setState(() {
          _isFriend = true;
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
      AppLogger.error('UserProfilePage', '친구 상태 확인 실패', e);
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileCard(),
          const SizedBox(height: 24),
          _buildCharacterSection(),
          if (!_isCurrentUser) ...[
            const SizedBox(height: 24),
            _buildActionButton(),
          ],
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterSection() {
    // 장착 아이템 조회
    final headItem = _equippedItems.headItemId != null
        ? ItemRecipes.allItems
            .where((item) => item.id == _equippedItems.headItemId)
            .firstOrNull
        : null;
    final bodyItem = _equippedItems.bodyItemId != null
        ? ItemRecipes.allItems
            .where((item) => item.id == _equippedItems.bodyItemId)
            .firstOrNull
        : null;
    final legsItem = _equippedItems.legsItemId != null
        ? ItemRecipes.allItems
            .where((item) => item.id == _equippedItems.legsItemId)
            .firstOrNull
        : null;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_nickname의 캐릭터',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Center(
              child: CharacterWidget(
                equippedItems: _equippedItems,
                size: 200,
              ),
            ),
            const SizedBox(height: 16),
            _buildEquippedItemsList(headItem, bodyItem, legsItem),
          ],
        ),
      ),
    );
  }

  Widget _buildEquippedItemsList(
    dynamic headItem,
    dynamic bodyItem,
    dynamic legsItem,
  ) {
    final items = [
      (ClothingSlot.head, headItem),
      (ClothingSlot.body, bodyItem),
      (ClothingSlot.legs, legsItem),
    ];

    return Column(
      children: items.map((entry) {
        final slot = entry.$1;
        final item = entry.$2;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    slot == ClothingSlot.head ? '🎩' :
                    slot == ClothingSlot.body ? '👕' : '👖',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                slot == ClothingSlot.head ? '머리' :
                slot == ClothingSlot.body ? '상의' : '하의',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const Spacer(),
              Text(
                item?.name ?? '없음',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: item != null ? FontWeight.bold : FontWeight.normal,
                      color: item != null ? null : Colors.grey[400],
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton() {
    if (_isFriend) {
      return const SizedBox.shrink(); // 이미 친구인 경우 버튼 없음
    }

    if (_isPendingRequest) {
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

