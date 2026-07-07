import '../../../../core/error/result.dart';
import '../entities/paginated_occurrences.dart';
import '../repositories/occurrences_repository.dart';

class ListMyOccurrencesUseCase {
  const ListMyOccurrencesUseCase(this._repository);
  final OccurrencesRepository _repository;

  Future<Result<PaginatedOccurrences>> call({int page = 1, String? status}) {
    return _repository.listMine(page: page, status: status);
  }
}
