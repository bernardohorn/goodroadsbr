import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../repositories/categories_repository.dart';

class CreateCategoryUseCase {
  const CreateCategoryUseCase(this._repo);
  final CategoriesRepository _repo;

  Future<Result<Category>> call({required String name, String? icon, String? color}) {
    return _repo.create(name: name, icon: icon, color: color);
  }
}
