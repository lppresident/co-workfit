import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/craft/domain/entities/equipped_items_entity.dart';
import 'package:co_workfit/features/craft/domain/entities/item_entity.dart';
import 'package:co_workfit/features/craft/domain/entities/item_recipes.dart';
import 'package:co_workfit/features/craft/presentation/pages/craft_page.dart';
import 'package:co_workfit/features/craft/presentation/pages/character_page.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_event.dart';
import 'package:co_workfit/features/profile/presentation/bloc/profile_state.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_bloc.dart';
import 'package:co_workfit/features/wood/presentation/bloc/wood_state.dart';
import 'package:co_workfit/features/wood/presentation/pages/settlement_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  EquippedItemsEntity? _equippedItems;
  bool _isLoadingEquipped = true;

  @override
  void initState() {
    super.initState();
    _loadEquippedItems();
  }

  Future<void> _loadEquippedItems() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authState.user.id)
          .get();

      if (doc.exists && doc.data()?['equippedItems'] != null) {
        final data = doc.data()!['equippedItems'] as Map<String, dynamic>;
        setState(() {
          _equippedItems = EquippedItemsEntity(
            headItemId: data['headItemId'] as String?,
            bodyItemId: data['bodyItemId'] as String?,
            legsItemId: data['legsItemId'] as String?,
          );
          _isLoadingEquipped = false;
        });
      } else {
        setState(() {
          _equippedItems = const EquippedItemsEntity();
          _isLoadingEquipped = false;
        });
      }
    } catch (e) {
      setState(() {
        _equippedItems = const EquippedItemsEntity();
        _isLoadingEquipped = false;
      });
    }
  }

  void _showEditNicknameDialog(BuildContext context, String currentNickname) {
    final TextEditingController controller =
        TextEditingController(text: currentNickname);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('닉네임 변경'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '닉네임',
            hintText: '새 닉네임을 입력하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.person_outline),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentNickname) {
                context.read<ProfileBloc>().add(UpdateDisplayName(newName));
              }
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ProfileBloc>().add(LogoutButtonPressed());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileInitial || state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProfileLoadFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    '프로필을 불러올 수 없습니다',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<ProfileBloc>().add(FetchProfileData());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          if (state is ProfileLoadSuccess) {
            final user = state.user;
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProfileBloc>().add(FetchProfileData());
                await _loadEquippedItems();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 커스텀 앱바 with 캐릭터
                  _buildSliverAppBar(context, user),

                  // 콘텐츠
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // 재화 섹션
                        _buildResourcesSection(context),

                        const SizedBox(height: 20),

                        // 빠른 액션 버튼
                        _buildQuickActions(context),

                        const SizedBox(height: 20),

                        // 메뉴 섹션
                        _buildMenuSection(context, user),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('알 수 없는 오류가 발생했습니다.'));
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, dynamic user) {
    final equipped = _equippedItems ?? const EquippedItemsEntity();
    final headItem = equipped.headItemId != null
        ? ItemRecipes.getItemById(equipped.headItemId!)
        : null;
    final bodyItem = equipped.bodyItemId != null
        ? ItemRecipes.getItemById(equipped.bodyItemId!)
        : null;
    final legsItem = equipped.legsItemId != null
        ? ItemRecipes.getItemById(equipped.legsItemId!)
        : null;

    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.brown[400],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green[300]!,
                Colors.brown[300]!,
                Colors.brown[400]!,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // 캐릭터 뷰
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CharacterPage(),
                      ),
                    );
                    _loadEquippedItems();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // 캐릭터 이모지
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            const Text(
                              '🧍',
                              style: TextStyle(fontSize: 70),
                            ),
                            if (headItem != null)
                              Positioned(
                                top: 0,
                                child: Text(
                                  headItem.iconEmoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                          ],
                        ),
                        // 장착 아이템 배지
                        if (equipped.equippedCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              children: [
                                if (headItem != null)
                                  _buildMiniItemBadge(headItem),
                                if (bodyItem != null)
                                  _buildMiniItemBadge(bodyItem),
                                if (legsItem != null)
                                  _buildMiniItemBadge(legsItem),
                              ],
                            ),
                          )
                        else if (!_isLoadingEquipped)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '탭하여 의상 장착하기',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 닉네임
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.nickname,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showEditNicknameDialog(context, user.nickname),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () {
            // TODO: 설정 페이지
          },
        ),
      ],
    );
  }

  Widget _buildMiniItemBadge(ItemEntity item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.iconEmoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            item.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(item.rarityColorValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.handyman,
              label: '제작소',
              color: Colors.brown,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CraftPage()),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.checkroom,
              label: '내 캐릭터',
              color: Colors.amber[700]!,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CharacterPage()),
                );
                _loadEquippedItems();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.inventory_2_outlined,
              label: '인벤토리',
              color: Colors.teal,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CharacterPage()),
                );
                _loadEquippedItems();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourcesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BlocBuilder<WoodBloc, WoodState>(
        builder: (context, state) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 통나무
                Expanded(
                  child: _buildResourceItem(
                    emoji: '🪵',
                    name: '통나무',
                    amount: state.totalWood,
                    color: const Color(0xFF8B4513),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettlementHistoryPage(),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey[200],
                ),
                // 철 (준비 중)
                Expanded(
                  child: _buildResourceItem(
                    emoji: '🔩',
                    name: '철',
                    amount: 0,
                    color: const Color(0xFF607D8B),
                    comingSoon: true,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey[200],
                ),
                // 돌 (준비 중)
                Expanded(
                  child: _buildResourceItem(
                    emoji: '🪨',
                    name: '돌',
                    amount: 0,
                    color: const Color(0xFF78909C),
                    comingSoon: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResourceItem({
    required String emoji,
    required String name,
    required int amount,
    required Color color,
    bool comingSoon = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: comingSoon ? null : onTap,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            comingSoon ? '-' : _formatNumber(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: comingSoon ? Colors.grey[400] : color,
            ),
          ),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (comingSoon)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '준비중',
                style: TextStyle(fontSize: 8, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.history,
              iconColor: Colors.purple,
              title: '정산 내역',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettlementHistoryPage(),
                  ),
                );
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _buildMenuItem(
              icon: Icons.notifications_outlined,
              iconColor: Colors.blue,
              title: '알림 설정',
              onTap: () {
                // TODO: 알림 설정
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _buildMenuItem(
              icon: Icons.help_outline,
              iconColor: Colors.teal,
              title: '도움말',
              onTap: () {
                // TODO: 도움말
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _buildMenuItem(
              icon: Icons.logout,
              iconColor: Colors.red,
              title: '로그아웃',
              titleColor: Colors.red,
              showArrow: false,
              onTap: () => _showLogoutConfirmDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? Colors.grey[800],
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
