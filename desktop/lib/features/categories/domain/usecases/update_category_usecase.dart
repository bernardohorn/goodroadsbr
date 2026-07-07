import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../repositories/categories_repository.dart';

class UpdateCategoryUseCase {
  const UpdateCategoryUseCase(this._repo);
  final CategoriesRepository _repo;

  Future<Result<Category>> call({required String id, String? name, String? icon, String? color, bool? active}) {
    return _repo.update(id: id, name: name, icon: icon, color: color, active: active);
  }
}
