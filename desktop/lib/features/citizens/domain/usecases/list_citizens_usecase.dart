import '../../../../core/error/result.dart';
import '../entities/paginated_citizens.dart';
import '../repositories/citizens_repository.dart';

class ListCitizensUseCase {
  const ListCitizensUseCase(this._repo);
  final CitizensRepository _repo;

  Future<Result<PaginatedCitizens>> call({required int page, String? search}) {
    return _repo.list(page: page, search: search);
  }
}
