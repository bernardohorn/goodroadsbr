import 'dart:io';
import '../../../../core/error/result.dart';
import '../../../../core/network/failure_mapper.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/occurrence.dart';
import '../../domain/entities/occurrence_status_history_entry.dart';
import '../../domain/entities/paginated_occurrences.dart';
import '../../domain/repositories/occurrences_repository.dart';
import '../datasources/occurrences_remote_data_source.dart';

class OccurrencesRepositoryImpl implements OccurrencesRepository {
  const OccurrencesRepositoryImpl(this._remote);
  final OccurrencesRemoteDataSource _remote;

  @override
  Future<Result<Occurrence>> create({
    required String description,
    required double latitude,
    required double longitude,
    String? address,
    String? categoryId,
    required List<File> photos,
  }) async {
    try {
      final occurrence = await _remote.create(
        description: description,
        latitude: latitude,
        longitude: longitude,
        address: address,
        categoryId: categoryId,
        photos: photos,
      );
      return Result.success(occurrence);
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<PaginatedOccurrences>> listMine({int page = 1, String? status}) async {
    try {
      final result = await _remote.listMine(page: page, status: status);
      return Result.success(
        PaginatedOccurrences(items: result.items, total: result.total, page: page, pageSize: 20),
      );
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<Occurrence>> getById(String id) async {
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
  Future<Result<List<Category>>> listCategories() async {
    try {
      return Result.success(await _remote.listCategories());
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }
}
