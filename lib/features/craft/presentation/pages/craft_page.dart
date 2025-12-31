import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/wood/wood.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/item_recipes.dart';
import '../bloc/craft_bloc.dart';
import '../bloc/craft_event.dart';
import '../bloc/craft_state.dart';
import '../widgets/character_widget.dart';
import '../widgets/item_card_widget.dart';
import '../widgets/wood_display_widget.dart';

/// 제작소 페이지
class CraftPage extends StatefulWidget {
  const CraftPage({super.key});

  @override
  State<CraftPage> createState() => _CraftPageState();
}

class _CraftPageState extends State<CraftPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<CraftBloc>().add(const LoadRecipes());
      context.read<CraftBloc>().add(LoadInventory(authState.user.id));
      context.read<CraftBloc>().add(LoadEquippedItems(authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CraftBloc, CraftState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🛠️ 제작소'),
          actions: [
            // 통나무 보유량 표시
            BlocBuilder<WoodBloc, WoodState>(
              builder: (context, woodState) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: WoodDisplayWidget(
                    amount: woodState.summary?.totalWood ?? 0,
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '🧢 머리'),
              Tab(text: '👕 상체'),
              Tab(text: '👖 하체'),
            ],
          ),
        ),
        body: BlocBuilder<CraftBloc, CraftState>(
          builder: (context, state) {
            if (state.isLoading && state.recipes.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildSlotTab(ClothingSlot.head, state),
                _buildSlotTab(ClothingSlot.body, state),
                _buildSlotTab(ClothingSlot.legs, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSlotTab(ClothingSlot slot, CraftState state) {
    final items = ItemRecipes.getItemsBySlot(slot);

    return BlocBuilder<WoodBloc, WoodState>(
      builder: (context, woodState) {
        final currentWood = woodState.summary?.totalWood ?? 0;

        return RefreshIndicator(
          onRefresh: () async {
            _loadData();
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final quantity = state.getItemQuantity(item.id);
              final isEquipped = state.isItemEquipped(item.id);

              return ItemCardWidget(
                item: item,
                currentWood: currentWood,
                ownedQuantity: quantity,
                isEquipped: isEquipped,
                currentEquipped: state.equippedItems,
                onTap: () => _showItemDetail(context, item, state, currentWood),
                onCraft: () => _craftItem(item.id),
                onEquip: quantity > 0 && !isEquipped
                    ? () => _equipItem(item.id)
                    : null,
                onUnequip: isEquipped ? () => _unequipItem(item.id) : null,
              );
            },
          ),
        );
      },
    );
  }

  void _showItemDetail(
    BuildContext context,
    ItemEntity item,
    CraftState state,
    int currentWood,
  ) {
    final quantity = state.getItemQuantity(item.id);
    final isEquipped = state.isItemEquipped(item.id);
    final canCraft = currentWood >= item.woodCost;
    
    // 미리보기용 장착 상태
    var previewEquipped = state.equippedItems;
    if (item.clothingSlot != null) {
      previewEquipped = previewEquipped.equip(item.clothingSlot!, item.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 캐릭터 미리보기
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green[50]!,
                    Colors.brown[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.brown[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 현재 모습
                      Column(
                        children: [
                          Text(
                            '현재',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          CharacterWidget(
                            size: 100,
                            equippedItems: state.equippedItems,
                            backgroundColor: Colors.white.withValues(alpha: 0.5),
                            borderColor: Colors.grey[400]!,
                            showShadow: false,
                          ),
                        ],
                      ),
                      // 화살표
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.brown[400],
                        size: 32,
                      ),
                      // 장착 후 모습
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '미리보기',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CharacterWidget(
                            size: 100,
                            equippedItems: previewEquipped,
                            backgroundColor: Colors.white.withValues(alpha: 0.8),
                            borderColor: Colors.amber,
                            borderWidth: 2,
                            showShadow: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 아이템 정보
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(item.themeColorValue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(item.themeColorValue).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.iconEmoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.clothingSlot?.displayName ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEquipped)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '장착 중',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // 설명
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem('🪵', '제작 비용', '${item.woodCost}개'),
                _buildInfoItem('📦', '보유량', '$quantity개'),
                _buildInfoItem('⏱️', '획득 예상', '~${item.estimatedDays}일'),
              ],
            ),

            const SizedBox(height: 20),

            // 액션 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: canCraft
                        ? () {
                            Navigator.pop(context);
                            _craftItem(item.id);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      canCraft
                          ? '🪵 ${item.woodCost}개로 제작하기'
                          : '통나무 부족 ($currentWood/${item.woodCost})',
                    ),
                  ),
                ),
                if (quantity > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: isEquipped
                        ? OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _unequipItem(item.id);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('해제하기'),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _equipItem(item.id);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('장착하기'),
                          ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _craftItem(String itemId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<CraftBloc>().add(
            CraftItemEvent(userId: authState.user.id, itemId: itemId),
          );
      // Wood 상태도 새로고침
      context.read<WoodBloc>().add(const LoadWoodSummary());
    }
  }

  void _equipItem(String itemId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<CraftBloc>().add(
            EquipItemEvent(userId: authState.user.id, itemId: itemId),
          );
    }
  }

  void _unequipItem(String itemId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<CraftBloc>().add(
            UnequipItemEvent(userId: authState.user.id, itemId: itemId),
          );
    }
  }
}

