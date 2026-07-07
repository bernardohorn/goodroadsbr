import '../../../../core/error/result.dart';
import '../entities/occurrence_status_history_entry.dart';
import '../repositories/occurrences_repository.dart';

class GetOccurrenceHistoryUseCase {
  const GetOccurrenceHistoryUseCase(this._repo);
  final OccurrencesRepository _repo;

  Future<Result<List<OccurrenceStatusHistoryEntry>>> call(String id) => _repo.getHistory(id);
}
