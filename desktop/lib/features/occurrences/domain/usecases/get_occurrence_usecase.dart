import '../../../../core/error/result.dart';
import '../entities/staff_occurrence.dart';
import '../repositories/occurrences_repository.dart';

class GetOccurrenceUseCase {
  const GetOccurrenceUseCase(this._repo);
  final OccurrencesRepository _repo;

  Future<Result<StaffOccurrence>> call(String id) => _repo.getById(id);
}
