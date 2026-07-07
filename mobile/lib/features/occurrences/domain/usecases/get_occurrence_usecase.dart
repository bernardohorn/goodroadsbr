import '../../../../core/error/result.dart';
import '../entities/occurrence.dart';
import '../repositories/occurrences_repository.dart';

class GetOccurrenceUseCase {
  const GetOccurrenceUseCase(this._repository);
  final OccurrencesRepository _repository;

  Future<Result<Occurrence>> call(String id) => _repository.getById(id);
}
