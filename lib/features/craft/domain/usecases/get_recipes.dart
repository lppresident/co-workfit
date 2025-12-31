import '../entities/item_entity.dart';
import '../repositories/craft_repository.dart';

/// 아이템 레시피 조회 UseCase
class GetRecipes {
  final CraftRepository repository;

  GetRecipes(this.repository);

  /// 모든 레시피 조회
  Future<List<ItemEntity>> call() async {
    return repository.getAllRecipes();
  }

  /// ID로 아이템 조회
  Future<ItemEntity?> getById(String itemId) async {
    return repository.getItemById(itemId);
  }
}

