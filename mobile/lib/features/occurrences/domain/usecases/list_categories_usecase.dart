import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../repositories/occurrences_repository.dart';

class ListCategoriesUseCase {
  const ListCategoriesUseCase(this._repository);
  final OccurrencesRepository _repository;

  Future<Result<List<Category>>> call() => _repository.listCategories();
}
