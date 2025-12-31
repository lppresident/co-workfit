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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.inventory.length,
                itemBuilder: (context, index) {
                  final inventoryItem = state.inventory[index];
                  final item = ItemRecipes.getItemById(inventoryItem.itemId);

                  if (item == null) return const SizedBox.shrink();

                  final isEquipped = state.isItemEquipped(item.id);

                  return _buildInventoryItem(item, inventoryItem.quantity, isEquipped);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🎒',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            '인벤토리가 비어있습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
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

  Widget _buildInventoryItem(ItemEntity item, int quantity, bool isEquipped) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEquipped ? Colors.amber : Colors.transparent,
          width: isEquipped ? 2 : 0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(item.rarityColorValue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              item.iconEmoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              'x$quantity',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Color(item.rarityColorValue),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.rarityName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        trailing: isEquipped
            ? TextButton(
                onPressed: () => _unequipItem(item.id),
                child: const Text('해제'),
              )
            : ElevatedButton(
                onPressed: () => _equipItem(item.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                ),
                child: const Text('장착'),
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

