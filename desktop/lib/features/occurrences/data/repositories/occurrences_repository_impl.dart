import '../../../../core/error/result.dart';
import '../../../../core/network/failure_mapper.dart';
import '../../domain/entities/occurrence_filters.dart';
import '../../domain/entities/occurrence_status_history_entry.dart';
import '../../domain/entities/paginated_occurrences.dart';
import '../../domain/entities/staff_occurrence.dart';
import '../../domain/repositories/occurrences_repository.dart';
import '../datasources/occurrences_remote_data_source.dart';

class OccurrencesRepositoryImpl implements OccurrencesRepository {
  const OccurrencesRepositoryImpl(this._remote);
  final OccurrencesRemoteDataSource _remote;

  @override
  Future<Result<PaginatedOccurrences>> list({required int page, required OccurrenceFilters filters}) async {
    try {
      final response = await _remote.list(page: page, filters: filters);
      return Result.success(
        PaginatedOccurrences(items: response.items, total: response.total, page: page, pageSize: 20),
      );
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<StaffOccurrence>> getById(String id) async {
    try {
      return Result.success(await _remote.getById(id));
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<List<OccurrenceStatusHistoryEntry>>> getHistory(String id) async {
    try {
      return Result.success(await _remote.getHistory(id));
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<StaffOccurrence>> updateStatus({required String id, required String status, String? note}) async {
    try {
      return Result.success(await _remote.updateStatus(id: id, status: status, note: note));
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<StaffOccurrence>> updateDetails({
    required String id,
    String? categoryId,
    String? priority,
    String? teamId,
    String? assignedToId,
    String? internalNotes,
  }) async {
    try {
      return Result.success(
        await _remote.updateDetails(
          id: id,
          categoryId: categoryId,
          priority: priority,
          teamId: teamId,
          assignedToId: assignedToId,
          internalNotes: internalNotes,
        ),
      );
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }
}
