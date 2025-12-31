import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_event.dart';
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

/// 제작소 페이지
class CraftPage extends StatefulWidget {
  const CraftPage({super.key});

  @override
  State<CraftPage> createState() => _CraftPageState();
}

class _CraftPageState extends State<CraftPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  /// 현재 선택된 재화 타입 (false: 통나무, true: 쇠)
  bool _showIronItems = false;

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
            // 재화 보유량 표시
            BlocBuilder<WoodBloc, WoodState>(
              builder: (context, woodState) {
                final authState = context.read<AuthBloc>().state;
                final ironAmount = authState is Authenticated 
                    ? authState.user.ironAmount 
                    : 0;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 통나무 표시
                      _buildCurrencyChip(
                        emoji: '🪵',
                        amount: woodState.summary?.totalWood ?? 0,
                        isSelected: !_showIronItems,
                        onTap: () => setState(() => _showIronItems = false),
                      ),
                      const SizedBox(width: 8),
                      // 쇠 표시
                      _buildCurrencyChip(
                        emoji: '🔩',
                        amount: ironAmount,
                        isSelected: _showIronItems,
                        onTap: () => setState(() => _showIronItems = true),
                      ),
                    ],
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

  /// 재화 선택 칩
  Widget _buildCurrencyChip({
    required String emoji,
    required int amount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              '$amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotTab(ClothingSlot slot, CraftState state) {
    // 현재 선택된 재화 타입에 따라 아이템 필터링
    final allSlotItems = ItemRecipes.getItemsBySlot(slot);
    final items = allSlotItems.where((item) => 
        _showIronItems ? item.isIronItem : item.isWoodItem
    ).toList();

    return BlocBuilder<WoodBloc, WoodState>(
      builder: (context, woodState) {
        final currentWood = woodState.summary?.totalWood ?? 0;
        final authState = context.read<AuthBloc>().state;
        final currentIron = authState is Authenticated 
            ? authState.user.ironAmount 
            : 0;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _showIronItems ? '🔩' : '🪵',
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  _showIronItems 
                      ? '쇠 ${slot.displayName} 아이템이 없습니다'
                      : '통나무 ${slot.displayName} 아이템이 없습니다',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

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
                currentIron: currentIron,
                ownedQuantity: quantity,
                isEquipped: isEquipped,
                currentEquipped: state.equippedItems,
                onTap: () => _showItemDetail(context, item, state, currentWood, currentIron),
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
    int currentIron,
  ) {
    final quantity = state.getItemQuantity(item.id);
    final isEquipped = state.isItemEquipped(item.id);
    final canCraft = item.canCraft(currentWood: currentWood, currentIron: currentIron);
    
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
                _buildInfoItem(item.currencyEmoji, '제작 비용', '${item.cost}개'),
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
                      backgroundColor: item.isIronItem 
                          ? Colors.blueGrey[600]
                          : Colors.brown[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      canCraft
                          ? '${item.currencyEmoji} ${item.cost}개로 제작하기'
                          : _buildInsufficientText(item, currentWood, currentIron),
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
  
  String _buildInsufficientText(ItemEntity item, int currentWood, int currentIron) {
    if (item.isIronItem) {
      return '쇠 부족 ($currentIron/${item.ironCost})';
    } else {
      return '통나무 부족 ($currentWood/${item.woodCost})';
    }
  }

  void _craftItem(String itemId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<CraftBloc>().add(
            CraftItemEvent(userId: authState.user.id, itemId: itemId),
          );
      // 재화 상태 새로고침
      context.read<WoodBloc>().add(const LoadWoodSummary());
      // AuthBloc 새로고침 (쇠 정보용)
      context.read<AuthBloc>().add(AuthRefreshUserRequested());
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

