import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/utils/logger.dart';
import '../../domain/repositories/craft_repository.dart';
import '../../domain/usecases/craft_item.dart';
import '../../domain/usecases/equip_item.dart';
import '../../domain/usecases/get_equipped_items.dart';
import '../../domain/usecases/get_inventory.dart';
import '../../domain/usecases/get_recipes.dart';
import '../../domain/usecases/unequip_item.dart';
import 'craft_event.dart';
import 'craft_state.dart';

/// 제작 시스템 BLoC
class CraftBloc extends Bloc<CraftEvent, CraftState> {
  final GetRecipes getRecipes;
  final GetInventory getInventory;
  final GetEquippedItems getEquippedItems;
  final CraftItem craftItem;
  final EquipItem equipItem;
  final UnequipItem unequipItem;
  final CraftRepository repository;

  CraftBloc({
    required this.getRecipes,
    required this.getInventory,
    required this.getEquippedItems,
    required this.craftItem,
    required this.equipItem,
    required this.unequipItem,
    required this.repository,
  }) : super(CraftState.initial()) {
    on<LoadRecipes>(_onLoadRecipes);
    on<LoadInventory>(_onLoadInventory);
    on<LoadEquippedItems>(_onLoadEquippedItems);
    on<CraftItemEvent>(_onCraftItem);
    on<EquipItemEvent>(_onEquipItem);
    on<UnequipItemEvent>(_onUnequipItem);
    on<RefreshCraftData>(_onRefreshCraftData);
  }

  /// 레시피 로드
  Future<void> _onLoadRecipes(
    LoadRecipes event,
    Emitter<CraftState> emit,
  ) async {
    try {
      emit(state.loading());
      final recipes = await getRecipes();
      emit(state.copyWith(
        isLoading: false,
        recipes: recipes,
      ));
    } catch (e) {
      AppLogger.error('CraftBloc', '레시피 로드 실패', e);
      emit(state.error('레시피를 불러오는데 실패했습니다'));
    }
  }

  /// 인벤토리 로드
  Future<void> _onLoadInventory(
    LoadInventory event,
    Emitter<CraftState> emit,
  ) async {
    try {
      final inventory = await getInventory(event.userId);
      emit(state.copyWith(inventory: inventory));
    } catch (e) {
      AppLogger.error('CraftBloc', '인벤토리 로드 실패', e);
      emit(state.error('인벤토리를 불러오는데 실패했습니다'));
    }
  }

  /// 장착 아이템 로드
  Future<void> _onLoadEquippedItems(
    LoadEquippedItems event,
    Emitter<CraftState> emit,
  ) async {
    try {
      final equipped = await getEquippedItems(event.userId);
      emit(state.copyWith(equippedItems: equipped));
    } catch (e) {
      AppLogger.error('CraftBloc', '장착 아이템 로드 실패', e);
      emit(state.error('장착 아이템을 불러오는데 실패했습니다'));
    }
  }

  /// 아이템 제작
  Future<void> _onCraftItem(
    CraftItemEvent event,
    Emitter<CraftState> emit,
  ) async {
    try {
      emit(state.loading());

      final result = await craftItem(event.userId, event.itemId);

      if (result.success && result.craftedItem != null) {
        // 인벤토리 새로고침
        final inventory = await getInventory(event.userId);

        emit(state.copyWith(
          isLoading: false,
          inventory: inventory,
          successMessage: '${result.craftedItem!.name}을(를) 만들었습니다!',
        ));

        AppLogger.info(
          'CraftBloc',
          '아이템 제작 성공: ${result.craftedItem!.name}',
        );
      } else {
        emit(state.error(result.errorMessage ?? '제작에 실패했습니다'));
      }
    } catch (e) {
      AppLogger.error('CraftBloc', '아이템 제작 실패', e);
      emit(state.error('제작 중 오류가 발생했습니다'));
    }
  }

  /// 아이템 장착
  Future<void> _onEquipItem(
    EquipItemEvent event,
    Emitter<CraftState> emit,
  ) async {
    try {
      emit(state.loading());

      final result = await equipItem(event.userId, event.itemId);

      if (result.success) {
        // 장착 상태 새로고침
        final equipped = await getEquippedItems(event.userId);

        String message = '아이템을 장착했습니다';
        if (result.previousItemId != null) {
          message = '아이템을 교체했습니다';
        }

        emit(state.copyWith(
          isLoading: false,
          equippedItems: equipped,
          successMessage: message,
        ));

        AppLogger.info('CraftBloc', '아이템 장착 성공: ${event.itemId}');
      } else {
        emit(state.error(result.errorMessage ?? '장착에 실패했습니다'));
      }
    } catch (e) {
      AppLogger.error('CraftBloc', '아이템 장착 실패', e);
      emit(state.error('장착 중 오류가 발생했습니다'));
    }
  }

  /// 아이템 해제
  Future<void> _onUnequipItem(
    UnequipItemEvent event,
    Emitter<CraftState> emit,
  ) async {
    try {
      emit(state.loading());

      final result = await unequipItem(event.userId, event.itemId);

      if (result.success) {
        // 장착 상태 새로고침
        final equipped = await getEquippedItems(event.userId);

        emit(state.copyWith(
          isLoading: false,
          equippedItems: equipped,
          successMessage: '아이템을 해제했습니다',
        ));

        AppLogger.info('CraftBloc', '아이템 해제 성공: ${event.itemId}');
      } else {
        emit(state.error(result.errorMessage ?? '해제에 실패했습니다'));
      }
    } catch (e) {
      AppLogger.error('CraftBloc', '아이템 해제 실패', e);
      emit(state.error('해제 중 오류가 발생했습니다'));
    }
  }

  /// 전체 데이터 새로고침
  Future<void> _onRefreshCraftData(
    RefreshCraftData event,
    Emitter<CraftState> emit,
  ) async {
    try {
      emit(state.loading());

      final recipes = await getRecipes();
      final inventory = await getInventory(event.userId);
      final equipped = await getEquippedItems(event.userId);

      emit(state.copyWith(
        isLoading: false,
        recipes: recipes,
        inventory: inventory,
        equippedItems: equipped,
      ));

      AppLogger.info('CraftBloc', '제작 데이터 새로고침 완료');
    } catch (e) {
      AppLogger.error('CraftBloc', '데이터 새로고침 실패', e);
      emit(state.error('데이터를 불러오는데 실패했습니다'));
    }
  }
}

