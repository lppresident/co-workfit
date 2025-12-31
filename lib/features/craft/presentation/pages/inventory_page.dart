import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/item_recipes.dart';
import '../bloc/craft_bloc.dart';
import '../bloc/craft_event.dart';
import '../bloc/craft_state.dart';
import '../widgets/character_widget.dart';

/// 인벤토리 페이지
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
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
        ),
        body: BlocBuilder<CraftBloc, CraftState>(
          builder: (context, state) {
            if (state.isLoading && state.inventory.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.inventory.isEmpty) {
              return _buildEmptyInventory();
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadData();
              },
              child: CustomScrollView(
                slivers: [
                  // 현재 캐릭터 모습
                  SliverToBoxAdapter(
                    child: _buildCurrentCharacter(state),
                  ),
                  // 인벤토리 목록
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final inventoryItem = state.inventory[index];
                          final item = ItemRecipes.getItemById(inventoryItem.itemId);

                          if (item == null) return const SizedBox.shrink();

                          final isEquipped = state.isItemEquipped(item.id);

                          return _buildInventoryItem(
                            item, 
                            inventoryItem.quantity, 
                            isEquipped,
                            state,
                          );
                        },
                        childCount: state.inventory.length,
                      ),
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

  Widget _buildCurrentCharacter(CraftState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          Text(
            '현재 모습',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.brown[700],
            ),
          ),
          const SizedBox(height: 12),
          CharacterWidget(
            size: 120,
            equippedItems: state.equippedItems,
            backgroundColor: Colors.white.withValues(alpha: 0.6),
            borderColor: Colors.brown[400]!,
            showShadow: true,
          ),
          const SizedBox(height: 12),
          Text(
            '보유 아이템: ${state.inventory.length}종',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CharacterWidget(
            size: 120,
            equippedItems: null,
            backgroundColor: Colors.grey[100],
            borderColor: Colors.grey[300]!,
            showShadow: false,
          ),
          const SizedBox(height: 24),
          Text(
            '인벤토리가 비어있습니다',
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
        ],
      ),
    );
  }

  Widget _buildInventoryItem(
    ItemEntity item, 
    int quantity, 
    bool isEquipped,
    CraftState state,
  ) {
    // 미리보기용 장착 상태
    var previewEquipped = state.equippedItems;
    if (item.clothingSlot != null) {
      previewEquipped = previewEquipped.equip(item.clothingSlot!, item.id);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isEquipped ? Colors.amber : Colors.transparent,
          width: isEquipped ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => _showItemDetail(item, quantity, isEquipped, state),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 캐릭터 미리보기
              CharacterWidget(
                size: 64,
                equippedItems: previewEquipped,
                backgroundColor: Colors.grey[50],
                borderColor: isEquipped 
                    ? Colors.amber 
                    : Color(item.themeColorValue).withValues(alpha: 0.5),
                borderWidth: 1.5,
                showShadow: false,
              ),
              const SizedBox(width: 12),
              // 아이템 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.iconEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          'x$quantity',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          item.clothingSlot?.displayName ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (isEquipped) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, 
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '장착 중',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 장착/해제 버튼
              SizedBox(
                width: 64,
                height: 36,
                child: isEquipped
                    ? OutlinedButton(
                        onPressed: () => _unequipItem(item.id),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('해제', style: TextStyle(fontSize: 12)),
                      )
                    : ElevatedButton(
                        onPressed: () => _equipItem(item.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('장착', style: TextStyle(fontSize: 12)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetail(
    ItemEntity item,
    int quantity,
    bool isEquipped,
    CraftState state,
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
