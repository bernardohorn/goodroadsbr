import 'dart:io';
import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../models/occurrence_model.dart';
import '../models/occurrence_status_history_model.dart';

class OccurrencesRemoteDataSource {
  const OccurrencesRemoteDataSource(this._dio);
  final Dio _dio;

  Future<OccurrenceModel> create({
    required String description,
    required double latitude,
    required double longitude,
    String? address,
    String? categoryId,
    required List<File> photos,
  }) async {
    final formData = FormData.fromMap({
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': ?address,
      'categoryId': ?categoryId,
      'photos': [
        for (final photo in photos) await MultipartFile.fromFile(photo.path, filename: photo.uri.pathSegments.last),
      ],
    });

    final response = await _dio.post('/occurrences', data: formData);
    return OccurrenceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<({List<OccurrenceModel> items, int total})> listMine({required int page, String? status}) async {
    final response = await _dio.get(
      '/occurrences',
      queryParameters: {'page': page, 'pageSize': 20, 'status': ?status},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((item) => OccurrenceModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return (items: items, total: data['total'] as int);
  }

  Future<OccurrenceModel> getById(String id) async {
    final response = await _dio.get('/occurrences/$id');
    return OccurrenceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<OccurrenceStatusHistoryModel>> getHistory(String id) async {
    final response = await _dio.get('/occurrences/$id/history');
    return (response.data as List<dynamic>)
        .map((item) => OccurrenceStatusHistoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoryModel>> listCategories() async {
    final response = await _dio.get('/categories');
    return (response.data as List<dynamic>)
        .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
