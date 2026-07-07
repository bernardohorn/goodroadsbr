import 'dart:io';
import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../entities/occurrence.dart';
import '../entities/occurrence_status_history_entry.dart';
import '../entities/paginated_occurrences.dart';

abstract class OccurrencesRepository {
  Future<Result<Occurrence>> create({
    required String description,
    required double latitude,
    required double longitude,
    String? address,
    String? categoryId,
    required List<File> photos,
  });

  Future<Result<PaginatedOccurrences>> listMine({int page = 1, String? status});

  Future<Result<Occurrence>> getById(String id);

  Future<Result<List<OccurrenceStatusHistoryEntry>>> getHistory(String id);

  Future<Result<List<Category>>> listCategories();
}
