import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../repositories/categories_repository.dart';

class ListCategoriesUseCase {
  const ListCategoriesUseCase(this._repo);
  final CategoriesRepository _repo;

  Future<Result<List<Category>>> call() => _repo.list();
}
