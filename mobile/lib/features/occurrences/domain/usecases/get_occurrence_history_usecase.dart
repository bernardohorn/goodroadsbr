import '../../../../core/error/result.dart';
import '../entities/occurrence_status_history_entry.dart';
import '../repositories/occurrences_repository.dart';

class GetOccurrenceHistoryUseCase {
  const GetOccurrenceHistoryUseCase(this._repository);
  final OccurrencesRepository _repository;

  Future<Result<List<OccurrenceStatusHistoryEntry>>> call(String id) => _repository.getHistory(id);
}
