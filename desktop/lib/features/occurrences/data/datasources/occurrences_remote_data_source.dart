import 'package:dio/dio.dart';
import '../../domain/entities/occurrence_filters.dart';
import '../models/staff_occurrence_model.dart';
import '../models/status_history_model.dart';

class OccurrencesRemoteDataSource {
  const OccurrencesRemoteDataSource(this._dio);
  final Dio _dio;

  Future<({List<StaffOccurrenceModel> items, int total})> list({
    required int page,
    required OccurrenceFilters filters,
  }) async {
    final response = await _dio.get(
      '/occurrences',
      queryParameters: {
        'page': page,
        'pageSize': 20,
        'sortBy': filters.sortBy,
        'sortOrder': filters.sortOrder,
        if (filters.status != null) 'status': filters.status,
        if (filters.priority != null) 'priority': filters.priority,
        if (filters.categoryId != null) 'categoryId': filters.categoryId,
        if (filters.search != null && filters.search!.isNotEmpty) 'search': filters.search,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((item) => StaffOccurrenceModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return (items: items, total: data['total'] as int);
  }

  Future<StaffOccurrenceModel> getById(String id) async {
    final response = await _dio.get('/occurrences/$id');
    return StaffOccurrenceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<OccurrenceStatusHistoryModel>> getHistory(String id) async {
    final response = await _dio.get('/occurrences/$id/history');
    return (response.data as List<dynamic>)
        .map((item) => OccurrenceStatusHistoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StaffOccurrenceModel> updateStatus({required String id, required String status, String? note}) async {
    final response = await _dio.patch(
      '/occurrences/$id/status',
      data: {'status': status, if (note != null && note.isNotEmpty) 'note': note},
    );
    return StaffOccurrenceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StaffOccurrenceModel> updateDetails({
    required String id,
    String? categoryId,
    String? priority,
    String? teamId,
    String? assignedToId,
    String? internalNotes,
  }) async {
    final response = await _dio.patch(
      '/occurrences/$id',
      data: {
        'categoryId': ?categoryId,
        'priority': ?priority,
        'teamId': ?teamId,
        'assignedToId': ?assignedToId,
        'internalNotes': ?internalNotes,
      },
    );
    return StaffOccurrenceModel.fromJson(response.data as Map<String, dynamic>);
  }
}
