import '../../../../core/error/result.dart';
import '../entities/occurrence_filters.dart';
import '../entities/occurrence_status_history_entry.dart';
import '../entities/paginated_occurrences.dart';
import '../entities/staff_occurrence.dart';

abstract class OccurrencesRepository {
  Future<Result<PaginatedOccurrences>> list({required int page, required OccurrenceFilters filters});
  Future<Result<StaffOccurrence>> getById(String id);
  Future<Result<List<OccurrenceStatusHistoryEntry>>> getHistory(String id);
  Future<Result<StaffOccurrence>> updateStatus({required String id, required String status, String? note});
  Future<Result<StaffOccurrence>> updateDetails({
    required String id,
    String? categoryId,
    String? priority,
    String? teamId,
    String? assignedToId,
    String? internalNotes,
  });
}
