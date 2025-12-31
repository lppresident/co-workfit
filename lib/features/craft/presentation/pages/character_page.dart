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
import 'inventory_page.dart';

/// 캐릭터 페이지
class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<CraftBloc>().add(LoadEquippedItems(authState.user.id));
      context.read<CraftBloc>().add(LoadInventory(authState.user.id));
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
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🧑 내 캐릭터'),
          actions: [
            IconButton(
              icon: const Icon(Icons.backpack_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryPage()),
                );
              },
              tooltip: '인벤토리',
            ),
          ],
        ),
        body: BlocBuilder<CraftBloc, CraftState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 캐릭터 뷰
                    _buildCharacterView(state),

                    const SizedBox(height: 24),

                    // 장착 슬롯
                    _buildEquipmentSlots(state),

                    const SizedBox(height: 24),

                    // 인벤토리 버튼
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InventoryPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.backpack_outlined),
                        label: const Text('인벤토리 열기'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCharacterView(CraftState state) {
    final equipped = state.equippedItems;

    // 장착된 아이템 정보 가져오기
    final headItem = equipped.headItemId != null
        ? ItemRecipes.getItemById(equipped.headItemId!)
        : null;
    final bodyItem = equipped.bodyItemId != null
        ? ItemRecipes.getItemById(equipped.bodyItemId!)
        : null;
    final legsItem = equipped.legsItemId != null
        ? ItemRecipes.getItemById(equipped.legsItemId!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
          // 도트 스타일 캐릭터
          CharacterWidget(
            size: 180,
            equippedItems: equipped,
            backgroundColor: Colors.white.withValues(alpha: 0.5),
            borderColor: Colors.brown[400]!,
            showShadow: true,
          ),

          const SizedBox(height: 16),

          // 장착 아이템 뱃지 표시
          if (equipped.equippedCount > 0) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (headItem != null) _buildEquippedBadge(headItem),
                if (bodyItem != null) _buildEquippedBadge(bodyItem),
                if (legsItem != null) _buildEquippedBadge(legsItem),
              ],
            ),
          ] else ...[
            Text(
              '장착된 아이템이 없습니다',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEquippedBadge(ItemEntity item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(item.rarityColorValue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(item.rarityColorValue)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.iconEmoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            item.name,
            style: TextStyle(
              fontSize: 12,
              color: Color(item.rarityColorValue),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSlots(CraftState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '장착 슬롯',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSlotRow(ClothingSlot.head, state),
        const SizedBox(height: 8),
        _buildSlotRow(ClothingSlot.body, state),
        const SizedBox(height: 8),
        _buildSlotRow(ClothingSlot.legs, state),
      ],
    );
  }

  Widget _buildSlotRow(ClothingSlot slot, CraftState state) {
    final equippedItemId = state.equippedItems.getEquippedItemId(slot);
    final item = equippedItemId != null
        ? ItemRecipes.getItemById(equippedItemId)
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item != null
            ? Color(item.rarityColorValue).withValues(alpha: 0.05)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item != null
              ? Color(item.rarityColorValue).withValues(alpha: 0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          // 슬롯 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                slot.emoji,
                style: const TextStyle(fontSize: 20),
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
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '비어있음',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          // 해제 버튼
          if (item != null)
            TextButton(
              onPressed: () => _unequipItem(equippedItemId!),
              child: const Text('해제'),
            ),
        ],
      ),
    );
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

