import '../../../../core/error/result.dart';
import '../entities/occurrence_filters.dart';
import '../entities/paginated_occurrences.dart';
import '../repositories/occurrences_repository.dart';

class ListOccurrencesUseCase {
  const ListOccurrencesUseCase(this._repo);
  final OccurrencesRepository _repo;

  Future<Result<PaginatedOccurrences>> call({required int page, required OccurrenceFilters filters}) {
    return _repo.list(page: page, filters: filters);
  }
}
