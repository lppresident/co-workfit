import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/craft/domain/entities/equipped_items_entity.dart';
import 'package:co_workfit/features/craft/presentation/pages/craft_page.dart';
import 'package:co_workfit/features/craft/presentation/pages/character_page.dart';
import 'package:co_workfit/features/craft/presentation/pages/inventory_page.dart';
import 'package:co_workfit/features/craft/presentation/widgets/character_widget.dart';
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
        });
      } else {
        setState(() {
          _equippedItems = const EquippedItemsEntity();
        });
      }
    } catch (e) {
      setState(() {
        _equippedItems = const EquippedItemsEntity();
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
                        const SizedBox(height: 20),

                        // 재화 섹션 (탭하면 정산 내역으로)
                        _buildResourcesSection(context),

                        const SizedBox(height: 20),

                        // 제작 & 꾸미기 섹션
                        _buildCraftSection(context),

                        const SizedBox(height: 20),

                        // 설정 메뉴
                        _buildSettingsSection(context),

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

    return SliverAppBar(
      expandedHeight: 260,
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
                // 캐릭터 뷰 (탭하면 캐릭터 페이지로)
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
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        // 도트 스타일 캐릭터
                        CharacterWidget(
                          size: 110,
                          equippedItems: equipped,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          borderColor: Colors.white,
                          borderWidth: 2,
                          showShadow: false,
                        ),
                        const SizedBox(height: 8),
                        // 힌트 텍스트
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              equipped.equippedCount > 0 ? '캐릭터 꾸미기' : '의상 장착하기',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildResourcesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettlementHistoryPage()),
          );
        },
        child: BlocBuilder<WoodBloc, WoodState>(
          builder: (context, state) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber[700]!,
                    Colors.brown[600]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 통나무 아이콘
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('🪵', style: TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(width: 16),
                      // 보유량
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '내 통나무',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatNumber(state.totalWood)} 개',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 화살표
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 누적 획득량
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '누적 획득: ${_formatNumber(state.lifetimeEarned)} 개',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '정산 내역 보기',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCraftSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 20, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text(
                    '제작 & 꾸미기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            // 제작소
            _buildCraftMenuItem(
              icon: Icons.handyman,
              iconColor: Colors.brown,
              title: '제작소',
              subtitle: '통나무로 아이템 제작',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CraftPage()),
                );
              },
            ),
            Divider(height: 1, indent: 72, color: Colors.grey[200]),
            // 인벤토리
            _buildCraftMenuItem(
              icon: Icons.inventory_2_outlined,
              iconColor: Colors.teal,
              title: '인벤토리',
              subtitle: '보유 아이템 확인 및 장착',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryPage()),
                );
                _loadEquippedItems();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCraftMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
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
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '설정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _buildSettingsMenuItem(
              icon: Icons.notifications_outlined,
              iconColor: Colors.blue,
              title: '알림 설정',
              onTap: () {
                // TODO: 알림 설정
              },
            ),
            Divider(height: 1, indent: 72, color: Colors.grey[200]),
            _buildSettingsMenuItem(
              icon: Icons.help_outline,
              iconColor: Colors.teal,
              title: '도움말',
              onTap: () {
                // TODO: 도움말
              },
            ),
            Divider(height: 1, indent: 72, color: Colors.grey[200]),
            _buildSettingsMenuItem(
              icon: Icons.info_outline,
              iconColor: Colors.grey,
              title: '앱 정보',
              onTap: () {
                _showAppInfoDialog(context);
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _buildSettingsMenuItem(
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

  Widget _buildSettingsMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? Colors.grey[800],
                ),
              ),
            ),
            if (showArrow)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('🏃', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('Co-Workfit'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('버전: 1.0.0', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              '함께 운동하고, 통나무를 모아 캐릭터를 꾸며보세요!',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
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
