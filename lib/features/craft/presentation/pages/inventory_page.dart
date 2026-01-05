import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/features/currency/currency.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/item_recipes.dart';
import '../bloc/craft_bloc.dart';
import '../bloc/craft_event.dart';
import '../bloc/craft_state.dart';
import '../widgets/character_widget.dart';
import '../widgets/item_card_widget.dart';

/// 인벤토리 페이지
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// 현재 선택된 재화 필터 (null = 전체)
  ItemCurrencyType? _selectedCurrencyFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
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
          title: const Text('🎒 인벤토리'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                // 재화 필터 칩
                _buildCurrencyFilterRow(context),
                const SizedBox(height: 8),
                // 슬롯 탭
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '전체'),
                    Tab(text: '🧢 머리'),
                    Tab(text: '👕 상체'),
                    Tab(text: '👖 하체'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: BlocBuilder<CraftBloc, CraftState>(
          builder: (context, state) {
            if (state.isLoading && state.inventory.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildItemGrid(null, state), // 전체
                _buildItemGrid(ClothingSlot.head, state),
                _buildItemGrid(ClothingSlot.body, state),
                _buildItemGrid(ClothingSlot.legs, state),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 재화 필터 칩 Row
  Widget _buildCurrencyFilterRow(BuildContext context) {
    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, currencyState) {
        final woodAmount = currencyState is CurrencyLoaded
            ? currencyState.getAmount(CurrencyType.wood)
            : 0;
        final ironAmount = currencyState is CurrencyLoaded
            ? currencyState.getAmount(CurrencyType.iron)
            : 0;
        final soilAmount = currencyState is CurrencyLoaded
            ? currencyState.getAmount(CurrencyType.soil)
            : 0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 전체 필터
              _buildFilterChip(
                label: '전체',
                emoji: '📦',
                isSelected: _selectedCurrencyFilter == null,
                onTap: () => setState(() => _selectedCurrencyFilter = null),
              ),
              const SizedBox(width: 8),
              // 통나무 필터
              _buildFilterChip(
                label: '통나무',
                emoji: '🪵',
                amount: woodAmount,
                isSelected: _selectedCurrencyFilter == ItemCurrencyType.wood,
                color: const Color(0xFF8B4513),
                onTap: () => setState(() => _selectedCurrencyFilter = ItemCurrencyType.wood),
              ),
              const SizedBox(width: 8),
              // 쇠 필터
              _buildFilterChip(
                label: '쇠',
                emoji: '🔩',
                amount: ironAmount,
                isSelected: _selectedCurrencyFilter == ItemCurrencyType.iron,
                color: const Color(0xFF708090),
                onTap: () => setState(() => _selectedCurrencyFilter = ItemCurrencyType.iron),
              ),
              const SizedBox(width: 8),
              // 흙 필터
              _buildFilterChip(
                label: '흙',
                emoji: '🪨',
                amount: soilAmount,
                isSelected: _selectedCurrencyFilter == ItemCurrencyType.soil,
                color: const Color(0xFF6B4423),
                onTap: () => setState(() => _selectedCurrencyFilter = ItemCurrencyType.soil),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 필터 칩 위젯
  Widget _buildFilterChip({
    required String label,
    required String emoji,
    int? amount,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? chipColor : Colors.grey[700],
                fontSize: 13,
              ),
            ),
            if (amount != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$amount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? chipColor : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 아이템 그리드 (인벤토리 아이템만 표시)
  Widget _buildItemGrid(ClothingSlot? slot, CraftState state) {
    // 인벤토리에서 보유 중인 아이템만 가져오기
    List<ItemEntity> ownedItems = [];
    for (var inventoryItem in state.inventory) {
      final item = ItemRecipes.getItemById(inventoryItem.itemId);
      if (item != null) {
        ownedItems.add(item);
      }
    }

    // 슬롯 필터
    if (slot != null) {
      ownedItems = ownedItems.where((item) => item.clothingSlot == slot).toList();
    }

    // 재화 필터
    if (_selectedCurrencyFilter != null) {
      ownedItems = ownedItems.where((item) => item.currencyType == _selectedCurrencyFilter).toList();
    }

    // 가격순 정렬
    ownedItems.sort((a, b) => a.cost.compareTo(b.cost));

    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, currencyState) {
        final currentWood = currencyState is CurrencyLoaded
            ? currencyState.getAmount(CurrencyType.wood)
            : 0;
        final currentIron = currencyState is CurrencyLoaded
            ? currencyState.getAmount(CurrencyType.iron)
            : 0;
        final currentSoil = currencyState is CurrencyLoaded
            ? currencyState.getAmount(CurrencyType.soil)
            : 0;

        if (ownedItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getEmptyEmoji(),
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  '보유 중인 아이템이 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '제작소에서 아이템을 만들어보세요!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedCurrencyFilter != null || slot != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCurrencyFilter = null;
                      });
                    },
                    child: const Text('필터 초기화'),
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
            itemCount: ownedItems.length,
            itemBuilder: (context, index) {
              final item = ownedItems[index];
              final quantity = state.getItemQuantity(item.id);
              final isEquipped = state.isItemEquipped(item.id);

              return ItemCardWidget(
                item: item,
                currentWood: currentWood,
                currentIron: currentIron,
                currentSoil: currentSoil,
                ownedQuantity: quantity,
                isEquipped: isEquipped,
                currentEquipped: state.equippedItems,
                onTap: () => _showItemDetail(item, quantity, isEquipped, state, currentWood, currentIron, currentSoil),
                onCraft: null, // 인벤토리에서는 제작 불가
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

  String _getEmptyEmoji() {
    switch (_selectedCurrencyFilter) {
      case ItemCurrencyType.wood:
        return '🪵';
      case ItemCurrencyType.iron:
        return '🔩';
      case ItemCurrencyType.soil:
        return '🪨';
      case null:
        return '🎒';
    }
  }

  void _showItemDetail(
    ItemEntity item,
    int quantity,
    bool isEquipped,
    CraftState state,
    int currentWood,
    int currentIron,
    int currentSoil,
  ) {
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
          children: [
            // 캐릭터 비교
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
              child: Row(
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
                      Row(
                        children: [
                          Text(
                            item.clothingSlot?.displayName ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '보유: $quantity개',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
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
            SizedBox(
              width: double.infinity,
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
